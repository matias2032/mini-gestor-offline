// providers/sale_provider.dart

import 'package:flutter/foundation.dart';
import '../models/sale_model.dart';
import '../repositories/sale_repository.dart';
import 'business_unit_provider.dart';

/// Thin UI state holder for the sale module (sale, sale_category,
/// sale_installment, sale_payment). Zero business logic — only calls
/// SaleRepository and exposes loading/error/data for the UI. Listens to
/// [BusinessUnitProvider] so switching the active store reloads every
/// sale-scoped list/stat automatically.
class SaleProvider extends ChangeNotifier {
  SaleProvider(this._saleRepository, this._businessUnitProvider) {
    _businessUnitProvider.addListener(_onActiveUnitChanged);
  }

  final SaleRepository _saleRepository;
  final BusinessUnitProvider _businessUnitProvider;

  List<SaleModel> _sales = [];
  List<SaleModel> _creditSales = [];
  SaleModel? _currentSale;
  List<SaleInstallmentModel> _installments = [];
  List<SalePaymentModel> _payments = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Remembers the last filters used in loadSales, so mutations (create,
  // cancel, payment) and store switches can refresh the list with the
  // same view active.
  int? _lastSaleCategoryId;
  int? _lastCustomerId;
  String? _lastSaleType;
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;

  // Whether loadCreditSales was ever called — lets mutations decide
  // whether it's worth refreshing that list too. Filters for it are kept
  // separately since it's shown on its own screen.
  bool _creditSalesLoaded = false;
  int? _lastCreditCustomerId;
  DateTime? _lastCreditStartDate;
  DateTime? _lastCreditEndDate;

  // Remembers which sale's installments/payments are currently loaded, so
  // registerPayment/cancelSale can keep the detail screen in sync.
  int? _currentSaleId;

  // Count of not-yet-finalized credit sales — drives the sidebar badge.
  // Kept separate from _creditSales so any screen can trigger/read it
  // without paying for the full credit-sales list load.
  int _outstandingCreditCount = 0;

  DashboardStats _dashboardStats = DashboardStats.empty();
  DashboardPeriod _dashboardPeriod = DashboardPeriod.oneMonth;

  List<SaleModel> get sales => _sales;
  List<SaleModel> get creditSales => _creditSales;
  SaleModel? get currentSale => _currentSale;
  List<SaleInstallmentModel> get installments => _installments;
  List<SalePaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get outstandingCreditCount => _outstandingCreditCount;
  DashboardStats get dashboardStats => _dashboardStats;
  DashboardPeriod get dashboardPeriod => _dashboardPeriod;

  int? get _activeUnitId => _businessUnitProvider.activeBusinessUnit?.idBusinessUnit;

  // ---------------------------------------------------------------------
  // sale
  // ---------------------------------------------------------------------

  /// Loads the main sales list: every NORMAL sale, plus CREDIT sales only
  /// once they're finalized (COMPLETED/CANCELLED). Active credit sales
  /// live in [loadCreditSales] instead.
  Future<void> loadSales({
    int? saleCategoryId,
    int? customerId,
    String? saleType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _lastSaleCategoryId = saleCategoryId;
    _lastCustomerId = customerId;
    _lastSaleType = saleType;
    _lastStartDate = startDate;
    _lastEndDate = endDate;

    final unitId = _activeUnitId;
    if (unitId == null) {
      _sales = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _sales = await _saleRepository.getSalesForSalesList(
        businessUnitId: unitId,
        saleCategoryId: saleCategoryId,
        customerId: customerId,
        saleType: saleType,
        startDate: startDate,
        endDate: endDate,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Loads the credit sales list screen: active (unpaid) credit sales
  /// only. Once a credit sale is fully paid or cancelled it disappears
  /// from here and shows up in [loadSales] instead.
  Future<void> loadCreditSales({
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _creditSalesLoaded = true;
    _lastCreditCustomerId = customerId;
    _lastCreditStartDate = startDate;
    _lastCreditEndDate = endDate;

    final unitId = _activeUnitId;
    if (unitId == null) {
      _creditSales = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _creditSales = await _saleRepository.getOutstandingCreditSales(
        businessUnitId: unitId,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createSale({
    required int saleCategoryId,
    required String description,
    required int totalAmountCents,
    String saleType = 'NORMAL',
    int? customerId,
    String? walkInCustomerName,
    DateTime? creditDueDate,
    String? notes,
    // Optional down payment for a CREDIT sale; leave null/0 for no entry
    // (the full total starts out as outstanding debt).
    int? initialPaymentCents,
    String initialPaymentMethod = 'CASH',
  }) async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _errorMessage = 'No active business unit selected.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _saleRepository.createSale(
        businessUnitId: unitId,
        saleCategoryId: saleCategoryId,
        description: description,
        totalAmountCents: totalAmountCents,
        saleType: saleType,
        customerId: customerId,
        walkInCustomerName: walkInCustomerName,
        creditDueDate: creditDueDate,
        notes: notes,
        initialPaymentCents: initialPaymentCents,
        initialPaymentMethod: initialPaymentMethod,
      );
      await _refreshSales();
      if (_creditSalesLoaded) await _refreshCreditSales();
      await loadOutstandingCreditCount();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelSale({
    required int saleId,
    required String cancellationReason,
  }) async {
    _setLoading(true);
    try {
      await _saleRepository.cancelSale(
        saleId: saleId,
        cancellationReason: cancellationReason,
      );
      await _refreshSales();
      if (_creditSalesLoaded) await _refreshCreditSales();
      if (_currentSaleId == saleId) {
        await _refreshSaleDetail(saleId);
      }
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerPayment({
    required int saleId,
    required int paidAmountCents,
    String paymentMethod = 'CASH',
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _saleRepository.registerPayment(
        saleId: saleId,
        paidAmountCents: paidAmountCents,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await _refreshSales();
      if (_creditSalesLoaded) await _refreshCreditSales();
      if (_currentSaleId == saleId) {
        await _refreshSaleDetail(saleId);
      }
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Loads a sale's installments and payments together — used by the
  /// sale detail screen. Subsequent registerPayment/cancelSale calls for
  /// this same saleId keep this data in sync automatically.
  Future<void> loadSaleDetail(int saleId) async {
    _currentSaleId = saleId;
    _setLoading(true);
    try {
      await _refreshSaleDetail(saleId);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the sidebar badge count. Best-effort: a failure here
  /// shouldn't surface as a page-level error, so it doesn't touch
  /// _errorMessage/_isLoading. No-op if there's no active store yet.
  Future<void> loadOutstandingCreditCount() async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _outstandingCreditCount = 0;
      notifyListeners();
      return;
    }
    try {
      _outstandingCreditCount =
          await _saleRepository.countOutstandingCreditSales(businessUnitId: unitId);
      notifyListeners();
    } catch (_) {
      // Badge is non-critical; silently keep the last known value.
    }
  }

  /// Loads dashboard stats for [period] (or the last one used, if
  /// omitted). Called on dashboard init and whenever the user switches
  /// the period filter.
  Future<void> loadDashboardStats({DashboardPeriod? period}) async {
    if (period != null) _dashboardPeriod = period;

    final unitId = _activeUnitId;
    if (unitId == null) {
      _dashboardStats = DashboardStats.empty();
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final now = DateTime.now();
      _dashboardStats = await _saleRepository.getDashboardStats(
        businessUnitId: unitId,
        startDate: _dashboardPeriod.startDateFrom(now),
        endDate: now,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _refreshSales() async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _sales = [];
      return;
    }
    _sales = await _saleRepository.getSalesForSalesList(
      businessUnitId: unitId,
      saleCategoryId: _lastSaleCategoryId,
      customerId: _lastCustomerId,
      saleType: _lastSaleType,
      startDate: _lastStartDate,
      endDate: _lastEndDate,
    );
  }

  Future<void> _refreshCreditSales() async {
    final unitId = _activeUnitId;
    if (unitId == null) {
      _creditSales = [];
      return;
    }
    _creditSales = await _saleRepository.getOutstandingCreditSales(
      businessUnitId: unitId,
      customerId: _lastCreditCustomerId,
      startDate: _lastCreditStartDate,
      endDate: _lastCreditEndDate,
    );
  }

  Future<void> _refreshSaleDetail(int saleId) async {
    _currentSale = await _saleRepository.getSaleById(saleId);
    _installments = await _saleRepository.getInstallmentsBySale(saleId);
    _payments = await _saleRepository.getPaymentsBySale(saleId);
  }

  /// Standalone lookup of a sale's installments, independent from the
  /// loadSaleDetail/_currentSale flow. Meant to be called per-row from a
  /// FutureBuilder (e.g. the finished sales list), so it never touches
  /// isLoading/errorMessage or the detail-screen state.
  Future<List<SaleInstallmentModel>> installmentsForSale(int saleId) {
    return _saleRepository.getInstallmentsBySale(saleId);
  }

  /// Reloads every store-scoped list/stat currently in use when the
  /// active business unit changes. Detail state (_currentSale, etc.) is
  /// intentionally left untouched — a sale detail screen open on a sale
  /// from the previous store shouldn't silently vanish under the user.
  void _onActiveUnitChanged() {
    loadSales(
      saleCategoryId: _lastSaleCategoryId,
      customerId: _lastCustomerId,
      saleType: _lastSaleType,
      startDate: _lastStartDate,
      endDate: _lastEndDate,
    );
    if (_creditSalesLoaded) {
      loadCreditSales(
        customerId: _lastCreditCustomerId,
        startDate: _lastCreditStartDate,
        endDate: _lastCreditEndDate,
      );
    }
    loadOutstandingCreditCount();
    loadDashboardStats();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _businessUnitProvider.removeListener(_onActiveUnitChanged);
    super.dispose();
  }
}