import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:quick_wifi_share/services/background_service.dart';

class FtpProvider with ChangeNotifier {
  bool _isRunning = false;
  bool _isStarting = false;
  String _ipAddress = '0.0.0.0';
  int _webPort = 8080;
  int _totalBytesTransferred = 0;
  int _autoStopMinutes = 0;
  Timer? _autoStopTimer;
  final List<String> _logs = [];
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  bool get isRunning => _isRunning;
  bool get isStarting => _isStarting;
  String get ipAddress => _ipAddress;
  int get webPort => _webPort;
  int get totalBytesTransferred => _totalBytesTransferred;
  int get autoStopMinutes => _autoStopMinutes;
  List<String> get logs => List.unmodifiable(_logs);

  FtpProvider() {
    _initNetworkInfo();
    _listenToServiceUpdates();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final isRunning = await BackgroundServiceManager.isServiceRunning();
    if (isRunning) {
      BackgroundServiceManager.invoke('getStatus');
    }
  }

  void _listenToServiceUpdates() {
    _serviceSubscription = BackgroundServiceManager.onDataReceived.listen((event) {
      if (event == null) return;

      debugPrint('FtpProvider event: $event');

      if (event.containsKey('message')) {
        final log = event['message'] as String;
        _logs.insert(0, log);
        if (_logs.length > 20) _logs.removeLast();

        if (log.contains('bytes transferred')) {
          final match = RegExp(r'(\d+)\s+bytes').firstMatch(log);
          if (match != null) {
            _totalBytesTransferred += int.parse(match.group(1)!);
          }
        }
        notifyListeners();
      }

      if (event.containsKey('running')) {
        final newState = event['running'] as bool;
        if (_isRunning != newState) {
          _isRunning = newState;
          _isStarting = false;
          
          if (_isRunning && event.containsKey('ip')) {
            _ipAddress = event['ip'] as String;
            _startAutoStopTimer();
          } else if (!_isRunning) {
            _totalBytesTransferred = 0;
            _logs.clear();
            _cancelAutoStopTimer();
          }
          
          debugPrint('FtpProvider: isRunning changed to $_isRunning');
          notifyListeners();
        }
      }

      if (event.containsKey('ip') && event['ip'] != null) {
        _ipAddress = event['ip'] as String;
        debugPrint('FtpProvider: ip changed to $_ipAddress');
        notifyListeners();
      }

      if (event.containsKey('webPort') && event['webPort'] != null) {
        _webPort = event['webPort'] as int;
        debugPrint('FtpProvider: webPort changed to $_webPort');
        notifyListeners();
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
    if (_isRunning) return true;
    if (_isStarting) return true;

    _isStarting = true;
    _logs.clear();
    notifyListeners();

    try {
      debugPrint('FtpProvider: Starting FTP server...');
      final success = await BackgroundServiceManager.startService(
        port: port,
        rootPath: rootPath,
        anonymous: anonymous,
        username: username,
        password: password,
      );

      if (!success) {
        _isStarting = false;
        notifyListeners();
        return false;
      }

      // Wait for service to respond
      await Future.delayed(const Duration(seconds: 2));
      
      // If still starting after 2 seconds, the service will update us
      if (_isStarting) {
        debugPrint('FtpProvider: Waiting for service confirmation...');
      }

      return true;
    } catch (e) {
      debugPrint('Error starting FTP server: $e');
      _isStarting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopServer() async {
    if (!_isRunning && !_isStarting) return;

    debugPrint('FtpProvider: Stopping FTP server');
    _isStarting = false;
    notifyListeners();

    await BackgroundServiceManager.stopService();
  }

  void setAutoStopMinutes(int minutes) {
    _autoStopMinutes = minutes;
    if (_isRunning) {
      _cancelAutoStopTimer();
      _startAutoStopTimer();
    }
    notifyListeners();
  }

  void _startAutoStopTimer() {
    _cancelAutoStopTimer();
    if (_autoStopMinutes <= 0) return;
    _autoStopTimer = Timer(Duration(minutes: _autoStopMinutes), () {
      if (_isRunning) {
        _logs.insert(0, 'Auto-stop: Server stopped after $_autoStopMinutes minutes');
        stopServer();
        notifyListeners();
      }
    });
  }

  void _cancelAutoStopTimer() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    _cancelAutoStopTimer();
    super.dispose();
  }
}