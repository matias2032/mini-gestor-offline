// business_category_repository.dart
import '../daos/business_category_dao.dart';
import '../models/business_category_model.dart';

/// All business logic for the single, shared category table used by
/// both sales and expenses ("ramo de negócio"). Neither SaleRepository
/// nor ExpenseRepository owns this anymore — they only read from it
/// (e.g. ExpenseRepository validates a category exists before attaching
/// it to an expense).
class BusinessCategoryRepository {
  BusinessCategoryRepository(this._dao);

  final BusinessCategoryDao _dao;

  Future<List<BusinessCategoryModel>> getAllCategories({
    bool includeDeleted = false,
  }) {
    return _dao.getAllCategories(includeDeleted: includeDeleted);
  }

  Future<BusinessCategoryModel?> getCategoryById(int idBusinessCategory) {
    return _dao.getCategoryById(idBusinessCategory);
  }

  Future<BusinessCategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }
    final category = BusinessCategoryModel(
      name: trimmedName,
      description: _cleanOrNull(description),
      createdAt: DateTime.now(),
    );
    final id = await _dao.insertCategory(category);
    return category.copyWith(idBusinessCategory: id);
  }

  Future<BusinessCategoryModel> updateCategory({
    required int idBusinessCategory,
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }
    final current = await _dao.getCategoryById(idBusinessCategory);
    if (current == null) {
      throw StateError('Category not found.');
    }
    final updated = current.copyWith(
      name: trimmedName,
      description: _cleanOrNull(description),
      updatedAt: DateTime.now(),
    );
    await _dao.updateCategory(updated);
    return updated;
  }

  Future<void> deleteCategory(int idBusinessCategory) {
    return _dao.softDeleteCategory(idBusinessCategory);
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}