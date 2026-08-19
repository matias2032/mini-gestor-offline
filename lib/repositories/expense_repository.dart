import '../core/database/local_database.dart';
import '../daos/expense_dao.dart';
import '../models/expense_model.dart';

/// All business logic for expenses.
///
/// Since Schema v4 dropped `expense_category_split`, an expense is a
/// single flat record again — no allocation validation, no child-table
/// transaction. `businessUnitId` is strict scope: every expense belongs
/// to exactly one loja and is immutable after creation.
class ExpenseRepository {
  ExpenseRepository(this._localDatabase, this._expenseDao);

  final LocalDatabase _localDatabase;
  final ExpenseDao _expenseDao;

  Future<List<ExpenseModel>> getAllExpenses({
    required int businessUnitId,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _expenseDao.getAllExpenses(
      businessUnitId: businessUnitId,
      supplierId: supplierId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ExpenseModel?> getExpenseById(int idExpense) {
    return _expenseDao.getExpenseById(idExpense);
  }

  Future<ExpenseModel> createExpense({
    required int businessUnitId,
    int? supplierId,
    required String description,
    required int amountCents,
    required DateTime expenseDate,
  }) async {
    if (description.trim().isEmpty) {
      throw ArgumentError('Expense description cannot be empty.');
    }
    if (amountCents <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }

    final expense = ExpenseModel(
      supplierId: supplierId,
      description: description.trim(),
      amountCents: amountCents,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
      businessUnitId: businessUnitId,
    );

    final id = await _expenseDao.insertExpense(expense);
    return expense.copyWith(idExpense: id);
  }

  Future<ExpenseModel> updateExpense({
    required int idExpense,
    int? supplierId,
    required String description,
    required int amountCents,
    required DateTime expenseDate,
  }) async {
    final existing = await _expenseDao.getExpenseById(idExpense);
    if (existing == null) {
      throw StateError('Expense not found.');
    }
    if (existing.deleted) {
      throw StateError('Cannot update a deleted expense.');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('Expense description cannot be empty.');
    }
    if (amountCents <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }

    final updated = existing.copyWith(
      supplierId: supplierId,
      description: description.trim(),
      amountCents: amountCents,
      expenseDate: expenseDate,
    );

    await _expenseDao.updateExpense(updated);
    return updated;
  }

  Future<void> deleteExpense(int idExpense, String deletionReason) async {
    if (deletionReason.trim().isEmpty) {
      throw ArgumentError('A deletion reason is required.');
    }

    final existing = await _expenseDao.getExpenseById(idExpense);
    if (existing == null) {
      throw StateError('Expense not found.');
    }
    if (existing.deleted) {
      return;
    }

    await _expenseDao.softDeleteExpense(idExpense, deletionReason.trim());
  }
}