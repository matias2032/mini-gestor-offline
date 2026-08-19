import 'package:flutter/foundation.dart';

import '../models/business_unit_model.dart';
import '../repositories/business_unit_repository.dart';

/// Holds the list of business units and which one is currently active
/// across the whole app (e.g. the store switcher in the dashboard AppBar).
///
/// Other providers (`SaleProvider`, `ExpenseProvider`, `CustomerProvider`,
/// ...) are expected to depend on [activeBusinessUnit] and reload their
/// data whenever it changes — that wiring happens in FASE 5 (Providers).
class BusinessUnitProvider extends ChangeNotifier {
  BusinessUnitProvider({BusinessUnitRepository? repository})
      : _repository = repository ?? BusinessUnitRepository();

  final BusinessUnitRepository _repository;

  List<BusinessUnitModel> _units = [];
  BusinessUnitModel? _activeUnit;
  bool _isLoading = false;
  String? _error;

  List<BusinessUnitModel> get units => List.unmodifiable(_units);
  BusinessUnitModel? get activeBusinessUnit => _activeUnit;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMultipleUnits => _units.length > 1;

  /// Loads all active units and resolves which one should be active.
  /// [preferredActiveId] lets a caller (e.g. after creating a new unit and
  /// switching to it) force the selection.
  Future<void> loadUnits({int? preferredActiveId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _units = await _repository.getAll();
      _activeUnit = _resolveActiveUnit(preferredActiveId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  BusinessUnitModel? _resolveActiveUnit(int? preferredActiveId) {
    if (_units.isEmpty) return null;

    if (preferredActiveId != null) {
      for (final unit in _units) {
        if (unit.idBusinessUnit == preferredActiveId) return unit;
      }
    }

    if (_activeUnit != null) {
      for (final unit in _units) {
        if (unit.idBusinessUnit == _activeUnit!.idBusinessUnit) return unit;
      }
    }

    return _units.firstWhere((u) => u.isDefault, orElse: () => _units.first);
  }

  /// Switches the active unit. Screens/providers that depend on it should
  /// listen to this provider and refetch when it changes.
  void setActiveUnit(BusinessUnitModel unit) {
    if (_activeUnit?.idBusinessUnit == unit.idBusinessUnit) return;
    _activeUnit = unit;
    notifyListeners();
  }

  Future<void> createUnit(String name) async {
    final unit = await _repository.create(name);
    _units = [..._units, unit];
    notifyListeners();
  }

  Future<void> renameUnit(int id, String newName) async {
    await _repository.rename(id, newName);
    await loadUnits(preferredActiveId: _activeUnit?.idBusinessUnit);
  }

  Future<void> setAsDefault(int id) async {
    await _repository.setAsDefault(id);
    await loadUnits(preferredActiveId: id);
  }

  Future<void> deleteUnit(int id) async {
    await _repository.delete(id);
    final wasActive = _activeUnit?.idBusinessUnit == id;
    await loadUnits(
      preferredActiveId: wasActive ? null : _activeUnit?.idBusinessUnit,
    );
  }
}