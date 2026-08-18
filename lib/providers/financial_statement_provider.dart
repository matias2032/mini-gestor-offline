// financial_statement_provider.dart
import 'package:flutter/foundation.dart';

import '../models/financial_statement_model.dart';
import '../repositories/financial_statement_repository.dart';
import 'business_unit_provider.dart';

/// Thin UI state holder for the financial_statement module. Zero
/// business logic — only calls FinancialStatementRepository and exposes
/// loading/error/data for the UI.
///
/// By default every call is scoped to the active store. Pass
/// `consolidated: true` to generate/list across every store instead
/// (maps to the repository's `businessUnitId: null` / `activeUnitId:
/// null` "todas as lojas" behaviour). Listens to [BusinessUnitProvider]
/// and reloads the list on a store switch only while a scoped view is
/// active — a consolidated view doesn't change when the active store
/// changes.
class FinancialStatementProvider extends ChangeNotifier {
  FinancialStatementProvider(this._repository, this._businessUnitProvider) {
    _businessUnitProvider.addListener(_onActiveUnitChanged);
  }

  final FinancialStatementRepository _repository;
  final BusinessUnitProvider _businessUnitProvider;

  List<FinancialStatementModel> _statements = [];
  FinancialStatementDetail? _currentDetail;

  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  // Remembers the last filters used in loadStatements, so a generation
  // (or a store switch) can refresh the list with the same view active.
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;
  bool _lastConsolidated = false;

  List<FinancialStatementModel> get statements => _statements;
  FinancialStatementDetail? get currentDetail => _currentDetail;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  int? get _activeUnitId => _businessUnitProvider.activeBusinessUnit?.idBusinessUnit;

  Future<void> loadStatements({
    DateTime? startDate,
    DateTime? endDate,
    bool consolidated = false,
  }) async {
    _lastStartDate = startDate;
    _lastEndDate = endDate;
    _lastConsolidated = consolidated;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statements = await _repository.getAllStatements(
        activeUnitId: consolidated ? null : _activeUnitId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStatementDetail(int idFinancialStatement) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDetail = await _repository.getStatementDetail(idFinancialStatement);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates a new statement and refreshes the list with the last
  /// filters used. Returns the generated statement on success, or null
  /// on failure (check [errorMessage]). Scoped to the active store
  /// unless `consolidated: true` is passed.
  Future<FinancialStatementModel?> generateStatement({
    required StatementPeriodType periodType,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? notes,
    bool consolidated = false,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final statement = await _repository.generateStatement(
        periodType: periodType,
        businessUnitId: consolidated ? null : _activeUnitId,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
        notes: notes,
      );
      _statements = await _repository.getAllStatements(
        activeUnitId: _lastConsolidated ? null : _activeUnitId,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
      );
      return statement;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStatement(int idFinancialStatement) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteStatement(idFinancialStatement);
      _statements = await _repository.getAllStatements(
        activeUnitId: _lastConsolidated ? null : _activeUnitId,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onActiveUnitChanged() {
    if (!_lastConsolidated) {
      loadStatements(
        startDate: _lastStartDate,
        endDate: _lastEndDate,
        consolidated: false,
      );
    }
  }

  @override
  void dispose() {
    _businessUnitProvider.removeListener(_onActiveUnitChanged);
    super.dispose();
  }
}