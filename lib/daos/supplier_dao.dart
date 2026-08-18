import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../models/supplier_model.dart';

/// Pure CRUD access to the `supplier` table.
///
/// No business decisions here — e.g. whether a delete should be soft or
/// hard is decided by SupplierRepository; this DAO just exposes the raw
/// operations it needs.
class SupplierDao {
  SupplierDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<int> insertSupplier(
    SupplierModel supplier, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('supplier', supplier.toMap());
  }

  Future<int> updateSupplier(
    SupplierModel supplier, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'supplier',
      supplier.toMap(),
      where: 'id_supplier = ?',
      whereArgs: [supplier.idSupplier],
    );
  }

  Future<int> softDeleteSupplier(int idSupplier, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'supplier',
      {'deleted': 1},
      where: 'id_supplier = ?',
      whereArgs: [idSupplier],
    );
  }

  Future<SupplierModel?> getSupplierById(
    int idSupplier, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'supplier',
      where: 'id_supplier = ?',
      whereArgs: [idSupplier],
    );
    if (rows.isEmpty) return null;
    return SupplierModel.fromMap(rows.first);
  }

  Future<List<SupplierModel>> getAllSuppliers({
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
      'supplier',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'name ASC',
    );
    return rows.map(SupplierModel.fromMap).toList();
  }
}