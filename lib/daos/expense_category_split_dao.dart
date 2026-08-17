import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../models/expense_category_split_model.dart';

class ExpenseCategorySplitDao {
  ExpenseCategorySplitDao(this._localDatabase);

  final LocalDatabase _localDatabase;

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