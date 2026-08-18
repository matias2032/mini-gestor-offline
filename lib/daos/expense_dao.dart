// expense_dao.dart
import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/expense_model.dart';

/// Pure data access for the `expense` aggregate: expense and
/// expense_category_split. Unified into one DAO because a split has no
/// independent lifecycle from the expense it allocates — same reasoning
/// used to fold sale_installment/sale_payment into SaleDao.
class ExpenseDao {
  ExpenseDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  // ---------------------------------------------------------------------
  // expense
  // ---------------------------------------------------------------------

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
  ///
  /// All filters are combined with AND. Date bounds are inclusive and
  /// compared as ISO-8601 strings, consistent with how `expense_date` is
  /// stored. Filtering by category is a sub-select against
  /// expense_category_split, since a single expense can belong to more
  /// than one category.
  Future<List<ExpenseModel>> getAllExpenses({
    required int businessUnitId,
    int? businessCategoryId,
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
    if (businessCategoryId != null) {
      conditions.add(
        'id_expense IN ('
        'SELECT expense_id FROM expense_category_split '
        'WHERE business_category_id = ?)',
      );
      args.add(businessCategoryId);
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

  // ---------------------------------------------------------------------
  // expense_category_split
  // ---------------------------------------------------------------------

  Future<void> insertSplits(
    List<ExpenseCategorySplitModel> splits, {
    required Transaction txn,
  }) async {
    final batch = txn.batch();
    for (final split in splits) {
      batch.insert('expense_category_split', split.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<ExpenseCategorySplitModel>> getSplitsByExpense(
    int expenseId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'expense_category_split',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    return rows.map(ExpenseCategorySplitModel.fromMap).toList();
  }

  /// Deletes all splits for [expenseId] — used by updateExpense, which
  /// replaces the whole allocation rather than diffing it.
  Future<void> deleteSplitsByExpense(
    int expenseId, {
    required Transaction txn,
  }) async {
    await txn.delete(
      'expense_category_split',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
  }
}