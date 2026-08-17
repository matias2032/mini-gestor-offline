// sale_installment_dao.dart
import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../models/sale_installment_model.dart';

class SaleInstallmentDao {
  SaleInstallmentDao(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<int> insertInstallment(
    SaleInstallmentModel installment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.insert('sale_installment', installment.toMap());
  }

  Future<int> updateInstallment(
    SaleInstallmentModel installment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale_installment',
      installment.toMap(),
      where: 'id_sale_installment = ?',
      whereArgs: [installment.idSaleInstallment],
    );
  }

  Future<List<SaleInstallmentModel>> getInstallmentsBySale(
    int saleId, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_installment',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'installment_number ASC',
    );
    return rows.map(SaleInstallmentModel.fromMap).toList();
  }

  Future<SaleInstallmentModel?> getInstallmentById(
    int idSaleInstallment, {
    Transaction? txn,
  }) async {
    final executor = txn ?? await _localDatabase.database;
    final rows = await executor.query(
      'sale_installment',
      where: 'id_sale_installment = ?',
      whereArgs: [idSaleInstallment],
    );
    if (rows.isEmpty) return null;
    return SaleInstallmentModel.fromMap(rows.first);
  }

Future<int> cancelUnpaidInstallments(int saleId, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    return executor.update(
      'sale_installment',
      {
        'installment_status': 'CANCELLED',
        'cancelled_by_sale_cancellation': 1,
      },
      where: 'sale_id = ? AND installment_status IN (?, ?)',
      whereArgs: [saleId, 'PENDING', 'PARTIAL'],
    );
  }

  /// Number of installments already generated for [saleId]. Since
  /// installments are no longer predefined — each payment automatically
  /// creates the "next" one — this is how SaleRepository knows the next
  /// installment_number to use.
  Future<int> countInstallmentsBySale(int saleId, {Transaction? txn}) async {
    final executor = txn ?? await _localDatabase.database;
    final result = await executor.rawQuery(
      'SELECT COUNT(*) AS total FROM sale_installment WHERE sale_id = ?',
      [saleId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}