import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/sale_category_model.dart';

class SaleCategoryDao {
  SaleCategoryDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<int> insertCategory(
    SaleCategoryModel category, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('sale_category', category.toMap());
  }

  Future<int> updateCategory(
    SaleCategoryModel category, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale_category',
      category.toMap(),
      where: 'id_sale_category = ?',
      whereArgs: [category.idSaleCategory],
    );
  }

  Future<int> softDeleteCategory(
    int idSaleCategory, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale_category',
      {'deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id_sale_category = ?',
      whereArgs: [idSaleCategory],
    );
  }

  Future<SaleCategoryModel?> getCategoryById(
    int idSaleCategory, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_category',
      where: 'id_sale_category = ?',
      whereArgs: [idSaleCategory],
    );
    if (rows.isEmpty) return null;
    return SaleCategoryModel.fromMap(rows.first);
  }

  Future<List<SaleCategoryModel>> getAllCategories({
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_category',
      where: includeDeleted ? null : 'deleted = 0',
      orderBy: 'name ASC',
    );
    return rows.map(SaleCategoryModel.fromMap).toList();
  }
}