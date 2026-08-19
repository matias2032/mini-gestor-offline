import '../core/database/local_database.dart';
import '../daos/customer_dao.dart';
import '../models/customer_model.dart';

/// All business logic for customers.
///
/// Deletion is always soft (deleted = 1), never a physical DELETE, so
/// that sale history referencing a customer stays intact.
///
/// `businessUnitId` is strict scope (Schema v4) — every customer belongs
/// to exactly one loja, so it's now a required argument everywhere.
class CustomerRepository {
  CustomerRepository(this._database, this._customerDao);

  final LocalDatabase _database;
  final CustomerDao _customerDao;

  Future<List<CustomerModel>> getAllCustomers({
    required int businessUnitId,
    bool includeDeleted = false,
  }) {
    return _customerDao.getAllCustomers(
      businessUnitId: businessUnitId,
      includeDeleted: includeDeleted,
    );
  }

  Future<CustomerModel?> getCustomerById(int idCustomer) {
    return _customerDao.getCustomerById(idCustomer);
  }

  Future<CustomerModel> createCustomer({
    required String name,
    required int businessUnitId,
    String? lastName,
    String? phone,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Customer name cannot be empty.');
    }

    return _database.runInTransaction((txn) async {
      final draft = CustomerModel(
        idCustomer: 0, // placeholder — replaced below with the real id
        name: trimmedName,
        lastName: _cleanOrNull(lastName),
        phone: _cleanOrNull(phone),
        notes: _cleanOrNull(notes),
        businessUnitId: businessUnitId,
        createdAt: DateTime.now(),
      );

      final newId = await _customerDao.insertCustomer(draft, txn: txn);
      return CustomerModel(
        idCustomer: newId,
        name: draft.name,
        lastName: draft.lastName,
        phone: draft.phone,
        notes: draft.notes,
        businessUnitId: draft.businessUnitId,
        deleted: draft.deleted,
        createdAt: draft.createdAt,
        updatedAt: draft.updatedAt,
      );
    });
  }

  Future<CustomerModel> updateCustomer({
    required int idCustomer,
    String? name,
    String? lastName,
    String? phone,
    String? notes,
  }) async {
    return _database.runInTransaction((txn) async {
      final current = await _customerDao.getCustomerById(idCustomer, txn: txn);
      if (current == null) {
        throw StateError('Customer not found: $idCustomer');
      }
      if (current.deleted) {
        throw StateError('Cannot update a deleted customer.');
      }

      if (name != null && name.trim().isEmpty) {
        throw ArgumentError('Customer name cannot be empty.');
      }

      final updated = current.copyWith(
        name: name?.trim(),
        lastName: _cleanOrNull(lastName),
        phone: _cleanOrNull(phone),
        notes: _cleanOrNull(notes),
        updatedAt: DateTime.now(),
      );

      await _customerDao.updateCustomer(updated, txn: txn);
      return updated;
    });
  }

  /// Soft-deletes the customer. Sale history referencing this customer
  /// is preserved — the row is only flagged, never removed.
  Future<CustomerModel> deleteCustomer(int idCustomer) async {
    return _database.runInTransaction((txn) async {
      final current = await _customerDao.getCustomerById(idCustomer, txn: txn);
      if (current == null) {
        throw StateError('Customer not found: $idCustomer');
      }

      final updated = current.copyWith(
        deleted: true,
        updatedAt: DateTime.now(),
      );

      await _customerDao.updateCustomer(updated, txn: txn);
      return updated;
    });
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}