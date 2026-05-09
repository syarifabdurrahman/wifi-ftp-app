import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:quick_wifi_share/screens/connection/connection_screen.dart';
import 'package:quick_wifi_share/screens/files/file_manager_screen.dart';
import 'package:quick_wifi_share/screens/history/transfer_history_screen.dart';
import 'package:quick_wifi_share/screens/settings/ftp_settings_screen.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.settings_remote_outlined),
            selectedIcon: Icon(Icons.settings_remote, color: Theme.of(context).colorScheme.primary),
            label: 'Connection',
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
            label: 'Files',
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
