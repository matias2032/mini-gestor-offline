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
    int? activeUnitId,
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
    final rows = await executor.query(
      'business_category',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'name ASC',
    );
    return rows.map(BusinessCategoryModel.fromMap).toList();
  }

  /// Every category, from every business unit, ignoring scope entirely.
  /// Used only by BusinessCategoryRepository to validate a Global
  /// category's name — a Global is visible in every loja, so its name
  /// must not collide with anyone's category, not just other Globals.
  Future<List<BusinessCategoryModel>> getAllCategoriesUnscoped({
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