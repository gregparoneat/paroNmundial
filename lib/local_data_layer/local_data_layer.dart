import 'package:fantacy11/app_config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataLayer {
  LocalDataLayer._privateConstructor() {
    _initPref();
  }

  static final LocalDataLayer _instance = LocalDataLayer._privateConstructor();

  factory LocalDataLayer() {
    return _instance;
  }

  static const String _currentLanguageKey = "key_cur_lang";
  SharedPreferences? _sharedPreferences;

  Future<void> _initPref() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  Future<void> clearPrefs() async {
    await _initPref();
    await _sharedPreferences!.clear();
  }

  Future<bool> clearPrefKey(String key) async {
    await _initPref();
    return _sharedPreferences!.remove(key);
  }

  Future<String> getCurrentLanguage() async {
    await _initPref();
    return _sharedPreferences!.getString(_currentLanguageKey) ??
        AppConfig.languageDefault;
  }

  Future<void> setCurrentLanguage(String langCode) async {
    await _initPref();
    await _sharedPreferences!.setString(_currentLanguageKey, langCode);
  }
}
