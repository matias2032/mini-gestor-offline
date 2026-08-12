import '../core/database/local_database.dart';
import '../daos/supplier_dao.dart';
import '../models/supplier_model.dart';

/// All business logic for suppliers: validation, soft-delete enforcement,
/// and update guards. Screens and providers must never talk to
/// SupplierDao directly.
class SupplierRepository {
  SupplierRepository(this._localDatabase, this._supplierDao);

  final LocalDatabase _localDatabase;
  final SupplierDao _supplierDao;

  Future<List<SupplierModel>> getAllSuppliers({
    bool includeDeleted = false,
  }) {
    return _supplierDao.getAllSuppliers(includeDeleted: includeDeleted);
  }

  Future<SupplierModel?> getSupplierById(int idSupplier) {
    return _supplierDao.getSupplierById(idSupplier);
  }

  Future<SupplierModel> createSupplier({
    required String name,
    String? phone,
    String? address,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Supplier name cannot be empty.');
    }

    final supplier = SupplierModel(
      name: name.trim(),
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );

    final id = await _supplierDao.insertSupplier(supplier);
    return supplier.copyWith(idSupplier: id);
  }

  Future<SupplierModel> updateSupplier({
    required int idSupplier,
    required String name,
    String? phone,
    String? address,
  }) async {
    final existing = await _supplierDao.getSupplierById(idSupplier);
    if (existing == null) {
      throw StateError('Supplier not found.');
    }
    if (existing.deleted) {
      throw StateError('Cannot update a deleted supplier.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Supplier name cannot be empty.');
    }

    final updated = existing.copyWith(
      name: name.trim(),
      phone: phone,
      address: address,
    );

    await _supplierDao.updateSupplier(updated);
    return updated;
  }

  Future<void> deleteSupplier(int idSupplier) async {
    final existing = await _supplierDao.getSupplierById(idSupplier);
    if (existing == null) {
      throw StateError('Supplier not found.');
    }
    if (existing.deleted) {
      return;
    }
    await _supplierDao.softDeleteSupplier(idSupplier);
  }
}