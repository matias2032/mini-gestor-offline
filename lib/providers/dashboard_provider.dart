// providers/dashboard_provider.dart

import 'package:flutter/foundation.dart';
import '../models/sale_model.dart';
import '../repositories/sale_repository.dart';
import 'business_unit_provider.dart';

/// Which slice of data the dashboard currently shows.
enum DashboardScope { currentStore, allStores }

/// Thin UI state holder for the Dashboard (Individual + Super).
///
/// Zero business logic — only calls SaleRepository and exposes
/// loading/error/data for the UI. Listens to [BusinessUnitProvider] so
/// switching the active store reloads stats automatically (only
/// relevant while [scope] is [DashboardScope.currentStore] — switching
/// stores has no effect on the consolidated view). Re-fetches whenever
/// the period or the scope changes.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._saleRepository, this._businessUnitProvider) {
    _businessUnitProvider.addListener(_onActiveUnitChanged);
  }

  final SaleRepository _saleRepository;
  final BusinessUnitProvider _businessUnitProvider;

  DashboardScope _scope = DashboardScope.currentStore;
  DashboardPeriod _period = DashboardPeriod.oneMonth;

  DashboardStats? _stats;
  ConsolidatedDashboardStats? _consolidatedStats;

  bool _isLoading = false;
  String? _errorMessage;

  DashboardScope get scope => _scope;
  DashboardPeriod get period => _period;

  /// Populated only while scope == currentStore.
  DashboardStats? get stats => _stats;

  /// Populated only while scope == allStores.
  ConsolidatedDashboardStats? get consolidatedStats => _consolidatedStats;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get _activeUnitId => _businessUnitProvider.activeBusinessUnit?.idBusinessUnit;

  Future<void> loadStats() async {
    if (_scope == DashboardScope.allStores) {
      await _loadConsolidatedStats();
    } else {
      await _loadCurrentStoreStats();
    }
  }

  /// getDashboardStats requires a non-null businessUnitId, so with no
  /// active store yet (e.g. BusinessUnitProvider still loading on
  /// startup) this just clears the stats instead of calling the
  /// repository.
  Future<void> _loadCurrentStoreStats() async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _stats = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _saleRepository.getDashboardStats(
        businessUnitId: unitId,
        period: _period,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadConsolidatedStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _consolidatedStats = await _saleRepository.getConsolidatedDashboardStats(
        period: _period,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switches scope and reloads. No-op if it hasn't actually changed.
  Future<void> setScope(DashboardScope scope) async {
    if (scope == _scope) return;
    _scope = scope;
    await loadStats();
  }

  /// Switches the period and reloads. No-op if it hasn't actually
  /// changed, so re-selecting the same dropdown value doesn't trigger a
  /// redundant query.
  Future<void> setPeriod(DashboardPeriod period) async {
    if (period == _period) return;
    _period = period;
    await loadStats();
  }

  /// Only the currentStore scope depends on the active business unit;
  /// switching stores while viewing "all stores" is a no-op for the data
  /// shown (though the app-wide active unit still changes for every
  /// other screen).
  void _onActiveUnitChanged() {
    if (_scope == DashboardScope.currentStore) {
      loadStats();
    }
  }

  @override
  void dispose() {
    _businessUnitProvider.removeListener(_onActiveUnitChanged);
    super.dispose();
  }
}