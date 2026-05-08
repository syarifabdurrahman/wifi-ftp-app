import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ftp_server/ftp_server.dart';
import 'package:ftp_server/server_type.dart';
import 'package:ftp_server/file_operations/physical_file_operations.dart';
import 'package:network_info_plus/network_info_plus.dart';

const notificationChannelId = 'ftp_foreground_service';
const notificationId = 888;

class BackgroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_bg_service_small');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'FTP Server Service',
      description: 'FTP Server is running in the background',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'FTP Server',
        initialNotificationContent: 'Starting...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> startService({
    required int port,
    required String rootPath,
    required bool anonymous,
    required String username,
    required String password,
  }) async {
    _service.invoke('startServer', {
      'port': port,
      'rootPath': rootPath,
      'anonymous': anonymous,
      'username': username,
      'password': password,
    });
  }

  static Future<void> stopService() async {
    _service.invoke('stopServer');
  }

  static Stream<Map<String, dynamic>?> get onDataReceived {
    return _service.on('update');
  }

  static Future<bool> isRunning() async {
    final result = await _service.isRunning();
    return result;
  }

  static void stopBackgroundService() {
    _service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FtpServer? ftpServer;
  Timer? updateTimer;
  bool serverStarted = false;

  service.on('startServer').listen((event) async {
    if (serverStarted) return;

    final port = event?['port'] as int? ?? 2121;
    final rootPath = event?['rootPath'] as String? ?? '/storage/emulated/0';
    final anonymous = event?['anonymous'] as bool? ?? false;
    final username = event?['username'] as String? ?? '';
    final password = event?['password'] as String? ?? '';

    try {
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) {
        rootDir.createSync(recursive: true);
      }

      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP() ?? '0.0.0.0';

      ftpServer = FtpServer(
        port,
        username: anonymous ? null : username,
        password: anonymous ? null : password,
        fileOperations: PhysicalFileOperations(rootPath),
        serverType: ServerType.readAndWrite,
        logFunction: (log) {
          debugPrint('FTP SERVER: $log');
          service.invoke('log', {'message': log});
        },
      );

      await ftpServer!.startInBackground();

      serverStarted = true;

      updateTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            final currentIP = await NetworkInfo().getWifiIP() ?? wifiIP;
            flutterLocalNotificationsPlugin.show(
              notificationId,
              'FTP Server Active',
              'ftp://$currentIP:$port',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelId,
                  'FTP Server Service',
                  icon: 'ic_bg_service_small',
                  ongoing: true,
                ),
              ),
            );
          }
        }
      });

      service.invoke('serverStatus', {
        'running': true,
        'ip': wifiIP,
        'port': port,
      });
    } catch (e) {
      debugPrint('Error starting FTP server in background: $e');
      service.invoke('serverStatus', {
        'running': false,
        'error': e.toString(),
      });
    }
  });

  service.on('stopServer').listen((_) async {
    updateTimer?.cancel();
    await ftpServer?.stop();
    serverStarted = false;

    service.invoke('serverStatus', {
      'running': false,
    });
  });

  service.on('stopService').listen((_) async {
    updateTimer?.cancel();
    await ftpServer?.stop();
    await service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}