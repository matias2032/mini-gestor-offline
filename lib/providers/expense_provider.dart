import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import 'business_unit_provider.dart';

/// Thin UI state holder for the expense list.
///
/// Zero business logic — only calls ExpenseRepository and exposes
/// loading/error/data state for the UI. Listens to [BusinessUnitProvider]
/// so switching the active store reloads the list automatically.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._expenseRepository, this._businessUnitProvider) {
    _businessUnitProvider.addListener(_onActiveUnitChanged);
  }

  final ExpenseRepository _expenseRepository;
  final BusinessUnitProvider _businessUnitProvider;

  List<ExpenseModel> _expenses = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Active filters — null means "no filter" for that field.
  int? _filterSupplierId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<ExpenseModel> get expenses => _expenses;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get filterSupplierId => _filterSupplierId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  bool get hasActiveFilters =>
      _filterSupplierId != null ||
      _filterStartDate != null ||
      _filterEndDate != null;

  int? get _activeUnitId => _businessUnitProvider.activeBusinessUnit?.idBusinessUnit;

  /// getAllExpenses requires a non-null businessUnitId, so with no active
  /// store yet (e.g. BusinessUnitProvider still loading on startup) this
  /// just clears the list instead of calling the repository.
  Future<void> loadExpenses() async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _expenses = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _expenseRepository.getAllExpenses(
        businessUnitId: unitId,
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
    int? supplierId,
    bool clearSupplierId = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) async {
    _filterSupplierId = clearSupplierId ? null : (supplierId ?? _filterSupplierId);
    _filterStartDate = clearStartDate ? null : (startDate ?? _filterStartDate);
    _filterEndDate = clearEndDate ? null : (endDate ?? _filterEndDate);
    await loadExpenses();
  }

  Future<void> clearFilters() async {
    _filterSupplierId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    await loadExpenses();
  }

  Future<bool> createExpense({
    int? supplierId,
    required String description,
    required int amountCents,
    required DateTime expenseDate,
  }) async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _errorMessage = 'No active business unit selected.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseRepository.createExpense(
        businessUnitId: unitId,
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

  void _onActiveUnitChanged() {
    loadExpenses();
  }

  @override
  void dispose() {
    _businessUnitProvider.removeListener(_onActiveUnitChanged);
    super.dispose();
  }
}