import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../daos/sale_category_dao.dart';
import '../daos/sale_dao.dart';
import '../daos/sale_installment_dao.dart';
import '../daos/sale_payment_dao.dart';
import '../models/sale_category_model.dart';
import '../models/sale_installment_model.dart';
import '../models/sale_model.dart';
import '../models/sale_payment_model.dart';



/// All business logic for the `sale` module: sale, sale_category,
/// sale_installment and sale_payment. This is the only entry point the
/// UI/providers should use — never the DAOs directly.
class SaleRepository {
  SaleRepository(
    this._database,
    this._saleDao,
    this._saleCategoryDao,
    this._saleInstallmentDao,
    this._salePaymentDao,
  );

  final LocalDatabase _database;
  final SaleDao _saleDao;
  final SaleCategoryDao _saleCategoryDao;
  final SaleInstallmentDao _saleInstallmentDao;
  final SalePaymentDao _salePaymentDao;

  // ---------------------------------------------------------------------
  // sale_category
  // ---------------------------------------------------------------------

  Future<SaleCategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }
    final category = SaleCategoryModel(
      name: trimmedName,
      description: _cleanOrNull(description),
      createdAt: DateTime.now(),
    );
    final id = await _saleCategoryDao.insertCategory(category);
    return category.copyWith(idSaleCategory: id);
  }

  Future<SaleCategoryModel> updateCategory({
    required int idSaleCategory,
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }
    final current = await _saleCategoryDao.getCategoryById(idSaleCategory);
    if (current == null) {
      throw StateError('Sale category not found.');
    }
    final updated = current.copyWith(
      name: trimmedName,
      description: _cleanOrNull(description),
      updatedAt: DateTime.now(),
    );
    await _saleCategoryDao.updateCategory(updated);
    return updated;
  }

  Future<void> deleteCategory(int idSaleCategory) {
    return _saleCategoryDao.softDeleteCategory(idSaleCategory);
  }

  Future<List<SaleCategoryModel>> getAllCategories({
    bool includeDeleted = false,
  }) {
    return _saleCategoryDao.getAllCategories(includeDeleted: includeDeleted);
  }

  // ---------------------------------------------------------------------
  // sale
  // ---------------------------------------------------------------------

Future<SaleModel> createSale({
    required int saleCategoryId,
    required String description,
    required int totalAmountCents,
    String saleType = 'NORMAL',
    int? customerId,
    String? walkInCustomerName,
    DateTime? creditDueDate,
    String? notes,
    // Optional down payment for a CREDIT sale. If provided (> 0), it is
    // registered as the sale's first payment/installment right away; if
    // omitted, the whole total starts out as outstanding debt.
    int? initialPaymentCents,
    String initialPaymentMethod = 'CASH',
  }) async {
    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) {
      throw ArgumentError('Sale description cannot be empty.');
    }
    if (totalAmountCents <= 0) {
      throw ArgumentError('Sale total must be greater than zero.');
    }

    final isCredit = saleType == 'CREDIT';

    if (isCredit) {
      final hasCustomer = customerId != null;
      final hasWalkIn =
          walkInCustomerName != null && walkInCustomerName.trim().isNotEmpty;
      if (!hasCustomer && !hasWalkIn) {
        throw ArgumentError(
          'A CREDIT sale needs either a customer or a walk-in customer name.',
        );
      }
    }

    if (initialPaymentCents != null) {
      if (!isCredit) {
        throw ArgumentError('Only CREDIT sales accept an initial payment.');
      }
      if (initialPaymentCents <= 0) {
        throw ArgumentError('Initial payment must be greater than zero.');
      }
      if (initialPaymentCents > totalAmountCents) {
        throw ArgumentError('Initial payment cannot exceed the sale total.');
      }
    }

    return _database.runInTransaction((txn) async {
      final reference = await _generateSaleReference(txn);

      final sale = SaleModel(
        reference: reference,
        saleCategoryId: saleCategoryId,
        description: trimmedDescription,
        totalAmountCents: totalAmountCents,
        saleType: saleType,
        // Installments are no longer predefined by modality — they're
        // generated one at a time as payments come in (see _applyPayment).
        creditModality: null,
        saleStatus: isCredit ? 'OUTSTANDING' : 'COMPLETED',
        paymentStatus: isCredit ? 'PENDING' : 'PAID',
        paidAmountCents: isCredit ? 0 : totalAmountCents,
        customerId: customerId,
        walkInCustomerName: _cleanOrNull(walkInCustomerName),
        saleDate: DateTime.now(),
        creditDueDate: isCredit ? creditDueDate : null,
        completedAt: isCredit ? null : DateTime.now(),
        notes: _cleanOrNull(notes),
        createdAt: DateTime.now(),
      );

      final insertedId = await _saleDao.insertSale(sale, txn: txn);
      var savedSale = sale.copyWith(idSale: insertedId);

      if (isCredit && initialPaymentCents != null) {
        savedSale = await _applyPayment(
          txn: txn,
          sale: savedSale,
          paidAmountCents: initialPaymentCents,
          paymentMethod: initialPaymentMethod,
          notes: null,
        );
      }

      return savedSale;
    });
  }

  /// Cancels a sale: sets sale_status to CANCELLED and auto-cancels its
  /// unpaid installments. Existing sale_payment rows are left untouched —
  /// they remain as payment history. This does NOT touch the `deleted`
  /// column; that flag is reserved for a possible future "remove from
  /// records" action distinct from cancellation.
  Future<SaleModel> cancelSale({
    required int saleId,
    required String cancellationReason,
  }) async {
    final trimmedReason = cancellationReason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError('Cancellation reason cannot be empty.');
    }

    return _database.runInTransaction((txn) async {
      final sale = await _saleDao.getSaleById(saleId, txn: txn);
      if (sale == null) {
        throw StateError('Sale not found.');
      }
      if (sale.saleStatus == 'CANCELLED') {
        throw StateError('Sale is already cancelled.');
      }

      await _saleInstallmentDao.cancelUnpaidInstallments(saleId, txn: txn);

      final updatedSale = sale.copyWith(
        saleStatus: 'CANCELLED',
        cancellationReason: trimmedReason,
      );
      await _saleDao.updateSale(updatedSale, txn: txn);
      return updatedSale;
    });
  }

/// Registers a payment against a CREDIT sale. This is what the credit
  /// sale detail screen calls every time the customer pays something —
  /// each call is itself the "automatic installment generation": it
  /// creates one new, already-PAID sale_installment row representing
  /// this exact tranche, in the order payments are received.
  Future<SaleModel> registerPayment({
    required int saleId,
    required int paidAmountCents,
    String paymentMethod = 'CASH',
    String? notes,
  }) async {
    if (paidAmountCents <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    return _database.runInTransaction((txn) async {
      final sale = await _saleDao.getSaleById(saleId, txn: txn);
      if (sale == null) {
        throw StateError('Sale not found.');
      }
      if (!sale.isCredit) {
        throw StateError('Only CREDIT sales accept payments.');
      }
      if (sale.saleStatus == 'CANCELLED') {
        throw StateError('Cannot register a payment on a cancelled sale.');
      }

      return _applyPayment(
        txn: txn,
        sale: sale,
        paidAmountCents: paidAmountCents,
        paymentMethod: paymentMethod,
        notes: notes,
      );
    });
  }

  /// Shared by [createSale] (initial payment) and [registerPayment]
  /// (every later payment). Must always run inside the caller's
  /// transaction, so a failure never leaves paid_amount_cents out of
  /// sync with the sum of sale_payment rows.
  Future<SaleModel> _applyPayment({
    required Transaction txn,
    required SaleModel sale,
    required int paidAmountCents,
    required String paymentMethod,
    String? notes,
  }) async {
    final due = sale.totalAmountCents - sale.paidAmountCents;
    if (paidAmountCents > due) {
      throw ArgumentError(
        'Payment exceeds the total amount still owed on this sale.',
      );
    }

    final nextInstallmentNumber = await _saleInstallmentDao
            .countInstallmentsBySale(sale.idSale!, txn: txn) +
        1;

    final installmentId = await _saleInstallmentDao.insertInstallment(
      SaleInstallmentModel(
        saleId: sale.idSale!,
        installmentNumber: nextInstallmentNumber,
        installmentAmountCents: paidAmountCents,
        paidAmountCents: paidAmountCents,
        dueDate: DateTime.now(),
        paidAt: DateTime.now(),
        installmentStatus: 'PAID',
      ),
      txn: txn,
    );

    final reference = await _generatePaymentReference(txn);
    await _salePaymentDao.insertPayment(
      SalePaymentModel(
        reference: reference,
        saleId: sale.idSale!,
        installmentId: installmentId,
        paidAmountCents: paidAmountCents,
        paymentMethod: paymentMethod,
        paidAt: DateTime.now(),
        notes: notes,
      ),
      txn: txn,
    );

    final newPaidAmount = sale.paidAmountCents + paidAmountCents;
    final isFullyPaid = newPaidAmount >= sale.totalAmountCents;
    final paymentStatus = newPaidAmount <= 0
        ? 'PENDING'
        : (isFullyPaid ? 'PAID' : 'PARTIAL');

    final updatedSale = sale.copyWith(
      paidAmountCents: newPaidAmount,
      paymentStatus: paymentStatus,
      saleStatus: isFullyPaid ? 'COMPLETED' : sale.saleStatus,
      completedAt: isFullyPaid ? DateTime.now() : sale.completedAt,
    );
    await _saleDao.updateSale(updatedSale, txn: txn);
    return updatedSale;
  }

  Future<SaleModel?> getSaleById(int idSale) {
    return _saleDao.getSaleById(idSale);
  }

Future<List<SaleModel>> getAllSales({
    int? saleCategoryId,
    int? customerId,
    String? saleType,
    String? saleStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _saleDao.getAllSales(
      saleCategoryId: saleCategoryId,
      customerId: customerId,
      saleType: saleType,
      saleStatus: saleStatus,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Backs the main sales list screen: NORMAL sales always, CREDIT sales
  /// only once finalized (COMPLETED/CANCELLED).
  Future<List<SaleModel>> getSalesForSalesList({
    int? saleCategoryId,
    int? customerId,
    String? saleType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _saleDao.getSalesForSalesList(
      saleCategoryId: saleCategoryId,
      customerId: customerId,
      saleType: saleType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Backs the credit sales list screen: only active (unpaid) credit sales.
  Future<List<SaleModel>> getOutstandingCreditSales({
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _saleDao.getOutstandingCreditSales(
      customerId: customerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<SaleInstallmentModel>> getInstallmentsBySale(int saleId) {
    return _saleInstallmentDao.getInstallmentsBySale(saleId);
  }

Future<List<SalePaymentModel>> getPaymentsBySale(int saleId) {
    return _salePaymentDao.getPaymentsBySale(saleId);
  }

  // ---------------------------------------------------------------------
  // dashboard / badge stats
  // ---------------------------------------------------------------------

  /// Number of credit sales still not finalized — backs the sidebar badge.
  Future<int> countOutstandingCreditSales() {
    return _saleDao.countOutstandingCreditSales();
  }

  /// Aggregates finalized-sale numbers for the dashboard, for the given
  /// date range. Pass null/null for an all-time snapshot.
  Future<DashboardStats> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final finalizedCount = await _saleDao.countFinalizedSales(
      startDate: startDate,
      endDate: endDate,
    );
    final totalAllCents = await _saleDao.sumFinalizedSalesCents(
      startDate: startDate,
      endDate: endDate,
    );
    final totalCreditCents = await _saleDao.sumFinalizedSalesCents(
      saleType: 'CREDIT',
      startDate: startDate,
      endDate: endDate,
    );
    final categoryRows = await _saleDao.sumFinalizedSalesByCategory(
      startDate: startDate,
      endDate: endDate,
    );

    return DashboardStats(
      finalizedSalesCount: finalizedCount,
      totalAllSalesCents: totalAllCents,
      totalCreditSalesCents: totalCreditCents,
      categorySummaries: categoryRows
          .map((row) => CategorySalesSummary(
                idSaleCategory: row['id_sale_category'] as int,
                name: row['name'] as String,
                totalCents: row['total_cents'] as int,
                saleCount: row['sale_count'] as int,
              ))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------

  Future<String> _generateSaleReference(Transaction txn) async {
    final count = await _saleDao.countAll(txn: txn);
    return 'V-${(count + 1).toString().padLeft(5, '0')}';
  }

  Future<String> _generatePaymentReference(Transaction txn) async {
    final count = await _salePaymentDao.countAll(txn: txn);
    return 'V-${(count + 1).toString().padLeft(5, '0')}';
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}


