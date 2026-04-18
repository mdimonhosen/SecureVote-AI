import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  Map<String, String>? _localizedStrings;
  static const String _prefKey = 'selected_language';

  Future<void> init() async {
    String lang = await getLanguage();
    await load(lang);
  }

  Future<void> load(String langCode) async {
    String jsonString = await rootBundle.loadString('assets/lang/$langCode.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }

  Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
    await load(langCode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? 'bn';
  }
}
