import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ftp_server/ftp_server.dart';
import 'package:ftp_server/server_type.dart';
import 'package:ftp_server/file_operations/physical_file_operations.dart';
import 'package:network_info_plus/network_info_plus.dart';

const notificationChannelId = 'ftp_foreground_service';
const notificationId = 888;

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Notification action received: ${notificationResponse.actionId}');
  if (notificationResponse.actionId == 'stop_action') {
    debugPrint('Invoking stopServer from notification action');
    FlutterBackgroundService().invoke('stopServer');
  }
}

class BackgroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static FtpServer? _ftpServer;
  static bool _isServerStarted = false;
  static bool _serviceStarted = false;
  static String _currentIP = '0.0.0.0';
  static int _currentPort = 2121;

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_bg_service_small');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'FTP Server Service',
      description: 'FTP Server is running in the background',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'FTP Server',
        initialNotificationContent: 'Starting FTP server...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<bool> startService({
    required int port,
    required String rootPath,
    required bool anonymous,
    required String username,
    required String password,
  }) async {
    debugPrint('BackgroundServiceManager: Starting service...');
    
    try {
      // Start the background service first
      final isRunning = await _service.isRunning();
      debugPrint('BackgroundServiceManager: Service running: $isRunning');
      
      if (!isRunning) {
        debugPrint('BackgroundServiceManager: Starting background service...');
        _service.startService();
        await Future.delayed(const Duration(milliseconds: 1000));
        debugPrint('BackgroundServiceManager: Service started');
      }
      
      _serviceStarted = true;

      // Now invoke startServer
      debugPrint('BackgroundServiceManager: Invoking startServer event');
      _service.invoke('startServer', {
        'port': port,
        'rootPath': rootPath,
        'anonymous': anonymous,
        'username': username,
        'password': password,
      });
      
      return true;
    } catch (e, stack) {
      debugPrint('BackgroundServiceManager: Error: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  static Future<void> stopService() async {
    debugPrint('BackgroundServiceManager: Stopping service...');
    try {
      _service.invoke('stopServer');
      _isServerStarted = false;
    } catch (e) {
      debugPrint('BackgroundServiceManager: Stop error: $e');
    }
  }

  static void invoke(String method, [Map<String, dynamic>? args]) {
    _service.invoke(method, args);
  }

  static Stream<Map<String, dynamic>?> get onDataReceived {
    return _service.on('update');
  }

  static Future<bool> isServiceRunning() async {
    final result = await _service.isRunning();
    return result ?? false;
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  debugPrint('Background service _onStart called');

  FtpServer? ftpServer;
  String currentIP = '0.0.0.0';
  int currentPort = 2121;

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    debugPrint('Set as foreground service');
  }

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  service.on('startServer').listen((event) async {
    debugPrint('Received startServer event: $event');

    if (ftpServer != null) {
      await ftpServer!.stop();
    }

    final port = event?['port'] as int? ?? 2121;
    final rootPath = event?['rootPath'] as String? ?? '/storage/emulated/0';
    final anonymous = event?['anonymous'] as bool? ?? false;
    final username = event?['username'] as String? ?? '';
    final password = event?['password'] as String? ?? '';

    debugPrint('Starting FTP server on port $port');
    debugPrint('Root path: $rootPath');
    debugPrint('Anonymous: $anonymous');

    try {
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) {
        debugPrint('Creating root directory: $rootPath');
        rootDir.createSync(recursive: true);
      }

      final networkInfo = NetworkInfo();
      currentIP = await networkInfo.getWifiIP() ?? '0.0.0.0';
      currentPort = port;
      debugPrint('WiFi IP: $currentIP');

      ftpServer = FtpServer(
        currentPort,
        username: anonymous ? null : username,
        password: anonymous ? null : password,
        fileOperations: PhysicalFileOperations(rootPath),
        serverType: ServerType.readAndWrite,
        logFunction: (log) {
          debugPrint('FTP: $log');
          service.invoke('update', {'message': log});
        },
      );

      debugPrint('Calling startInBackground...');
      await ftpServer!.startInBackground();
      debugPrint('FTP server started successfully!');

      await notifications.show(
        notificationId,
        'FTP Server Active',
        'ftp://$currentIP:$currentPort',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'FTP Server Service',
            icon: 'ic_bg_service_small',
            ongoing: true,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'stop_action',
                'STOP',
                cancelNotification: true,
              ),
            ],
          ),
        ),
      );

      // Send update to UI via 'update' stream
      service.invoke('update', {
        'running': true,
        'ip': currentIP,
        'port': currentPort,
        'message': 'FTP Server started at ftp://$currentIP:$currentPort',
      });

    } catch (e, stack) {
      debugPrint('Error starting FTP server: $e');
      debugPrint('Stack: $stack');
      await notifications.cancel(notificationId);
      service.invoke('update', {
        'running': false,
        'error': e.toString(),
      });
    }
  });

  service.on('stopServer').listen((_) async {
    debugPrint('Received stopServer event');
    if (ftpServer != null) {
      await ftpServer!.stop();
      ftpServer = null;
    }
    await notifications.cancel(notificationId);
    service.invoke('update', {
      'running': false,
      'message': 'FTP Server stopped',
    });
    
    // Give some time for the message to be sent before stopping
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  });

  service.on('getStatus').listen((_) {
    service.invoke('update', {
      'running': ftpServer != null,
      'ip': currentIP,
      'port': currentPort,
    });
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}