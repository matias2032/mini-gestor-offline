import 'package:flutter/foundation.dart';

import '../models/expense_category_split_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._expenseRepository);

  final ExpenseRepository _expenseRepository;

  List<ExpenseModel> _expenses = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Active filters — null means "no filter" for that field.
  int? _filterBusinessCategoryId;
  int? _filterSupplierId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<ExpenseModel> get expenses => _expenses;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get filterBusinessCategoryId => _filterBusinessCategoryId;
  int? get filterSupplierId => _filterSupplierId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  bool get hasActiveFilters =>
      _filterBusinessCategoryId != null ||
      _filterSupplierId != null ||
      _filterStartDate != null ||
      _filterEndDate != null;



  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _expenseRepository.getAllExpenses(
        businessCategoryId: _filterBusinessCategoryId,
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
    int? businessCategoryId,
    bool clearBusinessCategoryId = false,
    int? supplierId,
    bool clearSupplierId = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) async {
    _filterBusinessCategoryId =
        clearBusinessCategoryId ? null : (businessCategoryId ?? _filterBusinessCategoryId);
    _filterSupplierId = clearSupplierId ? null : (supplierId ?? _filterSupplierId);
    _filterStartDate = clearStartDate ? null : (startDate ?? _filterStartDate);
    _filterEndDate = clearEndDate ? null : (endDate ?? _filterEndDate);
    await loadExpenses();
  }

  Future<void> clearFilters() async {
    _filterBusinessCategoryId = null;
    _filterSupplierId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    await loadExpenses();
  }

  Future<bool> createExpense({
    required List<ExpenseCategoryAllocation> categoryAllocations,
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
        categoryAllocations: categoryAllocations,
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
    required List<ExpenseCategoryAllocation> categoryAllocations,
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
        categoryAllocations: categoryAllocations,
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


/// Existing category splits for [idExpense] — used to pre-fill the
  /// allocation UI when editing a shared expense.
  Future<List<ExpenseCategorySplitModel>> getSplitsByExpense(int idExpense) {
    return _expenseRepository.getSplitsByExpense(idExpense);
  }


}