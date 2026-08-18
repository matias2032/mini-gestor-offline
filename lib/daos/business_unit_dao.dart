import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../models/business_unit_model.dart';

/// Direct SQL access to the `business_unit` table.
///
/// This layer knows nothing about business rules (uniqueness of name,
/// "always keep at least one active unit", onboarding, etc). Those live in
/// [BusinessUnitRepository]. A DAO method takes an optional [Transaction] so
/// callers can compose it inside a larger transaction (e.g. creating the
/// user and the first business unit together during onboarding).
class BusinessUnitDao {
  static const String table = 'business_unit';

  Future<Database> get _db async => LocalDatabase.instance.database;

  Future<int> insert(BusinessUnitModel unit, {Transaction? txn}) async {
    final executor = txn ?? await _db;
    return executor.insert(table, unit.toInsertMap());
  }

  Future<int> update(BusinessUnitModel unit, {Transaction? txn}) async {
    assert(
      unit.idBusinessUnit != null,
      'Cannot update a BusinessUnitModel without an id.',
    );
    final executor = txn ?? await _db;
    return executor.update(
      table,
      unit.toUpdateMap(),
      where: 'id_business_unit = ?',
      whereArgs: [unit.idBusinessUnit],
    );
  }

  Future<int> softDelete(int idBusinessUnit, {Transaction? txn}) async {
    final executor = txn ?? await _db;
    return executor.update(
      table,
      {'deleted': 1},
      where: 'id_business_unit = ?',
      whereArgs: [idBusinessUnit],
    );
  }

  Future<BusinessUnitModel?> findById(
    int idBusinessUnit, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _db;
    final rows = await executor.query(
      table,
      where: 'id_business_unit = ?',
      whereArgs: [idBusinessUnit],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BusinessUnitModel.fromMap(rows.first);
  }

  Future<BusinessUnitModel?> findDefault({Transaction? txn}) async {
    final executor = txn ?? await _db;
    final rows = await executor.query(
      table,
      where: 'is_default = 1 AND deleted = 0',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BusinessUnitModel.fromMap(rows.first);
  }

  Future<List<BusinessUnitModel>> findAll({
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final executor = txn ?? await _db;
    final rows = await executor.query(
      table,
      where: includeDeleted ? null : 'deleted = 0',
      orderBy: 'is_default DESC, name ASC',
    );
    return rows.map(BusinessUnitModel.fromMap).toList();
  }

  Future<int> countActive({Transaction? txn}) async {
    final executor = txn ?? await _db;
    final result = await executor.rawQuery(
      'SELECT COUNT(*) AS total FROM $table WHERE deleted = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}