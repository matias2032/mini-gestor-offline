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
    int? activeUnitId,
    bool includeDeleted = false,
  }) {
    return _dao.getAllCategories(
      activeUnitId: activeUnitId,
      includeDeleted: includeDeleted,
    );
  }

  Future<BusinessCategoryModel?> getCategoryById(int idBusinessCategory) {
    return _dao.getCategoryById(idBusinessCategory);
  }

  Future<BusinessCategoryModel> createCategory({
    required String name,
    String? description,
    int? businessUnitId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }
    await _ensureNameAvailable(name: trimmedName, businessUnitId: businessUnitId);

    final category = BusinessCategoryModel(
      name: trimmedName,
      description: _cleanOrNull(description),
      businessUnitId: businessUnitId,
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
    await _ensureNameAvailable(
      name: trimmedName,
      businessUnitId: current.businessUnitId,
      excludeId: idBusinessCategory,
    );

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

  /// Enforces name uniqueness (case-insensitive) within the correct scope:
  ///  - Global (`businessUnitId == null`): checked against every category
  ///    in every loja, since a Global is visible everywhere.
  ///  - Scoped to a unit: checked only against what that unit actually
  ///    sees — Globals plus its own categories — via the same hybrid
  ///    query the list screens already use.
  Future<void> _ensureNameAvailable({
    required String name,
    required int? businessUnitId,
    int? excludeId,
  }) async {
    final candidates = businessUnitId == null
        ? await _dao.getAllCategoriesUnscoped()
        : await _dao.getAllCategories(activeUnitId: businessUnitId);

    final clash = candidates.any(
      (category) =>
          category.idBusinessCategory != excludeId &&
          category.name.toLowerCase() == name.toLowerCase(),
    );
    if (clash) {
      throw StateError('A category with this name already exists in this scope.');
    }
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}