import 'package:flutter/foundation.dart';

import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._expenseRepository);

  final ExpenseRepository _expenseRepository;

  List<ExpenseModel> _expenses = [];
  List<ExpenseCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Active filters — null means "no filter" for that field.
  int? _filterCategoryId;
  int? _filterSupplierId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get filterCategoryId => _filterCategoryId;
  int? get filterSupplierId => _filterSupplierId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  bool get hasActiveFilters =>
      _filterCategoryId != null ||
      _filterSupplierId != null ||
      _filterStartDate != null ||
      _filterEndDate != null;

  Future<void> loadCategories() async {
    _categories = await _expenseRepository.getAllCategories();
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _expenseRepository.getAllExpenses(
        expenseCategoryId: _filterCategoryId,
        supplierId: _filterSupplierId,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the active filters and reloads the list. Pass `clear: true`
  /// on a field to explicitly reset it to "no filter" (since `null` here
  /// means "leave unchanged", not "clear").
  Future<void> applyFilters({
    int? categoryId,
    bool clearCategoryId = false,
    int? supplierId,
    bool clearSupplierId = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) async {
    _filterCategoryId = clearCategoryId ? null : (categoryId ?? _filterCategoryId);
    _filterSupplierId = clearSupplierId ? null : (supplierId ?? _filterSupplierId);
    _filterStartDate = clearStartDate ? null : (startDate ?? _filterStartDate);
    _filterEndDate = clearEndDate ? null : (endDate ?? _filterEndDate);
    await loadExpenses();
  }

  Future<void> clearFilters() async {
    _filterCategoryId = null;
    _filterSupplierId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    await loadExpenses();
  }

  Future<bool> createExpense({
    required int expenseCategoryId,
    int? supplierId,
    required String description,
    required int amountCents,
    required DateTime expenseDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseRepository.createExpense(
        expenseCategoryId: expenseCategoryId,
        supplierId: supplierId,
        description: description,
        amountCents: amountCents,
        expenseDate: expenseDate,
      );
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense({
    required int idExpense,
    required int expenseCategoryId,
    int? supplierId,
    required String description,
    required int amountCents,
    required DateTime expenseDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseRepository.updateExpense(
        idExpense: idExpense,
        expenseCategoryId: expenseCategoryId,
        supplierId: supplierId,
        description: description,
        amountCents: amountCents,
        expenseDate: expenseDate,
      );
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int idExpense, String deletionReason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseRepository.deleteExpense(idExpense, deletionReason);
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

Future<bool> createCategory({required String name, String? description}) async {
    try {
      await _expenseRepository.createCategory(name: name, description: description);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory({
    required int idExpenseCategory,
    required String name,
    String? description,
  }) async {
    try {
      await _expenseRepository.updateCategory(
        idExpenseCategory: idExpenseCategory,
        name: name,
        description: description,
      );
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int idExpenseCategory) async {
    try {
      await _expenseRepository.deleteCategory(idExpenseCategory);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}