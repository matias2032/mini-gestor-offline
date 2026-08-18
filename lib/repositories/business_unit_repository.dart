import 'package:sqflite/sqflite.dart';

import '../daos/business_unit_dao.dart';
import '../models/business_unit_model.dart';

/// Business rules for business units: name validation/uniqueness,
/// guaranteeing there is always at least one active unit, and creating the
/// very first unit during onboarding.
class BusinessUnitRepository {
  BusinessUnitRepository({BusinessUnitDao? dao}) : _dao = dao ?? BusinessUnitDao();

  final BusinessUnitDao _dao;

  Future<List<BusinessUnitModel>> getAll({bool includeDeleted = false}) {
    return _dao.findAll(includeDeleted: includeDeleted);
  }

  Future<BusinessUnitModel?> getById(int id) => _dao.findById(id);

  Future<BusinessUnitModel?> getDefault() => _dao.findDefault();

  /// Creates the very first business unit for a brand-new account.
  ///
  /// Intended to be called from `UserRepository` *inside the same
  /// transaction* that creates the `user` row, so that "criar usuário +
  /// criar a primeira business_unit" is a single all-or-nothing operation,
  /// per the onboarding rule agreed for this migration.
  Future<BusinessUnitModel> createDefaultUnit(
    Transaction txn, {
    required String name,
  }) async {
    final trimmed = name.trim();
    final unit = BusinessUnitModel(
      name: trimmed.isEmpty ? 'Minha Loja' : trimmed,
      isDefault: true,
      createdAt: DateTime.now(),
    );
    final id = await _dao.insert(unit, txn: txn);
    return unit.copyWith(idBusinessUnit: id);
  }

  /// Creates an additional business unit (2ª loja em diante).
  Future<BusinessUnitModel> create(String name) async {
    final trimmed = _validateName(name);

    final existing = await _dao.findAll();
    final alreadyExists = existing.any(
      (unit) => unit.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (alreadyExists) {
      throw StateError('Já existe uma unidade de negócio com esse nome.');
    }

    final unit = BusinessUnitModel(
      name: trimmed,
      isDefault: false,
      createdAt: DateTime.now(),
    );
    final id = await _dao.insert(unit);
    return unit.copyWith(idBusinessUnit: id);
  }

  Future<void> rename(int id, String newName) async {
    final trimmed = _validateName(newName);

    final unit = await _dao.findById(id);
    if (unit == null) {
      throw StateError('Unidade de negócio não encontrada.');
    }
    await _dao.update(unit.copyWith(name: trimmed));
  }

  /// Soft-deletes a unit.
  ///
  /// Refuses to:
  ///  - remove the last remaining active unit (sale/expense always require
  ///    an active business unit to post to);
  ///  - remove the unit currently marked as default — the caller must
  ///    promote another unit first via [setAsDefault].
  Future<void> delete(int id) async {
    final active = await _dao.findAll();
    if (active.length <= 1) {
      throw StateError(
        'Não é possível remover a única unidade de negócio ativa.',
      );
    }

    final unit = active.firstWhere(
      (u) => u.idBusinessUnit == id,
      orElse: () => throw StateError('Unidade de negócio não encontrada.'),
    );
    if (unit.isDefault) {
      throw StateError(
        'Não é possível remover a unidade padrão. Defina outra unidade '
        'como padrão antes de remover esta.',
      );
    }

    await _dao.softDelete(id);
  }

  /// Promotes [id] to be the default unit, demoting whichever unit held
  /// that flag before. Kept as two updates rather than a raw SQL statement
  /// so both go through the same DAO write path.
  Future<void> setAsDefault(int id) async {
    final units = await _dao.findAll();
    final target = units.firstWhere(
      (u) => u.idBusinessUnit == id,
      orElse: () => throw StateError('Unidade de negócio não encontrada.'),
    );
    if (target.isDefault) return;

    for (final unit in units) {
      if (unit.isDefault) {
        await _dao.update(unit.copyWith(isDefault: false));
      }
    }
    await _dao.update(target.copyWith(isDefault: true));
  }

  String _validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('O nome da unidade de negócio não pode ser vazio.');
    }
    return trimmed;
  }
}