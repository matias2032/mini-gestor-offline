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

/// Plain input used to describe one installment when creating an
/// INSTALLMENTS credit sale. Not a persisted model — SaleRepository turns
/// each of these into a SaleInstallmentModel row.
class InstallmentInput {
  const InstallmentInput({
    required this.installmentNumber,
    required this.installmentAmountCents,
    required this.dueDate,
  });

  final int installmentNumber;
  final int installmentAmountCents;
  final DateTime dueDate;
}

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
    String? creditModality,
    int? customerId,
    String? walkInCustomerName,
    DateTime? creditDueDate,
    String? notes,
    List<InstallmentInput> installments = const [],
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
      if (creditModality != 'SINGLE_PAYMENT' &&
          creditModality != 'INSTALLMENTS') {
        throw ArgumentError('A CREDIT sale needs a valid credit modality.');
      }
      if (creditModality == 'INSTALLMENTS') {
        if (installments.isEmpty) {
          throw ArgumentError(
            'An INSTALLMENTS sale needs at least one installment.',
          );
        }
        final sum = installments.fold<int>(
          0,
          (total, installment) => total + installment.installmentAmountCents,
        );
        if (sum != totalAmountCents) {
          throw ArgumentError(
            'The sum of installment amounts must equal the sale total.',
          );
        }
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
        creditModality: isCredit ? creditModality : null,
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
      final savedSale = sale.copyWith(idSale: insertedId);

      if (isCredit && creditModality == 'INSTALLMENTS') {
        for (final input in installments) {
          await _saleInstallmentDao.insertInstallment(
            SaleInstallmentModel(
              saleId: insertedId,
              installmentNumber: input.installmentNumber,
              installmentAmountCents: input.installmentAmountCents,
              dueDate: input.dueDate,
            ),
            txn: txn,
          );
        }
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

  /// Registers a payment against a CREDIT sale.
  ///
  /// - INSTALLMENTS: distributes [paidAmountCents] sequentially into the
  ///   oldest PENDING/PARTIAL installment first, overflowing into the
  ///   next one, creating one sale_payment row per installment touched.
  /// - SINGLE_PAYMENT: creates a single sale_payment row with no
  ///   installment_id.
  ///
  /// Marks the sale COMPLETED (with completed_at) once fully paid, all
  /// inside one transaction.
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

      var remaining = paidAmountCents;
      var newPaidAmount = sale.paidAmountCents;

      if (sale.creditModality == 'INSTALLMENTS') {
        final installments =
            await _saleInstallmentDao.getInstallmentsBySale(saleId, txn: txn);
        final payable = installments
            .where((installment) =>
                installment.installmentStatus == 'PENDING' ||
                installment.installmentStatus == 'PARTIAL')
            .toList()
          ..sort(
            (a, b) => a.installmentNumber.compareTo(b.installmentNumber),
          );

        for (final installment in payable) {
          if (remaining <= 0) break;

          final due = installment.remainingCents;
          final applied = remaining < due ? remaining : due;

          final reference = await _generatePaymentReference(txn);
          await _salePaymentDao.insertPayment(
            SalePaymentModel(
              reference: reference,
              saleId: saleId,
              installmentId: installment.idSaleInstallment,
              paidAmountCents: applied,
              paymentMethod: paymentMethod,
              paidAt: DateTime.now(),
              notes: notes,
            ),
            txn: txn,
          );

          final updatedInstallmentPaid = installment.paidAmountCents + applied;
          final isInstallmentPaid =
              updatedInstallmentPaid >= installment.installmentAmountCents;
          await _saleInstallmentDao.updateInstallment(
            installment.copyWith(
              paidAmountCents: updatedInstallmentPaid,
              installmentStatus: isInstallmentPaid ? 'PAID' : 'PARTIAL',
              paidAt: isInstallmentPaid ? DateTime.now() : null,
            ),
            txn: txn,
          );

          remaining -= applied;
          newPaidAmount += applied;
        }

        if (remaining > 0) {
          throw ArgumentError(
            'Payment exceeds the total amount still owed on this sale.',
          );
        }
      } else {
        final due = sale.totalAmountCents - sale.paidAmountCents;
        if (paidAmountCents > due) {
          throw ArgumentError(
            'Payment exceeds the total amount still owed on this sale.',
          );
        }
        final reference = await _generatePaymentReference(txn);
        await _salePaymentDao.insertPayment(
          SalePaymentModel(
            reference: reference,
            saleId: saleId,
            paidAmountCents: paidAmountCents,
            paymentMethod: paymentMethod,
            paidAt: DateTime.now(),
            notes: notes,
          ),
          txn: txn,
        );
        newPaidAmount += paidAmountCents;
      }

      final isFullyPaid = newPaidAmount >= sale.totalAmountCents;
      final String paymentStatus;
      if (newPaidAmount <= 0) {
        paymentStatus = 'PENDING';
      } else if (isFullyPaid) {
        paymentStatus = 'PAID';
      } else {
        paymentStatus = 'PARTIAL';
      }

      final updatedSale = sale.copyWith(
        paidAmountCents: newPaidAmount,
        paymentStatus: paymentStatus,
        saleStatus: isFullyPaid ? 'COMPLETED' : sale.saleStatus,
        completedAt: isFullyPaid ? DateTime.now() : sale.completedAt,
      );
      await _saleDao.updateSale(updatedSale, txn: txn);
      return updatedSale;
    });
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

  Future<List<SaleInstallmentModel>> getInstallmentsBySale(int saleId) {
    return _saleInstallmentDao.getInstallmentsBySale(saleId);
  }

  Future<List<SalePaymentModel>> getPaymentsBySale(int saleId) {
    return _salePaymentDao.getPaymentsBySale(saleId);
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