// business_category_provider.dart
import 'package:flutter/foundation.dart';

import '../models/business_category_model.dart';
import '../repositories/business_category_repository.dart';

/// Thin UI state holder for the shared business_category table. Used
/// wherever a category picker or a category management screen is
/// needed, by both the sales and expenses flows.
class BusinessCategoryProvider extends ChangeNotifier {
  BusinessCategoryProvider(this._repository);

  final BusinessCategoryRepository _repository;

  List<BusinessCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BusinessCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories({bool includeDeleted = false}) async {
    _setLoading(true);
    try {
      _categories =
          await _repository.getAllCategories(includeDeleted: includeDeleted);
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
      await _repository.createCategory(name: name, description: description);
      _categories = await _repository.getAllCategories();
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
      _categories = await _repository.getAllCategories();
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
      _categories = await _repository.getAllCategories();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}