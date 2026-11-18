import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({this._preferences});

  static const _preferenceKey = 'app_locale';
  static const supportedLocales = <Locale>[
    Locale('es', 'MX'),
    Locale('en', 'US'),
  ];

  SharedPreferences? _preferences;
  Locale _locale = supportedLocales.first;

  Locale get locale => _locale;

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(
      scope != null,
      'AppLocaleController is not available in this context',
    );
    return scope!.controller;
  }

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final savedLocale = _preferences!.getString(_preferenceKey);
    if (savedLocale == null) return;

    final locale = _localeFromValue(savedLocale);
    if (locale != null) _locale = locale;
  }

  Future<void> setLocale(Locale locale) async {
    final supported = _localeFromValue(locale.toLanguageTag());
    if (supported == null || supported == _locale) return;

    _locale = supported;
    notifyListeners();
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_preferenceKey, supported.toLanguageTag());
  }

  Locale? _localeFromValue(String value) {
    for (final locale in supportedLocales) {
      if (locale.toLanguageTag() == value || locale.languageCode == value) {
        return locale;
      }
    }
    return null;
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    required AppLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  AppLocaleController get controller => notifier!;
}
