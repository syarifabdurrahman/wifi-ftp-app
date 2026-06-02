import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quick_wifi_share/models/server_profile.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  String get _defaultRootFolder {
    if (Platform.isWindows) return Platform.environment['USERPROFILE'] ?? 'C:\\';
    if (Platform.isLinux || Platform.isMacOS) return Platform.environment['HOME'] ?? '/';
    return '/storage/emulated/0';
  }

  int _port = 2121;
  late String _rootFolder = _defaultRootFolder;
  bool _anonymousAccess = false;
  String _username = 'admin';
  String _password = 'password';
  bool _keepScreenOn = true;
  bool _autoStart = false;
  int _autoStopMinutes = 0;
  int _speedLimitKBps = 0;
  bool _pinEnabled = false;
  String _pinHash = '';
  List<String> _bookmarkedFolders = [];
  int _accentColorIndex = 0;
  List<ServerProfile> _profiles = [];
  String _activeProfileId = '';
  ThemeMode _themeMode = ThemeMode.system;

  bool get isInitialized => _isInitialized;
  int get port => _port;
  String get rootFolder => _rootFolder;
  bool get anonymousAccess => _anonymousAccess;
  String get username => _username;
  String get password => _password;
  bool get keepScreenOn => _keepScreenOn;
  bool get autoStart => _autoStart;
  int get autoStopMinutes => _autoStopMinutes;
  int get speedLimitKBps => _speedLimitKBps;
  bool get pinEnabled => _pinEnabled;
  String get pinHash => _pinHash;
  List<String> get bookmarkedFolders => List.unmodifiable(_bookmarkedFolders);
  int get accentColorIndex => _accentColorIndex;
  List<ServerProfile> get profiles => List.unmodifiable(_profiles);
  ServerProfile get activeProfile {
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (_) {
      if (_profiles.isEmpty) {
        final defaultProfile = ServerProfile(id: 'default');
        _profiles.add(defaultProfile);
        _activeProfileId = 'default';
        _saveProfiles();
      }
      return _profiles.first;
    }
  }
  String get activeProfileId => _activeProfileId;
  ThemeMode get themeMode => _themeMode;

  SettingsProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _port = _prefs.getInt('port') ?? 2121;
    
    String savedRoot = _prefs.getString('rootFolder') ?? _defaultRootFolder;
    // Sanitize: if the stored path is the Android default but we are on Desktop, overwrite it
    if ((Platform.isWindows || Platform.isLinux || Platform.isMacOS) && savedRoot == '/storage/emulated/0') {
      savedRoot = _defaultRootFolder;
      await _prefs.setString('rootFolder', savedRoot);
    }
    _rootFolder = savedRoot;
    _anonymousAccess = _prefs.getBool('anonymousAccess') ?? false;
    _username = _prefs.getString('username') ?? 'admin';
    _password = _prefs.getString('password') ?? 'password';
    _keepScreenOn = _prefs.getBool('keepScreenOn') ?? true;
    _autoStart = _prefs.getBool('autoStart') ?? false;
    _autoStopMinutes = _prefs.getInt('autoStopMinutes') ?? 0;
    _speedLimitKBps = _prefs.getInt('speedLimitKBps') ?? 0;
    _bookmarkedFolders = _prefs.getStringList('bookmarkedFolders') ?? [];
    _pinEnabled = _prefs.getBool('pinEnabled') ?? false;
    _pinHash = _prefs.getString('pinHash') ?? '';
    _accentColorIndex = _prefs.getInt('accentColorIndex') ?? 0;
    _activeProfileId = _prefs.getString('activeProfileId') ?? 'default';
    _loadProfiles();
    _themeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _syncActiveProfile() async {
    final profile = _profiles.isNotEmpty ? _profiles.firstWhere((p) => p.id == _activeProfileId, orElse: () => _profiles.first) : null;
    if (profile != null) {
      profile.port = _port;
      profile.username = _username;
      profile.password = _password;
      profile.anonymousAccess = _anonymousAccess;
      profile.rootFolder = _rootFolder;
      await _saveProfiles();
    }
  }

  Future<void> setPort(int value) async {
    _port = value;
    await _prefs.setInt('port', value);
    await _syncActiveProfile();
    notifyListeners();
  }

  Future<void> setRootFolder(String value) async {
    _rootFolder = value;
    await _prefs.setString('rootFolder', value);
    await _syncActiveProfile();
    notifyListeners();
  }

  Future<void> setAnonymousAccess(bool value) async {
    _anonymousAccess = value;
    await _prefs.setBool('anonymousAccess', value);
    await _syncActiveProfile();
    notifyListeners();
  }

  Future<void> setUsername(String value) async {
    _username = value;
    await _prefs.setString('username', value);
    await _syncActiveProfile();
    notifyListeners();
  }

  Future<void> setPassword(String value) async {
    _password = value;
    await _prefs.setString('password', value);
    await _syncActiveProfile();
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    await _prefs.setBool('keepScreenOn', value);
    notifyListeners();
  }

  bool isBookmarked(String path) => _bookmarkedFolders.contains(path);

  Future<void> toggleBookmark(String path) async {
    if (_bookmarkedFolders.contains(path)) {
      _bookmarkedFolders.remove(path);
    } else {
      _bookmarkedFolders.add(path);
    }
    await _prefs.setStringList('bookmarkedFolders', _bookmarkedFolders);
    notifyListeners();
  }

  Future<void> removeBookmark(String path) async {
    _bookmarkedFolders.remove(path);
    await _prefs.setStringList('bookmarkedFolders', _bookmarkedFolders);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    _pinHash = pin;
    _pinEnabled = pin.isNotEmpty;
    await _prefs.setString('pinHash', pin);
    await _prefs.setBool('pinEnabled', pin.isNotEmpty);
    notifyListeners();
  }

  Future<void> setPinEnabled(bool value) async {
    _pinEnabled = value;
    await _prefs.setBool('pinEnabled', value);
    if (!value) {
      _pinHash = '';
      await _prefs.setString('pinHash', '');
    }
    notifyListeners();
  }

  bool verifyPin(String pin) => _pinHash == pin;

  Future<void> setSpeedLimitKBps(int kbPerSec) async {
    _speedLimitKBps = kbPerSec;
    await _prefs.setInt('speedLimitKBps', kbPerSec);
    notifyListeners();
  }

  Future<void> setAutoStopMinutes(int minutes) async {
    _autoStopMinutes = minutes;
    await _prefs.setInt('autoStopMinutes', minutes);
    notifyListeners();
  }

  Future<void> setAutoStart(bool value) async {
    _autoStart = value;
    await _prefs.setBool('autoStart', value);
    notifyListeners();
  }

  void _loadProfiles() {
    final raw = _prefs.getString('serverProfiles');
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      _profiles = list.map((e) => ServerProfile.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _profiles = [ServerProfile(id: 'default')];
      _activeProfileId = 'default';
      _saveProfiles();
    }
  }

  Future<void> _saveProfiles() async {
    final raw = jsonEncode(_profiles.map((p) => p.toJson()).toList());
    await _prefs.setString('serverProfiles', raw);
  }

  Future<void> addProfile(ServerProfile profile) async {
    _profiles.add(profile);
    _activeProfileId = profile.id;
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    if (_profiles.length <= 1) return;
    _profiles.removeWhere((p) => p.id == id);
    if (_activeProfileId == id) {
      _activeProfileId = _profiles.first.id;
    }
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> setActiveProfile(String id) async {
    _activeProfileId = id;
    await _prefs.setString('activeProfileId', id);
    final profile = _profiles.firstWhere((p) => p.id == id);
    _port = profile.port;
    _rootFolder = profile.rootFolder;
    _anonymousAccess = profile.anonymousAccess;
    _username = profile.username;
    _password = profile.password;
    notifyListeners();
  }

  Future<void> updateProfile(ServerProfile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      _profiles[idx] = profile;
      await _saveProfiles();
      notifyListeners();
    }
  }

  Future<void> setAccentColorIndex(int index) async {
    _accentColorIndex = index;
    await _prefs.setInt('accentColorIndex', index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    await _prefs.setInt('themeMode', value.index);
    notifyListeners();
  }
}
