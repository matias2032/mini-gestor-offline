import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../models/financial_statement_model.dart';

/// Pure data access for the financial_statement module. No business
/// rules here (e.g. no knowledge of what counts as a "finalized" sale) —
/// that belongs in FinancialStatementRepository.
class FinancialStatementDao {
  FinancialStatementDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  // ---------------------------------------------------------------------
  // financial_statement
  // ---------------------------------------------------------------------

  Future<int> insertStatement(
    FinancialStatementModel statement, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('financial_statement', statement.toMap());
  }

  Future<int> softDeleteStatement(
    int idFinancialStatement, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'financial_statement',
      {'deleted': 1},
      where: 'id_financial_statement = ?',
      whereArgs: [idFinancialStatement],
    );
  }

  Future<FinancialStatementModel?> getStatementById(
    int idFinancialStatement, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'financial_statement',
      where: 'id_financial_statement = ?',
      whereArgs: [idFinancialStatement],
    );
    if (rows.isEmpty) return null;
    return FinancialStatementModel.fromMap(rows.first);
  }

  /// Returns statements ordered by most recently generated first, with
  /// optional filters. All filters are combined with AND.
  /// Returns statements ordered by most recently generated first, with
  /// optional filters. `activeUnitId` applies the hybrid filter — null
  /// returns only consolidated (matriz) statements; an id returns
  /// consolidated + that unit's statements.
  Future<List<FinancialStatementModel>> getAllStatements({
    int? activeUnitId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;

    final conditions = <String>[
      '(business_unit_id IS NULL OR business_unit_id = ?)',
    ];
    final args = <Object?>[activeUnitId];

    if (!includeDeleted) {
      conditions.add('deleted = 0');
    }
    if (startDate != null) {
      conditions.add('generated_at >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('generated_at <= ?');
      args.add(endDate.toIso8601String());
    }

    final rows = await executor.query(
      'financial_statement',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'generated_at DESC',
    );
    return rows.map(FinancialStatementModel.fromMap).toList();
  }

  Future<int> countAll({bool includeDeleted = true, Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final result = await executor.rawQuery(
      includeDeleted
          ? 'SELECT COUNT(*) AS total FROM financial_statement'
          : 'SELECT COUNT(*) AS total FROM financial_statement WHERE deleted = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------
  // financial_statement_sale_item
  // ---------------------------------------------------------------------

  Future<void> insertSaleItems(
    List<FinancialStatementSaleItemModel> items, {
    required Transaction txn,
  }) async {
    final batch = txn.batch();
    for (final item in items) {
      batch.insert('financial_statement_sale_item', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<FinancialStatementSaleItemModel>> getSaleItemsByStatement(
    int financialStatementId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'financial_statement_sale_item',
      where: 'financial_statement_id = ?',
      whereArgs: [financialStatementId],
      orderBy: 'sale_date ASC',
    );
    return rows.map(FinancialStatementSaleItemModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // financial_statement_expense_item
  // ---------------------------------------------------------------------

  Future<void> insertExpenseItems(
    List<FinancialStatementExpenseItemModel> items, {
    required Transaction txn,
  }) async {
    final batch = txn.batch();
    for (final item in items) {
      batch.insert('financial_statement_expense_item', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<FinancialStatementExpenseItemModel>> getExpenseItemsByStatement(
    int financialStatementId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'financial_statement_expense_item',
      where: 'financial_statement_id = ?',
      whereArgs: [financialStatementId],
      orderBy: 'expense_date ASC',
    );
    return rows.map(FinancialStatementExpenseItemModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Source queries — read directly from `sale`/`expense` at generation
  // time. Kept here (not in SaleDao/ExpenseDao) because they're specific
  // to statement generation and return raw rows, not domain models.
  // ---------------------------------------------------------------------

  /// Finalized sales (sale_status = COMPLETED, not deleted) whose
  /// sale_date falls within [startDate, endDate] inclusive.
  /// Finalized sales (sale_status = COMPLETED, not deleted) whose
  /// sale_date falls within [startDate, endDate] inclusive. No category
  /// columns — dropped in Schema v4.
  Future<List<Map<String, Object?>>> getFinalizedSalesInPeriod({
    required int businessUnitId,
    required DateTime startDate,
    required DateTime endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.rawQuery(
      '''
      SELECT s.id_sale, s.reference, s.description, s.sale_date,
             s.total_amount_cents
      FROM sale s
      WHERE s.deleted = 0 AND s.sale_status = 'COMPLETED'
        AND s.business_unit_id = ?
        AND s.sale_date >= ? AND s.sale_date <= ?
      ORDER BY s.sale_date ASC
      ''',
      [businessUnitId, startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  /// Expenses within [startDate, endDate] inclusive. `expense_category_split`
  /// no longer exists (Schema v4) — amount_cents is read straight off
  /// `expense`, which is a flat row again.
  Future<List<Map<String, Object?>>> getExpensesInPeriod({
    required int businessUnitId,
    required DateTime startDate,
    required DateTime endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.rawQuery(
      '''
      SELECT e.id_expense, e.description, e.expense_date,
             e.amount_cents
      FROM expense e
      WHERE e.deleted = 0
        AND e.business_unit_id = ?
        AND e.expense_date >= ? AND e.expense_date <= ?
      ORDER BY e.expense_date ASC
      ''',
      [businessUnitId, startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

    Future<List<Map<String, Object?>>> getSalesBreakdownByUnit(
    int financialStatementId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.rawQuery(
      '''
      SELECT s.business_unit_id AS business_unit_id,
             COUNT(*) AS sales_count,
             COALESCE(SUM(fsi.amount_cents), 0) AS total_cents
      FROM financial_statement_sale_item fsi
      JOIN sale s ON s.id_sale = fsi.sale_id
      WHERE fsi.financial_statement_id = ?
      GROUP BY s.business_unit_id
      ''',
      [financialStatementId],
    );
  }

  Future<List<Map<String, Object?>>> getExpensesBreakdownByUnit(
    int financialStatementId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.rawQuery(
      '''
      SELECT e.business_unit_id AS business_unit_id,
             COUNT(*) AS expenses_count,
             COALESCE(SUM(fei.amount_cents), 0) AS total_cents
      FROM financial_statement_expense_item fei
      JOIN expense e ON e.id_expense = fei.expense_id
      WHERE fei.financial_statement_id = ?
      GROUP BY e.business_unit_id
      ''',
      [financialStatementId],
    );
  }

}