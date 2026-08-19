import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/sale_model.dart';

/// Pure data access for the `sale` aggregate: sale, sale_installment and
/// sale_payment. Unified into one DAO because these three tables are
/// never meaningfully touched in isolation — an installment/payment has
/// no independent lifecycle from the sale it belongs to (mirrors the
/// grouping already used in FinancialStatementDao).
class SaleDao {
  SaleDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  // ---------------------------------------------------------------------
  // sale
  // ---------------------------------------------------------------------

  Future<int> insertSale(SaleModel sale, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('sale', sale.toMap());
  }

  Future<int> updateSale(SaleModel sale, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale',
      sale.toMap(),
      where: 'id_sale = ?',
      whereArgs: [sale.idSale],
    );
  }

  Future<int> softDeleteSale(
    int idSale,
    String cancellationReason, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale',
      {'deleted': 1, 'cancellation_reason': cancellationReason},
      where: 'id_sale = ?',
      whereArgs: [idSale],
    );
  }

  Future<SaleModel?> getSaleById(int idSale, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale',
      where: 'id_sale = ?',
      whereArgs: [idSale],
    );
    if (rows.isEmpty) return null;
    return SaleModel.fromMap(rows.first);
  }

  Future<bool> referenceExists(String reference, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale',
      where: 'reference = ?',
      whereArgs: [reference],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Returns sales ordered by most recent first, with optional filters.
  /// All filters are combined with AND. `businessUnitId` is strict scope
  /// (mandatory) — see FASE 3 handoff.
  Future<List<SaleModel>> getAllSales({
    required int businessUnitId,
    int? customerId,
    String? saleType,
    String? saleStatus,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;

    final conditions = <String>['business_unit_id = ?'];
    final args = <Object?>[businessUnitId];

    if (!includeDeleted) {
      conditions.add('deleted = 0');
    }
    if (customerId != null) {
      conditions.add('customer_id = ?');
      args.add(customerId);
    }
    if (saleType != null) {
      conditions.add('sale_type = ?');
      args.add(saleType);
    }
    if (saleStatus != null) {
      conditions.add('sale_status = ?');
      args.add(saleStatus);
    }
    if (startDate != null) {
      conditions.add('sale_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('sale_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final rows = await executor.query(
      'sale',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'sale_date DESC',
    );
    return rows.map(SaleModel.fromMap).toList();
  }

  Future<int> countAll({bool includeDeleted = true, Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final result = await executor.rawQuery(
      includeDeleted
          ? 'SELECT COUNT(*) AS total FROM sale'
          : 'SELECT COUNT(*) AS total FROM sale WHERE deleted = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Sales for the main sales list: every NORMAL sale, plus CREDIT sales
  /// only once they're finalized (COMPLETED or CANCELLED). Active credit
  /// sales stay out of this list — they live in [getOutstandingCreditSales]
  /// until they're settled. `businessUnitId` is strict scope (mandatory).
  Future<List<SaleModel>> getSalesForSalesList({
    required int businessUnitId,
    int? customerId,
    String? saleType,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;

    final conditions = <String>[
      "(sale_type = 'NORMAL' OR sale_status IN ('COMPLETED','CANCELLED'))",
      'business_unit_id = ?',
    ];
    final args = <Object?>[businessUnitId];

    if (!includeDeleted) conditions.add('deleted = 0');
    if (customerId != null) {
      conditions.add('customer_id = ?');
      args.add(customerId);
    }
    if (saleType != null) {
      conditions.add('sale_type = ?');
      args.add(saleType);
    }
    if (startDate != null) {
      conditions.add('sale_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('sale_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final rows = await executor.query(
      'sale',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'sale_date DESC',
    );
    return rows.map(SaleModel.fromMap).toList();
  }

  /// Count of active (unfinalized) credit sales — powers the sidebar
  /// badge. A sale counts here from creation until it's COMPLETED or
  /// CANCELLED, exactly mirroring [getOutstandingCreditSales]'s filter.
  /// Scoped to the active business unit.
  Future<int> countOutstandingCreditSales({
    required int businessUnitId,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final result = await executor.rawQuery(
      "SELECT COUNT(*) AS total FROM sale "
      "WHERE deleted = 0 AND sale_type = 'CREDIT' "
      "AND sale_status IN ('OPEN','OUTSTANDING') "
      "AND business_unit_id = ?",
      [businessUnitId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }


  /// Count of finalized (COMPLETED) sales. Pass [saleType] to restrict to
  /// 'CREDIT' or 'NORMAL'; omit it to count both. Scoped to the active
  /// business unit.
  Future<int> countFinalizedSales({
    required int businessUnitId,
    String? saleType,
    DateTime? startDate,
    DateTime? endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final conditions = <String>[
      "deleted = 0",
      "sale_status = 'COMPLETED'",
      "business_unit_id = ?",
    ];
    final args = <Object?>[businessUnitId];
    if (saleType != null) {
      conditions.add('sale_type = ?');
      args.add(saleType);
    }
    if (startDate != null) {
      conditions.add('sale_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('sale_date <= ?');
      args.add(endDate.toIso8601String());
    }
    final result = await executor.rawQuery(
      'SELECT COUNT(*) AS total FROM sale WHERE ${conditions.join(' AND ')}',
      args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Sum of total_amount_cents for finalized sales. Pass [saleType] to
  /// restrict to 'CREDIT' or 'NORMAL'; omit it for the grand total.
  /// Scoped to the active business unit.
  Future<int> sumFinalizedSalesCents({
    required int businessUnitId,
    String? saleType,
    DateTime? startDate,
    DateTime? endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final conditions = <String>[
      "deleted = 0",
      "sale_status = 'COMPLETED'",
      "business_unit_id = ?",
    ];
    final args = <Object?>[businessUnitId];
    if (saleType != null) {
      conditions.add('sale_type = ?');
      args.add(saleType);
    }
    if (startDate != null) {
      conditions.add('sale_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('sale_date <= ?');
      args.add(endDate.toIso8601String());
    }
    final result = await executor.rawQuery(
      'SELECT COALESCE(SUM(total_amount_cents), 0) AS total '
      'FROM sale WHERE ${conditions.join(' AND ')}',
      args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }


  /// Credit sales still awaiting payment — exactly the ones excluded from
  /// [getSalesForSalesList]. Backs the (upcoming) credit sales list
  /// screen. Scoped to the active business unit.
  Future<List<SaleModel>> getOutstandingCreditSales({
    required int businessUnitId,
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;

    final conditions = <String>[
      "sale_type = 'CREDIT'",
      "sale_status IN ('OPEN','OUTSTANDING')",
      'business_unit_id = ?',
    ];
    final args = <Object?>[businessUnitId];

    if (!includeDeleted) conditions.add('deleted = 0');
    if (customerId != null) {
      conditions.add('customer_id = ?');
      args.add(customerId);
    }
    if (startDate != null) {
      conditions.add('sale_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('sale_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final rows = await executor.query(
      'sale',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'sale_date DESC',
    );
    return rows.map(SaleModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // sale_installment
  // ---------------------------------------------------------------------

  Future<int> insertInstallment(
    SaleInstallmentModel installment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('sale_installment', installment.toMap());
  }

  Future<int> updateInstallment(
    SaleInstallmentModel installment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale_installment',
      installment.toMap(),
      where: 'id_sale_installment = ?',
      whereArgs: [installment.idSaleInstallment],
    );
  }

  Future<List<SaleInstallmentModel>> getInstallmentsBySale(
    int saleId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_installment',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'installment_number ASC',
    );
    return rows.map(SaleInstallmentModel.fromMap).toList();
  }

  Future<SaleInstallmentModel?> getInstallmentById(
    int idSaleInstallment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_installment',
      where: 'id_sale_installment = ?',
      whereArgs: [idSaleInstallment],
    );
    if (rows.isEmpty) return null;
    return SaleInstallmentModel.fromMap(rows.first);
  }

  Future<int> cancelUnpaidInstallments(int saleId, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale_installment',
      {
        'installment_status': 'CANCELLED',
        'cancelled_by_sale_cancellation': 1,
      },
      where: 'sale_id = ? AND installment_status IN (?, ?)',
      whereArgs: [saleId, 'PENDING', 'PARTIAL'],
    );
  }

  /// Number of installments already generated for [saleId]. Since
  /// installments are no longer predefined — each payment automatically
  /// creates the "next" one — this is how SaleRepository knows the next
  /// installment_number to use.
  Future<int> countInstallmentsBySale(int saleId, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final result = await executor.rawQuery(
      'SELECT COUNT(*) AS total FROM sale_installment WHERE sale_id = ?',
      [saleId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------
  // sale_payment
  // ---------------------------------------------------------------------

  Future<int> insertPayment(
    SalePaymentModel payment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('sale_payment', payment.toMap());
  }

  Future<List<SalePaymentModel>> getPaymentsBySale(
    int saleId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_payment',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'paid_at DESC',
    );
    return rows.map(SalePaymentModel.fromMap).toList();
  }

  Future<bool> paymentReferenceExists(String reference, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_payment',
      where: 'reference = ?',
      whereArgs: [reference],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> countAllPayments({Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final result =
        await executor.rawQuery('SELECT COUNT(*) AS total FROM sale_payment');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}