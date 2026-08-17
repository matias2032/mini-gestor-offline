// business_category_dao.dart
import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../models/business_category_model.dart';

class BusinessCategoryDao {
  BusinessCategoryDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<int> insertCategory(
    BusinessCategoryModel category, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('business_category', category.toMap());
  }

  Future<int> updateCategory(
    BusinessCategoryModel category, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'business_category',
      category.toMap(),
      where: 'id_business_category = ?',
      whereArgs: [category.idBusinessCategory],
    );
  }

  Future<int> softDeleteCategory(
    int idBusinessCategory, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'business_category',
      {'deleted': 1},
      where: 'id_business_category = ?',
      whereArgs: [idBusinessCategory],
    );
  }

  Future<BusinessCategoryModel?> getCategoryById(
    int idBusinessCategory, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'business_category',
      where: 'id_business_category = ?',
      whereArgs: [idBusinessCategory],
    );
    if (rows.isEmpty) return null;
    return BusinessCategoryModel.fromMap(rows.first);
  }

  Future<List<BusinessCategoryModel>> getAllCategories({
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'business_category',
      where: includeDeleted ? null : 'deleted = 0',
      orderBy: 'name ASC',
    );
    return rows.map(BusinessCategoryModel.fromMap).toList();
  }
}