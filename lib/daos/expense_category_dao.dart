import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/expense_category_model.dart';

class ExpenseCategoryDao {
  ExpenseCategoryDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<int> insertCategory(
    ExpenseCategoryModel category, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('expense_category', category.toMap());
  }

  Future<int> updateCategory(
    ExpenseCategoryModel category, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'expense_category',
      category.toMap(),
      where: 'id_expense_category = ?',
      whereArgs: [category.idExpenseCategory],
    );
  }

  Future<int> softDeleteCategory(
    int idExpenseCategory, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'expense_category',
      {'deleted': 1},
      where: 'id_expense_category = ?',
      whereArgs: [idExpenseCategory],
    );
  }

  Future<ExpenseCategoryModel?> getCategoryById(
    int idExpenseCategory, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'expense_category',
      where: 'id_expense_category = ?',
      whereArgs: [idExpenseCategory],
    );
    if (rows.isEmpty) return null;
    return ExpenseCategoryModel.fromMap(rows.first);
  }

  Future<List<ExpenseCategoryModel>> getAllCategories({
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'expense_category',
      where: includeDeleted ? null : 'deleted = 0',
      orderBy: 'name ASC',
    );
    return rows.map(ExpenseCategoryModel.fromMap).toList();
  }
}