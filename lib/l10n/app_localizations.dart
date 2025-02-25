import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<void> load() async {
    String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap;
  }

  // Public getter to expose the raw JSON map.
  Map<String, dynamic> get localizedStrings => _localizedStrings;

  // Translate a single string; supports nested keys (e.g. "genders.male")
  String translate(String key) {
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;
    for (var k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }
    return value?.toString() ?? key;
  }

  // Helper method to fetch a list from the JSON.
  List<String> translateList(String key) {
    final dynamic value = _localizedStrings[key];
    if (value is List) {
      return List<String>.from(value);
    }
    return [];
  }

  // Helper method to fetch a map from the JSON.
  Map<String, List<String>> translateMap(String key) {
    final dynamic value = _localizedStrings[key];
    if (value is Map) {
      return value.map((key, value) {
        if (value is List) {
          return MapEntry(key.toString(), List<String>.from(value));
        }
        return MapEntry(key.toString(), <String>[]);
      });
    }
    return {};
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
