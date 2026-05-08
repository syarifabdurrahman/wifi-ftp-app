import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_ftp_app/services/background_service.dart';

class FtpProvider with ChangeNotifier {
  bool _isRunning = false;
  bool _isStarting = false;
  String _ipAddress = '0.0.0.0';
  int _activeConnections = 0;
  final List<String> _logs = [];
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  bool get isRunning => _isRunning;
  String get ipAddress => _ipAddress;
  int get activeConnections => _activeConnections;
  List<String> get logs => List.unmodifiable(_logs);

  FtpProvider() {
    _initNetworkInfo();
    _listenToServiceUpdates();
  }

  void _listenToServiceUpdates() {
    _serviceSubscription = BackgroundServiceManager.onDataReceived.listen((event) {
      if (event != null) {
        if (event.containsKey('message')) {
          final log = event['message'] as String;
          _logs.insert(0, log);
          if (_logs.length > 20) _logs.removeLast();

          if (log.contains('logged in')) {
            _activeConnections++;
          } else if (log.contains('disconnected')) {
            if (_activeConnections > 0) _activeConnections--;
          }
          notifyListeners();
        }
        if (event.containsKey('running')) {
          _isRunning = event['running'] as bool;
          if (!_isRunning) {
            _activeConnections = 0;
            _logs.clear();
          }
          notifyListeners();
        }
        if (event.containsKey('ip')) {
          _ipAddress = event['ip'] as String;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _initNetworkInfo() async {
    final info = NetworkInfo();
    final wifiIP = await info.getWifiIP();
    if (wifiIP != null) {
      _ipAddress = wifiIP;
      notifyListeners();
    }
  }

  Future<void> refreshNetworkInfo() async {
    await _initNetworkInfo();
  }

  Future<bool> startServer({
    required int port,
    required String rootPath,
    required bool anonymous,
    required String username,
    required String password,
  }) async {
    if (_isRunning || _isStarting) return true;
    
    _isStarting = true;
    notifyListeners();

    try {
      _isStarting = false;
      _isRunning = true;
      notifyListeners();

      await BackgroundServiceManager.startService(
        port: port,
        rootPath: rootPath,
        anonymous: anonymous,
        username: username,
        password: password,
      );

      return true;
    } catch (e) {
      debugPrint('Error starting FTP server: $e');
      _isRunning = false;
      _isStarting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopServer() async {
    if (!_isRunning) return;

    try {
      await BackgroundServiceManager.stopService();
      _isRunning = false;
      _activeConnections = 0;
      _logs.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping FTP server: $e');
    }
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }
}
