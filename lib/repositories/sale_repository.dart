import '../core/database/local_database.dart';
import '../daos/business_unit_dao.dart';
import '../daos/sale_dao.dart';
import '../models/sale_model.dart';
import 'package:sqflite/sqflite.dart';
/// All business logic for the `sale` module: sale, sale_installment and
/// sale_payment. This is the only entry point the UI/providers should
/// use — never SaleDao directly.
class SaleRepository {
  SaleRepository(this._database, this._saleDao, this._businessUnitDao);

  final LocalDatabase _database;
  final SaleDao _saleDao;
  final BusinessUnitDao _businessUnitDao;

  // ---------------------------------------------------------------------
  // sale
  // ---------------------------------------------------------------------

  Future<SaleModel> createSale({
    required int businessUnitId,
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
        businessUnitId: businessUnitId,
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

      await _saleDao.cancelUnpaidInstallments(saleId, txn: txn);

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

    final nextInstallmentNumber = await _saleDao
            .countInstallmentsBySale(sale.idSale!, txn: txn) +
        1;

    final installmentId = await _saleDao.insertInstallment(
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
    await _saleDao.insertPayment(
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
    required int businessUnitId,
    int? customerId,
    String? saleType,
    String? saleStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _saleDao.getAllSales(
      businessUnitId: businessUnitId,
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
    required int businessUnitId,
    int? customerId,
    String? saleType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _saleDao.getSalesForSalesList(
      businessUnitId: businessUnitId,
      customerId: customerId,
      saleType: saleType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Backs the credit sales list screen: only active (unpaid) credit sales.
  Future<List<SaleModel>> getOutstandingCreditSales({
    required int businessUnitId,
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _saleDao.getOutstandingCreditSales(
      businessUnitId: businessUnitId,
      customerId: customerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<SaleInstallmentModel>> getInstallmentsBySale(int saleId) {
    return _saleDao.getInstallmentsBySale(saleId);
  }

  Future<List<SalePaymentModel>> getPaymentsBySale(int saleId) {
    return _saleDao.getPaymentsBySale(saleId);
  }

  // ---------------------------------------------------------------------
  // badge stats
  // ---------------------------------------------------------------------

  /// Number of credit sales still not finalized — backs the sidebar badge.
  Future<int> countOutstandingCreditSales({required int businessUnitId}) {
    return _saleDao.countOutstandingCreditSales(businessUnitId: businessUnitId);
  }


  /// Aggregate dashboard stats for one store, over [period]. Backs the
  /// Dashboard Individual (FASE 5). businessUnitId is strict scope —
  /// callers use this for a single store; the Super Dashboard (also
  /// FASE 5) iterates this per business_unit instead of calling it once
  /// with a null id, since it stays consistent with
  /// FinancialStatementRepository.generateStatement's own pattern.
  Future<DashboardStats> getDashboardStats({
    required int businessUnitId,
    required DashboardPeriod period,
  }) async {
    final now = DateTime.now();
    final startDate = period.startDateFrom(now);

    final finalizedSalesCount = await _saleDao.countFinalizedSales(
      businessUnitId: businessUnitId,
      startDate: startDate,
      endDate: now,
    );
    final totalRevenueCents = await _saleDao.sumFinalizedSalesCents(
      businessUnitId: businessUnitId,
      startDate: startDate,
      endDate: now,
    );
    final settledCreditSalesCount = await _saleDao.countFinalizedSales(
      businessUnitId: businessUnitId,
      saleType: 'CREDIT',
      startDate: startDate,
      endDate: now,
    );
    final settledCreditRevenueCents = await _saleDao.sumFinalizedSalesCents(
      businessUnitId: businessUnitId,
      saleType: 'CREDIT',
      startDate: startDate,
      endDate: now,
    );

    return DashboardStats(
      businessUnitId: businessUnitId,
      period: period,
      startDate: startDate,
      endDate: now,
      finalizedSalesCount: finalizedSalesCount,
      totalRevenueCents: totalRevenueCents,
      settledCreditSalesCount: settledCreditSalesCount,
      settledCreditRevenueCents: settledCreditRevenueCents,
    );
  }

  /// Consolidated dashboard stats across every business unit (the "Super
  /// Dashboard"). Loops every business_unit — same pattern
  /// FinancialStatementRepository.generateStatement uses for
  /// businessUnitId == null — and sums each store's [DashboardStats]
  /// fields, keeping a per-store breakdown for the UI.
  Future<ConsolidatedDashboardStats> getConsolidatedDashboardStats({
    required DashboardPeriod period,
  }) async {
    final now = DateTime.now();
    final startDate = period.startDateFrom(now);

    final units = await _businessUnitDao.findAll();

    var finalizedSalesCount = 0;
    var totalRevenueCents = 0;
    var settledCreditSalesCount = 0;
    var settledCreditRevenueCents = 0;
    final perStore = <DashboardStoreBreakdown>[];

    for (final unit in units) {
      final unitId = unit.idBusinessUnit!;

      final unitSalesCount = await _saleDao.countFinalizedSales(
        businessUnitId: unitId,
        startDate: startDate,
        endDate: now,
      );
      final unitRevenueCents = await _saleDao.sumFinalizedSalesCents(
        businessUnitId: unitId,
        startDate: startDate,
        endDate: now,
      );
      final unitCreditCount = await _saleDao.countFinalizedSales(
        businessUnitId: unitId,
        saleType: 'CREDIT',
        startDate: startDate,
        endDate: now,
      );
      final unitCreditRevenueCents = await _saleDao.sumFinalizedSalesCents(
        businessUnitId: unitId,
        saleType: 'CREDIT',
        startDate: startDate,
        endDate: now,
      );

      finalizedSalesCount += unitSalesCount;
      totalRevenueCents += unitRevenueCents;
      settledCreditSalesCount += unitCreditCount;
      settledCreditRevenueCents += unitCreditRevenueCents;

      perStore.add(DashboardStoreBreakdown(
        businessUnitId: unitId,
        businessUnitName: unit.name,
        finalizedSalesCount: unitSalesCount,
        totalRevenueCents: unitRevenueCents,
      ));
    }

    perStore.sort((a, b) => b.totalRevenueCents.compareTo(a.totalRevenueCents));

    return ConsolidatedDashboardStats(
      period: period,
      startDate: startDate,
      endDate: now,
      finalizedSalesCount: finalizedSalesCount,
      totalRevenueCents: totalRevenueCents,
      settledCreditSalesCount: settledCreditSalesCount,
      settledCreditRevenueCents: settledCreditRevenueCents,
      perStore: perStore,
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
    final count = await _saleDao.countAllPayments(txn: txn);
    return 'V-${(count + 1).toString().padLeft(5, '0')}';
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}