import 'package:flutter/foundation.dart';

import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';
import 'business_unit_provider.dart';

/// Thin UI state holder for the customer list.
///
/// Zero business logic — only calls CustomerRepository and exposes
/// loading/error/data state for the UI to react to. Listens to
/// [BusinessUnitProvider] so switching the active store reloads the
/// hybrid-filtered customer list automatically.
class CustomerProvider extends ChangeNotifier {
  CustomerProvider(this._customerRepository, this._businessUnitProvider) {
    _businessUnitProvider.addListener(_onActiveUnitChanged);
  }

  final CustomerRepository _customerRepository;
  final BusinessUnitProvider _businessUnitProvider;

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Remembers the last includeDeleted flag used, so a store switch keeps
  // the same view active.
  bool _lastIncludeDeleted = false;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get _activeUnitId => _businessUnitProvider.activeBusinessUnit?.idBusinessUnit;

  Future<void> loadCustomers({bool includeDeleted = false}) async {
    _lastIncludeDeleted = includeDeleted;
    _setLoading(true);
    try {
      _customers = await _customerRepository.getAllCustomers(
        activeUnitId: _activeUnitId,
        includeDeleted: includeDeleted,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createCustomer({
    required String name,
    String? lastName,
    String? phone,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _customerRepository.createCustomer(
        name: name,
        lastName: lastName,
        phone: phone,
        notes: notes,
        businessUnitId: _activeUnitId,
      );
      _errorMessage = null;
      await loadCustomers(includeDeleted: _lastIncludeDeleted);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateCustomer({
    required int idCustomer,
    String? name,
    String? lastName,
    String? phone,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _customerRepository.updateCustomer(
        idCustomer: idCustomer,
        name: name,
        lastName: lastName,
        phone: phone,
        notes: notes,
      );
      _errorMessage = null;
      await loadCustomers(includeDeleted: _lastIncludeDeleted);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCustomer(int idCustomer) async {
    _setLoading(true);
    try {
      await _customerRepository.deleteCustomer(idCustomer);
      _errorMessage = null;
      await loadCustomers(includeDeleted: _lastIncludeDeleted);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _setLoading(false);
      return false;
    }
  }

  void _onActiveUnitChanged() {
    loadCustomers(includeDeleted: _lastIncludeDeleted);
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