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
  Future<List<FinancialStatementModel>> getAllStatements({
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
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
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
  Future<List<Map<String, Object?>>> getFinalizedSalesInPeriod({
    required DateTime startDate,
    required DateTime endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.rawQuery(
      '''
      SELECT s.id_sale, s.reference, s.description, s.sale_date,
             s.total_amount_cents,
             s.sale_category_id AS business_category_id,
             bc.name AS business_category_name
      FROM sale s
      LEFT JOIN business_category bc
        ON bc.id_business_category = s.sale_category_id
      WHERE s.deleted = 0 AND s.sale_status = 'COMPLETED'
        AND s.sale_date >= ? AND s.sale_date <= ?
      ORDER BY s.sale_date ASC
      ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  Future<List<Map<String, Object?>>> getExpensesInPeriod({
    required DateTime startDate,
    required DateTime endDate,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.rawQuery(
      '''
      SELECT e.id_expense, e.description, e.expense_date,
             ecs.amount_cents,
             ecs.business_category_id AS business_category_id,
             bc.name AS business_category_name
      FROM expense e
      JOIN expense_category_split ecs ON ecs.expense_id = e.id_expense
      LEFT JOIN business_category bc
        ON bc.id_business_category = ecs.business_category_id
      WHERE e.deleted = 0
        AND e.expense_date >= ? AND e.expense_date <= ?
      ORDER BY e.expense_date ASC
      ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }
}