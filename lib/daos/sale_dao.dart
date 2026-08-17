// sale_dao.dart
import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/sale_model.dart';
import 'package:flutter/foundation.dart';

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



/// Count of active (unfinalized) credit sales — powers the sidebar
  /// badge. A sale counts here from creation until it's COMPLETED or
  /// CANCELLED, exactly mirroring [getOutstandingCreditSales]'s filter.
  Future<int> countOutstandingCreditSales({Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final result = await executor.rawQuery(
      "SELECT COUNT(*) AS total FROM sale "
      "WHERE deleted = 0 AND sale_type = 'CREDIT' "
      "AND sale_status IN ('OPEN','OUTSTANDING')",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countFinalizedSales({
    DateTime? startDate,
    DateTime? endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final conditions = <String>["deleted = 0", "sale_status = 'COMPLETED'"];
    final args = <Object?>[];
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
  Future<int> sumFinalizedSalesCents({
    String? saleType,
    DateTime? startDate,
    DateTime? endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final conditions = <String>["deleted = 0", "sale_status = 'COMPLETED'"];
    final args = <Object?>[];
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

  /// One row per non-deleted sale_category, with the sum/count of its
  /// finalized sales in the period. LEFT JOIN keeps categories with zero
  /// sales in the result (as 0), instead of dropping them.
  Future<List<Map<String, Object?>>> sumFinalizedSalesByCategory({
    DateTime? startDate,
    DateTime? endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final joinConditions = <String>[
      's.sale_category_id = c.id_business_category',
      's.deleted = 0',
      "s.sale_status = 'COMPLETED'",
    ];
    final args = <Object?>[];
    if (startDate != null) {
      joinConditions.add('s.sale_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      joinConditions.add('s.sale_date <= ?');
      args.add(endDate.toIso8601String());
    }
final rows = await executor.rawQuery(
      'SELECT c.id_business_category AS id_business_category, c.name AS name, '
      'COALESCE(SUM(s.total_amount_cents), 0) AS total_cents, '
      'COUNT(s.id_sale) AS sale_count '
      'FROM business_category c '
      'LEFT JOIN sale s ON ${joinConditions.join(' AND ')} '
      'WHERE c.deleted = 0 '
      'GROUP BY c.id_business_category, c.name '
      'ORDER BY total_cents DESC',
      args,
    );
    debugPrint('CATEGORY BREAKDOWN: $rows');

    final debugRows = await executor.rawQuery(
      'SELECT id_sale, reference, description, total_amount_cents, '
      'sale_status, deleted, sale_category_id '
      'FROM sale WHERE sale_category_id = 1',
    );
    debugPrint('DESENVOLVIMENTO RAW SALES: $debugRows');

    return rows;
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