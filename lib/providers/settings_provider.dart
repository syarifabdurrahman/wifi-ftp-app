import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  int _port = 2121;
  String _rootFolder = '/storage/emulated/0';
  bool _anonymousAccess = false;
  String _username = 'admin';
  String _password = 'password';
  bool _keepScreenOn = true;

  bool get isInitialized => _isInitialized;
  int get port => _port;
  String get rootFolder => _rootFolder;
  bool get anonymousAccess => _anonymousAccess;
  String get username => _username;
  String get password => _password;
  bool get keepScreenOn => _keepScreenOn;

  SettingsProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _port = _prefs.getInt('port') ?? 2121;
    _rootFolder = _prefs.getString('rootFolder') ?? '/storage/emulated/0';
    _anonymousAccess = _prefs.getBool('anonymousAccess') ?? false;
    _username = _prefs.getString('username') ?? 'admin';
    _password = _prefs.getString('password') ?? 'password';
    _keepScreenOn = _prefs.getBool('keepScreenOn') ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setPort(int value) async {
    _port = value;
    await _prefs.setInt('port', value);
    notifyListeners();
  }

  Future<void> setRootFolder(String value) async {
    _rootFolder = value;
    await _prefs.setString('rootFolder', value);
    notifyListeners();
  }

  Future<void> setAnonymousAccess(bool value) async {
    _anonymousAccess = value;
    await _prefs.setBool('anonymousAccess', value);
    notifyListeners();
  }

  Future<void> setUsername(String value) async {
    _username = value;
    await _prefs.setString('username', value);
    notifyListeners();
  }

  Future<void> setPassword(String value) async {
    _password = value;
    await _prefs.setString('password', value);
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    await _prefs.setBool('keepScreenOn', value);
    notifyListeners();
  }
}
