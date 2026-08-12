// repositories/user_repository.dart

import '../core/database/local_database.dart';
import '../daos/user_dao.dart';
import '../models/user_model.dart';
import 'package:bcrypt/bcrypt.dart';

/// All business logic for the single-user profile.
///
/// Enforces the "there is exactly one user, with id_user = 1" rule that
/// the schema expresses via CHECK but cannot fully guarantee on its own
/// (e.g. preventing a second insert, deciding what a fresh install means).
class UserRepository {
  UserRepository(this._database, this._userDao);

  final LocalDatabase _database;
  final UserDao _userDao;

  static const int _singletonId = 1;

  /// Returns the current user, or null if onboarding has never run.
  Future<UserModel?> getCurrentUser() {
    return _userDao.getUser();
  }

  Future<bool> hasUser() {
    return _userDao.userExists();
  }

  /// Creates the single user row. Fails if a user already exists —
  /// callers should route existing users to [updateProfile] instead.
  Future<UserModel> createUser({
    required String name,
    required String password,
    String? lastName,
    String? phone,
    String? email,
    String? businessName,
    String currency = 'MZN',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('User name cannot be empty.');
    }
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters long.');
    }

    return _database.runInTransaction((txn) async {
      final exists = await _userDao.userExists(txn: txn);
      if (exists) {
        throw StateError('A user already exists; use updateProfile instead.');
      }

      final user = UserModel(
        idUser: _singletonId,
        name: trimmedName,
        lastName: _cleanOrNull(lastName),
        phone: _cleanOrNull(phone),
        email: _cleanOrNull(email),
        passwordHash: BCrypt.hashpw(password, BCrypt.gensalt()),
        businessName: _cleanOrNull(businessName),
        currency: currency.trim().isEmpty ? 'MZN' : currency.trim(),
        onboardingCompleted: false,
        createdAt: DateTime.now(),
      );

      await _userDao.insertUser(user, txn: txn);
      return user;
    });
  }

  /// Verifies the given password against the stored hash. Returns the
  /// user on success, null on wrong password. Throws if no user exists
  /// yet (caller should be redirecting to onboarding in that case).
  Future<UserModel?> login({required String password}) async {
    final current = await _userDao.getUser();
    if (current == null) {
      throw StateError('Cannot login: no user exists yet.');
    }
    final matches = BCrypt.checkpw(password, current.passwordHash);
    return matches ? current : null;
  }

  /// Changes the password after verifying the current one.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw ArgumentError('Password must be at least 6 characters long.');
    }
    return _database.runInTransaction((txn) async {
      final current = await _userDao.getUser(txn: txn);
      if (current == null) {
        throw StateError('Cannot change password: no user exists yet.');
      }
      if (!BCrypt.checkpw(currentPassword, current.passwordHash)) {
        return false;
      }
      final updated = current.copyWith(
        passwordHash: BCrypt.hashpw(newPassword, BCrypt.gensalt()),
        updatedAt: DateTime.now(),
      );
      await _userDao.updateUser(updated, txn: txn);
      return true;
    });
  }

  /// Updates profile fields. Only non-null arguments are changed.
  Future<UserModel> updateProfile({
    String? name,
    String? lastName,
    String? phone,
    String? email,
    String? businessName,
    String? currency,
  }) async {
    return _database.runInTransaction((txn) async {
      final current = await _userDao.getUser(txn: txn);
      if (current == null) {
        throw StateError('Cannot update profile: no user exists yet.');
      }

      if (name != null && name.trim().isEmpty) {
        throw ArgumentError('User name cannot be empty.');
      }

      final updated = current.copyWith(
        name: name?.trim(),
        lastName: _cleanOrNull(lastName),
        phone: _cleanOrNull(phone),
        email: _cleanOrNull(email),
        businessName: _cleanOrNull(businessName),
        currency: currency != null && currency.trim().isNotEmpty
            ? currency.trim()
            : null,
        updatedAt: DateTime.now(),
      );

      await _userDao.updateUser(updated, txn: txn);
      return updated;
    });
  }

  /// Marks onboarding as done. Idempotent — calling it again is a no-op
  /// beyond bumping updated_at.
  Future<UserModel> completeOnboarding() async {
    return _database.runInTransaction((txn) async {
      final current = await _userDao.getUser(txn: txn);
      if (current == null) {
        throw StateError('Cannot complete onboarding: no user exists yet.');
      }

      final updated = current.copyWith(
        onboardingCompleted: true,
        updatedAt: DateTime.now(),
      );

      await _userDao.updateUser(updated, txn: txn);
      return updated;
    });
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}