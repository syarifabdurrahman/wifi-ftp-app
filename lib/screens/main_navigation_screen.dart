import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:wifi_ftp_app/screens/connection/connection_screen.dart';
import 'package:wifi_ftp_app/screens/files/file_manager_screen.dart';
import 'package:wifi_ftp_app/screens/history/transfer_history_screen.dart';
import 'package:wifi_ftp_app/screens/settings/ftp_settings_screen.dart';
import 'package:wifi_ftp_app/theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ConnectionScreen(),
    const FileManagerScreen(),
    const TransferHistoryScreen(),
    const FtpSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primaryContainer.withOpacity(0.3),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.settings_remote_outlined),
            selectedIcon: Icon(Icons.settings_remote, color: AppTheme.primary),
            label: 'Connection',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: AppTheme.primary),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: AppTheme.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
