import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/sale_model.dart';

class SaleDao {
  SaleDao(this._localDatabase);

  final LocalDatabase _localDatabase;

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
  /// All filters are combined with AND.
  Future<List<SaleModel>> getAllSales({
    int? saleCategoryId,
    int? customerId,
    String? saleType,
    String? saleStatus,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (!includeDeleted) {
      conditions.add('deleted = 0');
    }
    if (saleCategoryId != null) {
      conditions.add('sale_category_id = ?');
      args.add(saleCategoryId);
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
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
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
  /// until they're settled.
  Future<List<SaleModel>> getSalesForSalesList({
    int? saleCategoryId,
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
    ];
    final args = <Object?>[];

    if (!includeDeleted) conditions.add('deleted = 0');
    if (saleCategoryId != null) {
      conditions.add('sale_category_id = ?');
      args.add(saleCategoryId);
    }
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

  /// Credit sales still awaiting payment — exactly the ones excluded from
  /// [getSalesForSalesList]. Backs the (upcoming) credit sales list screen.
  Future<List<SaleModel>> getOutstandingCreditSales({
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
    ];
    final args = <Object?>[];

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
}