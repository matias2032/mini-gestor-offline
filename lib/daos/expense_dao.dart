// expense_dao.dart
import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/expense_model.dart';

/// Pure data access for the `expense` table. Since Schema v4 dropped
/// `expense_category_split`, an expense is once again a single flat
/// row — no aggregate/child tables to coordinate here anymore.
class ExpenseDao {
  ExpenseDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<int> insertExpense(
    ExpenseModel expense, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('expense', expense.toMap());
  }

  Future<int> updateExpense(
    ExpenseModel expense, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'expense',
      expense.toMap(),
      where: 'id_expense = ?',
      whereArgs: [expense.idExpense],
    );
  }

  Future<int> softDeleteExpense(
    int idExpense,
    String deletionReason, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'expense',
      {'deleted': 1, 'deletion_reason': deletionReason},
      where: 'id_expense = ?',
      whereArgs: [idExpense],
    );
  }

  Future<ExpenseModel?> getExpenseById(
    int idExpense, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'expense',
      where: 'id_expense = ?',
      whereArgs: [idExpense],
    );
    if (rows.isEmpty) return null;
    return ExpenseModel.fromMap(rows.first);
  }

  /// Returns expenses ordered by most recent first, with optional filters.
  /// All filters are combined with AND. Date bounds are inclusive and
  /// compared as ISO-8601 strings, consistent with how `expense_date` is
  /// stored. `businessUnitId` is strict scope (mandatory).
  Future<List<ExpenseModel>> getAllExpenses({
    required int businessUnitId,
    int? supplierId,
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
    if (supplierId != null) {
      conditions.add('supplier_id = ?');
      args.add(supplierId);
    }
    if (startDate != null) {
      conditions.add('expense_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('expense_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final rows = await executor.query(
      'expense',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'expense_date DESC',
    );
    return rows.map(ExpenseModel.fromMap).toList();
  }
}