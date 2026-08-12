// providers/user_provider.dart

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Thin UI state holder for the user profile.
///
/// Zero business logic — only calls UserRepository and exposes
/// loading/error/data state for the UI to react to.
class UserProvider extends ChangeNotifier {
  UserProvider(this._userRepository);

  final UserRepository _userRepository;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUser => _user != null;

  Future<void> loadUser() async {
    _setLoading(true);
    try {
      _user = await _userRepository.getCurrentUser();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

Future<bool> createUser({
    required String name,
    required String password,
    String? lastName,
    String? phone,
    String? email,
    String? businessName,
    String currency = 'MZN',
  }) async {
    _setLoading(true);
    try {
      _user = await _userRepository.createUser(
        name: name,
        password: password,
        lastName: lastName,
        phone: phone,
        email: email,
        businessName: businessName,
        currency: currency,
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

  Future<bool> login({required String password}) async {
    _setLoading(true);
    try {
      final result = await _userRepository.login(password: password);
      _errorMessage = result == null ? 'Incorrect password.' : null;
      return result != null;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? lastName,
    String? phone,
    String? email,
    String? businessName,
    String? currency,
  }) async {
    _setLoading(true);
    try {
      _user = await _userRepository.updateProfile(
        name: name,
        lastName: lastName,
        phone: phone,
        email: email,
        businessName: businessName,
        currency: currency,
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

  Future<bool> completeOnboarding() async {
    _setLoading(true);
    try {
      _user = await _userRepository.completeOnboarding();
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