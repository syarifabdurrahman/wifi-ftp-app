import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/helpers/ad_helper.dart';
import 'package:quick_wifi_share/providers/file_provider.dart';
import 'package:quick_wifi_share/providers/ftp_provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';
import 'package:quick_wifi_share/screens/main_navigation_screen.dart';
import 'package:quick_wifi_share/services/background_service.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';

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
    final settingsProvider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'WiFi FTP App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

