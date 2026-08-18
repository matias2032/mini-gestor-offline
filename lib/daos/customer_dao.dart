import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../models/customer_model.dart';

/// Pure CRUD access to the `customer` table.
///
/// No business rules here (e.g. whether deletion is soft or hard,
/// whether the name is required) — that belongs to CustomerRepository.
/// Note: unlike `user`/`sale`/`expense`, this table has no
/// `updated_at` trigger, so callers must set it explicitly.
class CustomerDao {
  CustomerDao(this._database);

  final LocalDatabase _database;

  static const String _table = 'customer';

  Future<DatabaseExecutor> _executor(Transaction? txn) async {
    return txn ?? await _database.database;
  }

  Future<int> insertCustomer(CustomerModel customer, {Transaction? txn}) async {
    final db = await _executor(txn);
    final map = customer.toMap()..remove('id_customer');
    return db.insert(_table, map);
  }

  Future<int> updateCustomer(CustomerModel customer, {Transaction? txn}) async {
    final db = await _executor(txn);
    return db.update(
      _table,
      customer.toMap(),
      where: 'id_customer = ?',
      whereArgs: [customer.idCustomer],
    );
  }

  Future<CustomerModel?> getCustomerById(int idCustomer, {Transaction? txn}) async {
    final db = await _executor(txn);
    final rows = await db.query(
      _table,
      where: 'id_customer = ?',
      whereArgs: [idCustomer],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CustomerModel.fromMap(rows.first);
  }

  Future<List<CustomerModel>> getAllCustomers({
    int? activeUnitId,
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final db = await _executor(txn);
    final conditions = <String>[
      '(business_unit_id IS NULL OR business_unit_id = ?)',
    ];
    final args = <Object?>[activeUnitId];
    if (!includeDeleted) {
      conditions.add('deleted = ?');
      args.add(0);
    }
    final rows = await db.query(
      _table,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'name ASC',
    );
    return rows.map(CustomerModel.fromMap).toList();
  }
}