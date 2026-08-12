import 'package:flutter/foundation.dart';

import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

/// Thin UI state holder for the customer list.
///
/// Zero business logic — only calls CustomerRepository and exposes
/// loading/error/data state for the UI to react to.
class CustomerProvider extends ChangeNotifier {
  CustomerProvider(this._customerRepository);

  final CustomerRepository _customerRepository;

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCustomers({bool includeDeleted = false}) async {
    _setLoading(true);
    try {
      _customers = await _customerRepository.getAllCustomers(
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
      );
      _errorMessage = null;
      await loadCustomers();
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
      await loadCustomers();
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
      await loadCustomers();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}