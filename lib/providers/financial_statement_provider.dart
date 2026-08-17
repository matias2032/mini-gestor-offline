// financial_statement_provider.dart
import 'package:flutter/foundation.dart';

import '../models/financial_statement_model.dart';
import '../repositories/financial_statement_repository.dart';

/// Thin UI state holder for the financial_statement module. Zero
/// business logic — only calls FinancialStatementRepository and exposes
/// loading/error/data for the UI.
class FinancialStatementProvider extends ChangeNotifier {
  FinancialStatementProvider(this._repository);

  final FinancialStatementRepository _repository;

  List<FinancialStatementModel> _statements = [];
  FinancialStatementDetail? _currentDetail;

  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  // Remembers the last filters used in loadStatements, so a generation
  // can refresh the list with the same view active.
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;

  List<FinancialStatementModel> get statements => _statements;
  FinancialStatementDetail? get currentDetail => _currentDetail;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  Future<void> loadStatements({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _lastStartDate = startDate;
    _lastEndDate = endDate;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statements = await _repository.getAllStatements(
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
  /// on failure (check [errorMessage]).
  Future<FinancialStatementModel?> generateStatement({
    required StatementPeriodType periodType,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? notes,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final statement = await _repository.generateStatement(
        periodType: periodType,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
        notes: notes,
      );
      _statements = await _repository.getAllStatements(
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
}