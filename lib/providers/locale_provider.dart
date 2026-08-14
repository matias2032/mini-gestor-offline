// lib/providers/locale_provider.dart — completo (ficheiro novo, por isso sem "antes")
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'locale_code';

  Locale? _locale; // null = segue o idioma do sistema

  Locale? get locale => _locale;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;

    _locale = _localeFromCode(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _codeFromLocale(locale));
  }

  Future<void> useSystemLocale() async {
    _locale = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Locale _localeFromCode(String code) => Locale(code);

  String _codeFromLocale(Locale locale) => locale.languageCode;
}