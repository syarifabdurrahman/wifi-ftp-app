import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/helpers/ad_helper.dart';
import 'package:quick_wifi_share/providers/file_provider.dart';
import 'package:quick_wifi_share/providers/ftp_provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';
import 'package:quick_wifi_share/screens/main_navigation_screen.dart';
import 'package:quick_wifi_share/screens/pin_lock_screen.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    if (settingsProvider.pinEnabled && !_unlocked && settingsProvider.isInitialized) {
      final accentIdx = settingsProvider.accentColorIndex;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PinLockScreen(onUnlocked: () => setState(() => _unlocked = true)),
        theme: AppTheme.lightTheme(accentIdx),
        darkTheme: AppTheme.darkTheme(accentIdx),
        themeMode: settingsProvider.themeMode,
      );
    }

    final accentIdx = settingsProvider.accentColorIndex;
    return MaterialApp(
      title: 'WiFi FTP App',
      theme: AppTheme.lightTheme(accentIdx),
      darkTheme: AppTheme.darkTheme(accentIdx),
      themeMode: settingsProvider.themeMode,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

