import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftp_server/ftp_server.dart';
import 'package:ftp_server/server_type.dart';
import 'package:ftp_server/file_operations/physical_file_operations.dart';
import 'package:network_info_plus/network_info_plus.dart';

class FtpProvider with ChangeNotifier {
  FtpServer? _ftpServer;
  bool _isRunning = false;
  bool _isStarting = false;
  String _ipAddress = '0.0.0.0';
  int _activeConnections = 0;
  final List<String> _logs = [];

  bool get isRunning => _isRunning;
  String get ipAddress => _ipAddress;
  int get activeConnections => _activeConnections;
  List<String> get logs => List.unmodifiable(_logs);

  FtpProvider() {
    _initNetworkInfo();
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

    try {
      await refreshNetworkInfo();
      
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) {
        rootDir.createSync(recursive: true);
      }

      _ftpServer = FtpServer(
        port,
        username: anonymous ? null : username,
        password: anonymous ? null : password,
        fileOperations: PhysicalFileOperations(rootPath),
        serverType: ServerType.readAndWrite,
        logFunction: (log) {
          debugPrint('FTP SERVER: $log');
          _logs.insert(0, log);
          if (_logs.length > 20) _logs.removeLast();
          
          if (log.contains('logged in')) {
            _activeConnections++;
            notifyListeners();
          } else if (log.contains('disconnected')) {
            if (_activeConnections > 0) _activeConnections--;
            notifyListeners();
          }
        },
      );

      await _ftpServer!.startInBackground();
      _isRunning = true;
      _isStarting = false;
      notifyListeners();
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
      await _ftpServer?.stop();
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
    _ftpServer?.stop();
    super.dispose();
  }
}
