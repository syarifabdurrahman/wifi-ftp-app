import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ftp_server/ftp_server.dart';
import 'package:ftp_server/server_type.dart';
import 'package:ftp_server/file_operations/physical_file_operations.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:quick_wifi_share/services/web_server_service.dart';

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

  // Desktop Server Instances
  static FtpServer? _desktopFtpServer;
  static WebServerService? _desktopWebServer;
  static bool _desktopIsRunning = false;
  static int _desktopPort = 2121;
  static final StreamController<Map<String, dynamic>?> _desktopStreamController =
      StreamController<Map<String, dynamic>?>.broadcast();

  static Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Desktop doesn't support or need flutter_background_service/foreground notification init
      return;
    }

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
    
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        if (_desktopIsRunning) {
          await stopService();
        }

        final rootDir = Directory(rootPath);
        if (!rootDir.existsSync()) {
          rootDir.createSync(recursive: true);
        }

        final networkInfo = NetworkInfo();
        final currentIP = await networkInfo.getWifiIP() ?? '127.0.0.1';
        _desktopPort = port;

        _desktopFtpServer = FtpServer(
          port,
          username: anonymous ? null : username,
          password: anonymous ? null : password,
          fileOperations: PhysicalFileOperations(rootPath),
          serverType: ServerType.readAndWrite,
          logFunction: (log) {
            debugPrint('FTP Desktop: $log');
            _desktopStreamController.add({'message': log});
          },
        );

        await _desktopFtpServer!.startInBackground();

        _desktopWebServer = WebServerService(
          rootPath: rootPath,
          port: 8080,
          logFunction: (log) {
            debugPrint('WEB Desktop: $log');
            _desktopStreamController.add({'message': log});
          },
        );
        await _desktopWebServer!.start();

        _desktopIsRunning = true;
        
        _desktopStreamController.add({
          'running': true,
          'ip': currentIP,
          'port': port,
          'webPort': 8080,
          'message': 'Desktop Server started!\nFTP: ftp://$currentIP:$port\nWeb: http://$currentIP:8080',
        });
        
        return true;
      } catch (e) {
        debugPrint('Desktop server start error: $e');
        _desktopStreamController.add({
          'running': false,
          'error': e.toString(),
        });
        return false;
      }
    }

    try {
      final isRunning = await _service.isRunning();
      
      if (!isRunning) {
        _service.startService();
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      _service.invoke('startServer', {
        'port': port,
        'rootPath': rootPath,
        'anonymous': anonymous,
        'username': username,
        'password': password,
      });
      
      return true;
    } catch (e) {
      debugPrint('BackgroundServiceManager: Error: $e');
      return false;
    }
  }

  static Future<void> stopService() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        if (_desktopFtpServer != null) {
          await _desktopFtpServer!.stop().timeout(const Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint('Desktop FTP stop error: $e');
      } finally {
        _desktopFtpServer = null;
      }
      
      try {
        if (_desktopWebServer != null) {
          await _desktopWebServer!.stop().timeout(const Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint('Desktop Web stop error: $e');
      } finally {
        _desktopWebServer = null;
      }
      _desktopIsRunning = false;
      _desktopStreamController.add({
        'running': false,
        'message': 'FTP and Web Servers stopped',
      });
      return;
    }

    try {
      _service.invoke('stopServer');
    } catch (e) {
      debugPrint('BackgroundServiceManager: Stop error: $e');
    }
  }

  static void invoke(String method, [Map<String, dynamic>? args]) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (method == 'getStatus') {
        final networkInfo = NetworkInfo();
        networkInfo.getWifiIP().then((ip) {
          _desktopStreamController.add({
            'running': _desktopIsRunning,
            'ip': ip ?? '127.0.0.1',
            'port': _desktopPort,
            'webPort': 8080,
          });
        });
      }
      return;
    }
    _service.invoke(method, args);
  }

  static Stream<Map<String, dynamic>?> get onDataReceived {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _desktopStreamController.stream;
    }
    return _service.on('update');
  }

  static Future<bool> isServiceRunning() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _desktopIsRunning;
    }
    return await _service.isRunning();
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  debugPrint('Background service _onStart called');

  FtpServer? ftpServer;
  WebServerService? webServer;
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
    if (webServer != null) {
      await webServer!.stop();
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

      // Start the Web Server
      webServer = WebServerService(
        rootPath: rootPath,
        port: 8080,
        logFunction: (log) {
          debugPrint('WEB: $log');
          service.invoke('update', {'message': log});
        },
      );
      await webServer!.start();
      debugPrint('Web Server started successfully!');

      await notifications.show(
        notificationId,
        'WiFi Share Active',
        'ftp://$currentIP:$currentPort | Web: http://$currentIP:8080',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'WiFi FTP & Web Server Service',
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
        'webPort': 8080,
        'message': 'Server started!\nFTP: ftp://$currentIP:$currentPort\nWeb: http://$currentIP:8080',
      });

    } catch (e, stack) {
      debugPrint('Error starting FTP or Web server: $e');
      debugPrint('Stack: $stack');
      if (webServer != null) {
        try {
          await webServer!.stop();
        } catch (_) {}
        webServer = null;
      }
      await notifications.cancel(notificationId);
      service.invoke('update', {
        'running': false,
        'error': e.toString(),
      });
    }
  });

  service.on('stopServer').listen((_) async {
    debugPrint('Received stopServer event');
    
    try {
      if (ftpServer != null) {
        debugPrint('Stopping FTP Server...');
        await ftpServer!.stop().timeout(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('Error stopping FTP server (ignored): $e');
    } finally {
      ftpServer = null;
    }

    try {
      if (webServer != null) {
        debugPrint('Stopping Web Server...');
        await webServer!.stop().timeout(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('Error stopping Web server (ignored): $e');
    } finally {
      webServer = null;
    }

    try {
      await notifications.cancel(notificationId);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }

    service.invoke('update', {
      'running': false,
      'message': 'FTP and Web Servers stopped',
    });
    
    // Give some time for the message to be sent before stopping
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (service is AndroidServiceInstance) {
      debugPrint('Stopping Android Foreground Service...');
      service.stopSelf();
    }
  });

  service.on('getStatus').listen((_) {
    service.invoke('update', {
      'running': ftpServer != null,
      'ip': currentIP,
      'port': currentPort,
      'webPort': 8080,
    });
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}