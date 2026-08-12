import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/sale_payment_model.dart';

class SalePaymentDao {
  SalePaymentDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<int> insertPayment(
    SalePaymentModel payment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('sale_payment', payment.toMap());
  }

  Future<List<SalePaymentModel>> getPaymentsBySale(
    int saleId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_payment',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'paid_at DESC',
    );
    return rows.map(SalePaymentModel.fromMap).toList();
  }

  Future<bool> referenceExists(String reference, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_payment',
      where: 'reference = ?',
      whereArgs: [reference],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> countAll({Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final result =
        await executor.rawQuery('SELECT COUNT(*) AS total FROM sale_payment');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}