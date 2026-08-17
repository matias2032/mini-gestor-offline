import '../core/database/local_database.dart';
import '../daos/business_category_dao.dart';
import '../daos/expense_category_split_dao.dart';
import '../daos/expense_dao.dart';
import '../models/expense_category_split_model.dart';
import '../models/expense_model.dart';

/// One category's slice of an expense being created/updated — the input
/// shape for [ExpenseRepository.createExpense]/[updateExpense]. Not a
/// direct model: it deliberately has no id, since splits are always
/// replaced wholesale rather than edited individually.
class ExpenseCategoryAllocation {
  const ExpenseCategoryAllocation({
    required this.businessCategoryId,
    required this.amountCents,
  });

  final int businessCategoryId;
  final int amountCents;
}

class ExpenseRepository {
  ExpenseRepository(
    this._localDatabase,
    this._expenseDao,
    this._expenseCategorySplitDao,
    this._businessCategoryDao,
  );

  final LocalDatabase _localDatabase;
  final ExpenseDao _expenseDao;
  final ExpenseCategorySplitDao _expenseCategorySplitDao;
  final BusinessCategoryDao _businessCategoryDao;

  // ---------------- expense ----------------

  Future<List<ExpenseModel>> getAllExpenses({
    int? businessCategoryId,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _expenseDao.getAllExpenses(
      businessCategoryId: businessCategoryId,
      supplierId: supplierId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ExpenseModel?> getExpenseById(int idExpense) {
    return _expenseDao.getExpenseById(idExpense);
  }

  Future<List<ExpenseCategorySplitModel>> getSplitsByExpense(int idExpense) {
    return _expenseCategorySplitDao.getSplitsByExpense(idExpense);
  }

  Future<ExpenseModel> createExpense({
    required List<ExpenseCategoryAllocation> categoryAllocations,
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
    await _validateAllocations(categoryAllocations, amountCents);

    return _localDatabase.runInTransaction((txn) async {
      final expense = ExpenseModel(
        supplierId: supplierId,
        description: description.trim(),
        amountCents: amountCents,
        expenseDate: expenseDate,
        createdAt: DateTime.now(),
      );

      final id = await _expenseDao.insertExpense(expense, txn: txn);
      await _expenseCategorySplitDao.insertSplits(
        categoryAllocations
            .map((a) => ExpenseCategorySplitModel(
                  expenseId: id,
                  businessCategoryId: a.businessCategoryId,
                  amountCents: a.amountCents,
                ))
            .toList(),
        txn: txn,
      );

      return expense.copyWith(idExpense: id);
    });
  }

  Future<ExpenseModel> updateExpense({
    required int idExpense,
    required List<ExpenseCategoryAllocation> categoryAllocations,
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
    await _validateAllocations(categoryAllocations, amountCents);

    final updated = existing.copyWith(
      supplierId: supplierId,
      description: description.trim(),
      amountCents: amountCents,
      expenseDate: expenseDate,
    );

    await _localDatabase.runInTransaction((txn) async {
      await _expenseDao.updateExpense(updated, txn: txn);
      // Splits are always replaced wholesale, not diffed — simpler and
      // avoids partial-update edge cases (e.g. a category removed from
      // the allocation).
      await _expenseCategorySplitDao.deleteSplitsByExpense(idExpense, txn: txn);
      await _expenseCategorySplitDao.insertSplits(
        categoryAllocations
            .map((a) => ExpenseCategorySplitModel(
                  expenseId: idExpense,
                  businessCategoryId: a.businessCategoryId,
                  amountCents: a.amountCents,
                ))
            .toList(),
        txn: txn,
      );
    });

    return updated;
  }

  /// Ensures the allocation is well-formed: at least one category, no
  /// category repeated, every category exists and isn't deleted, and the
  /// amounts add up exactly to the expense total — this is the invariant
  /// that keeps per-category totals in the financial statement correct
  /// without ever double-counting the expense itself.
  Future<void> _validateAllocations(
    List<ExpenseCategoryAllocation> allocations,
    int amountCents,
  ) async {
    if (allocations.isEmpty) {
      throw ArgumentError('An expense needs at least one category.');
    }

    final seenCategoryIds = <int>{};
    var sum = 0;
    for (final allocation in allocations) {
      if (allocation.amountCents <= 0) {
        throw ArgumentError('Each category allocation must be greater than zero.');
      }
      if (!seenCategoryIds.add(allocation.businessCategoryId)) {
        throw ArgumentError('The same category cannot be allocated twice.');
      }
      final category =
          await _businessCategoryDao.getCategoryById(allocation.businessCategoryId);
      if (category == null || category.deleted) {
        throw StateError('Selected category is not available.');
      }
      sum += allocation.amountCents;
    }

    if (sum != amountCents) {
      throw ArgumentError(
        'Category allocations (${sum}) must add up to the expense total (${amountCents}).',
      );
    }
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