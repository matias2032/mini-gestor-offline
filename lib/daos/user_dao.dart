// daos/user_dao.dart

import 'package:sqflite/sqflite.dart';

import '../core/database/local_database.dart';
import '../models/user_model.dart';

/// Pure CRUD access to the `user` table.
///
/// This table is a singleton (CHECK id_user = 1) — there is only ever
/// one row. This DAO does not enforce that rule; it only knows how to
/// read/write rows. Enforcing "there must be exactly one user" and any
/// onboarding-related decisions belong to UserRepository.
class UserDao {
  UserDao(this._database);

  final LocalDatabase _database;

  static const String _table = 'user';

  Future<DatabaseExecutor> _executor(Transaction? txn) async {
    return txn ?? await _database.database;
  }

  Future<int> insertUser(UserModel user, {Transaction? txn}) async {
    final db = await _executor(txn);
    return db.insert(_table, user.toMap());
  }

  Future<int> updateUser(UserModel user, {Transaction? txn}) async {
    final db = await _executor(txn);
    return db.update(
      _table,
      user.toMap(),
      where: 'id_user = ?',
      whereArgs: [user.idUser],
    );
  }

  Future<UserModel?> getUser({Transaction? txn}) async {
    final db = await _executor(txn);
    final rows = await db.query(_table, limit: 1);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<bool> userExists({Transaction? txn}) async {
    final db = await _executor(txn);
    final rows = await db.query(_table, limit: 1);
    return rows.isNotEmpty;
  }

  Future<int> deleteUser(int idUser, {Transaction? txn}) async {
    final db = await _executor(txn);
    return db.delete(_table, where: 'id_user = ?', whereArgs: [idUser]);
  }
}