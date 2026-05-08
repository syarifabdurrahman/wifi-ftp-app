import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_ftp_app/helpers/ad_helper.dart';
import 'package:wifi_ftp_app/providers/file_provider.dart';
import 'package:wifi_ftp_app/providers/ftp_provider.dart';
import 'package:wifi_ftp_app/providers/settings_provider.dart';
import 'package:wifi_ftp_app/screens/main_navigation_screen.dart';
import 'package:wifi_ftp_app/services/background_service.dart';
import 'package:wifi_ftp_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AdHelper.initialize();
  await BackgroundServiceManager.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FtpProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi FTP App',
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

