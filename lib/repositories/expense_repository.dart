import '../core/database/local_database.dart';
import '../daos/expense_category_dao.dart';
import '../daos/expense_dao.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';

/// All business logic for the expense module: expenses and their
/// categories. Screens and providers must never talk to the DAOs
/// directly.
class ExpenseRepository {
  ExpenseRepository(
    this._localDatabase,
    this._expenseDao,
    this._expenseCategoryDao,
  );

  final LocalDatabase _localDatabase;
  final ExpenseDao _expenseDao;
  final ExpenseCategoryDao _expenseCategoryDao;

  // ---------------- expense_category ----------------

  Future<List<ExpenseCategoryModel>> getAllCategories({
    bool includeDeleted = false,
  }) {
    return _expenseCategoryDao.getAllCategories(includeDeleted: includeDeleted);
  }

  Future<ExpenseCategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    final category = ExpenseCategoryModel(
      name: name.trim(),
      description: description,
    );

    final id = await _expenseCategoryDao.insertCategory(category);
    return category.copyWith(idExpenseCategory: id);
  }

  Future<ExpenseCategoryModel> updateCategory({
    required int idExpenseCategory,
    required String name,
    String? description,
  }) async {
    final existing = await _expenseCategoryDao.getCategoryById(
      idExpenseCategory,
    );
    if (existing == null) {
      throw StateError('Category not found.');
    }
    if (existing.deleted) {
      throw StateError('Cannot update a deleted category.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    final updated = existing.copyWith(name: name.trim(), description: description);
    await _expenseCategoryDao.updateCategory(updated);
    return updated;
  }

  Future<void> deleteCategory(int idExpenseCategory) async {
    final existing = await _expenseCategoryDao.getCategoryById(
      idExpenseCategory,
    );
    if (existing == null) {
      throw StateError('Category not found.');
    }
    if (existing.deleted) {
      return;
    }
    await _expenseCategoryDao.softDeleteCategory(idExpenseCategory);
  }

  // ---------------- expense ----------------

  Future<List<ExpenseModel>> getAllExpenses({
    int? expenseCategoryId,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _expenseDao.getAllExpenses(
      expenseCategoryId: expenseCategoryId,
      supplierId: supplierId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ExpenseModel?> getExpenseById(int idExpense) {
    return _expenseDao.getExpenseById(idExpense);
  }

  Future<ExpenseModel> createExpense({
    required int expenseCategoryId,
    int? supplierId,
    required String description,
    required int amountCents,
    required DateTime expenseDate,
  }) async {
    if (description.trim().isEmpty) {
      throw ArgumentError('Expense description cannot be empty.');
    }
    if (amountCents < 0) {
      throw ArgumentError('Expense amount cannot be negative.');
    }

    final category = await _expenseCategoryDao.getCategoryById(
      expenseCategoryId,
    );
    if (category == null || category.deleted) {
      throw StateError('Selected category is not available.');
    }

    final expense = ExpenseModel(
      expenseCategoryId: expenseCategoryId,
      supplierId: supplierId,
      description: description.trim(),
      amountCents: amountCents,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
    );

    final id = await _expenseDao.insertExpense(expense);
    return expense.copyWith(idExpense: id);
  }

  Future<ExpenseModel> updateExpense({
    required int idExpense,
    required int expenseCategoryId,
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
    if (amountCents < 0) {
      throw ArgumentError('Expense amount cannot be negative.');
    }

    final category = await _expenseCategoryDao.getCategoryById(
      expenseCategoryId,
    );
    if (category == null || category.deleted) {
      throw StateError('Selected category is not available.');
    }

    final updated = existing.copyWith(
      expenseCategoryId: expenseCategoryId,
      supplierId: supplierId,
      description: description.trim(),
      amountCents: amountCents,
      expenseDate: expenseDate,
    );

    await _expenseDao.updateExpense(updated);
    return updated;
  }

  /// Soft-deletes an expense. [deletionReason] is mandatory and cannot be
  /// blank — this is enforced here even though the DAO would technically
  /// accept an empty string.
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