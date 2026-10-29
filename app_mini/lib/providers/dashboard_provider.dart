import 'package:flutter/foundation.dart';
import '../models/sale_model.dart';
import '../repositories/sale_repository.dart';
import 'business_unit_provider.dart';
import '../models/daily_revenue_point.dart';

/* Identifies the data aggregation scope for dashboard statistics. */
enum DashboardScope { currentStore, allStores }

/* Thin UI state holder for the Dashboard (Individual and Consolidated).

Zero business logic — only calls SaleRepository and exposes loading/error/data 
for the UI. Listens to BusinessUnitProvider to automatically refresh metrics 
when the active business unit changes while in currentStore scope. */
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
  List<DailyRevenuePoint> _dailyRevenue = const [];

  bool _isLoading = false;
  String? _errorMessage;

  DashboardScope get scope => _scope;
  DashboardPeriod get period => _period;

// Populated only while scope == currentStore.
  DashboardStats? get stats => _stats;

// Populated only while scope == allStores.
  ConsolidatedDashboardStats? get consolidatedStats => _consolidatedStats;

// Daily revenue for the active scope and period.
  List<DailyRevenuePoint> get dailyRevenue => _dailyRevenue;

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

//Requires a non-null businessUnitId. Clears metrics if no unit is active. 
  Future<void> _loadCurrentStoreStats() async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _stats = null;
      _dailyRevenue = const [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _saleRepository.getDashboardStats(businessUnitId: unitId, period: _period),
        _saleRepository.getDailyRevenue(businessUnitId: unitId, period: _period),
      ]);
      _stats = results[0] as DashboardStats;
      _dailyRevenue = results[1] as List<DailyRevenuePoint>;
    } catch (error) {
      _errorMessage = error.toString();
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
      final results = await Future.wait([
        _saleRepository.getConsolidatedDashboardStats(period: _period),
        _saleRepository.getDailyRevenue(period: _period),
      ]);
      _consolidatedStats = results[0] as ConsolidatedDashboardStats;
      _dailyRevenue = results[1] as List<DailyRevenuePoint>;
    } catch (error) {
      _errorMessage = error.toString();
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

// Updates the selected timeframe period and reloads stats. 
  Future<void> setPeriod(DashboardPeriod period) async {
    if (period == _period) return;
    _period = period;
    await loadStats();
  }

// Reloads metrics when active unit changes, only if scoped to current store. 
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