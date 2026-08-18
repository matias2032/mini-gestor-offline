import 'package:flutter/foundation.dart';

import '../models/business_category_model.dart';
import '../repositories/business_category_repository.dart';
import 'business_unit_provider.dart';

/// Thin UI state holder for the shared business_category table. Used
/// wherever a category picker or a category management screen is
/// needed, by both the sales and expenses flows.
class BusinessCategoryProvider extends ChangeNotifier {
  BusinessCategoryProvider(this._repository, this._businessUnitProvider) {
    _businessUnitProvider.addListener(_onActiveUnitChanged);
  }

  final BusinessCategoryRepository _repository;
  final BusinessUnitProvider _businessUnitProvider;

  List<BusinessCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _lastIncludeDeleted = false;

  List<BusinessCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get _activeUnitId => _businessUnitProvider.activeBusinessUnit?.idBusinessUnit;

  Future<void> loadCategories({bool includeDeleted = false}) async {
    _lastIncludeDeleted = includeDeleted;
    _setLoading(true);
    try {
      _categories = await _repository.getAllCategories(
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

  Future<bool> createCategory({required String name, String? description}) async {
    _setLoading(true);
    try {
      await _repository.createCategory(
        name: name,
        description: description,
        businessUnitId: _activeUnitId,
      );
      _categories = await _repository.getAllCategories(
        activeUnitId: _activeUnitId,
        includeDeleted: _lastIncludeDeleted,
      );
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
    required int idBusinessCategory,
    required String name,
    String? description,
  }) async {
    _setLoading(true);
    try {
      await _repository.updateCategory(
        idBusinessCategory: idBusinessCategory,
        name: name,
        description: description,
      );
      _categories = await _repository.getAllCategories(
        activeUnitId: _activeUnitId,
        includeDeleted: _lastIncludeDeleted,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(int idBusinessCategory) async {
    _setLoading(true);
    try {
      await _repository.deleteCategory(idBusinessCategory);
      _categories = await _repository.getAllCategories(
        activeUnitId: _activeUnitId,
        includeDeleted: _lastIncludeDeleted,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _onActiveUnitChanged() {
    loadCategories(includeDeleted: _lastIncludeDeleted);
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