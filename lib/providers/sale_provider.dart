// providers/sale_provider.dart

import 'package:flutter/foundation.dart';
import '../models/sale_category_model.dart';
import '../models/sale_installment_model.dart';
import '../models/sale_model.dart';
import '../models/sale_payment_model.dart';
import '../repositories/sale_repository.dart';

/// Thin UI state holder for the sale module (sale, sale_category,
/// sale_installment, sale_payment). Zero business logic — only calls
/// SaleRepository and exposes loading/error/data for the UI.
class SaleProvider extends ChangeNotifier {
  SaleProvider(this._saleRepository);

  final SaleRepository _saleRepository;

List<SaleCategoryModel> _categories = [];
  List<SaleModel> _sales = [];
  List<SaleModel> _creditSales = [];
  SaleModel? _currentSale;
  List<SaleInstallmentModel> _installments = [];
  List<SalePaymentModel> _payments = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Remembers the last filters used in loadSales, so mutations (create,
  // cancel, payment) can refresh the list with the same view active.
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

List<SaleCategoryModel> get categories => _categories;
  List<SaleModel> get sales => _sales;
  List<SaleModel> get creditSales => _creditSales;
  SaleModel? get currentSale => _currentSale;
  List<SaleInstallmentModel> get installments => _installments;
  List<SalePaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------
  // sale_category
  // ---------------------------------------------------------------------

  Future<void> loadCategories({bool includeDeleted = false}) async {
    _setLoading(true);
    try {
      _categories =
          await _saleRepository.getAllCategories(includeDeleted: includeDeleted);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createCategory({
    required String name,
    String? description,
  }) async {
    _setLoading(true);
    try {
      await _saleRepository.createCategory(name: name, description: description);
      _categories = await _saleRepository.getAllCategories();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategory({
    required int idSaleCategory,
    required String name,
    String? description,
  }) async {
    _setLoading(true);
    try {
      await _saleRepository.updateCategory(
        idSaleCategory: idSaleCategory,
        name: name,
        description: description,
      );
      _categories = await _saleRepository.getAllCategories();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(int idSaleCategory) async {
    _setLoading(true);
    try {
      await _saleRepository.deleteCategory(idSaleCategory);
      _categories = await _saleRepository.getAllCategories();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

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

    _setLoading(true);
    try {
      _sales = await _saleRepository.getSalesForSalesList(
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

    _setLoading(true);
    try {
      _creditSales = await _saleRepository.getOutstandingCreditSales(
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
    _setLoading(true);
    try {
      await _saleRepository.createSale(
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

Future<void> _refreshSales() async {
    _sales = await _saleRepository.getSalesForSalesList(
      saleCategoryId: _lastSaleCategoryId,
      customerId: _lastCustomerId,
      saleType: _lastSaleType,
      startDate: _lastStartDate,
      endDate: _lastEndDate,
    );
  }

  Future<void> _refreshCreditSales() async {
    _creditSales = await _saleRepository.getOutstandingCreditSales(
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}