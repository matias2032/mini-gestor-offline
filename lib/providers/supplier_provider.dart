import 'package:flutter/foundation.dart';

import '../models/supplier_model.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  SupplierProvider(this._supplierRepository);

  final SupplierRepository _supplierRepository;

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suppliers = await _supplierRepository.getAllSuppliers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSupplier({
    required String name,
    String? phone,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supplierRepository.createSupplier(
        name: name,
        phone: phone,
        address: address,
      );
      await loadSuppliers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier({
    required int idSupplier,
    required String name,
    String? phone,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supplierRepository.updateSupplier(
        idSupplier: idSupplier,
        name: name,
        phone: phone,
        address: address,
      );
      await loadSuppliers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(int idSupplier) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supplierRepository.deleteSupplier(idSupplier);
      await loadSuppliers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}