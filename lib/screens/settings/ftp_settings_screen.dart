import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/models/server_profile.dart';
import 'package:quick_wifi_share/providers/ftp_provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';
import 'package:quick_wifi_share/screens/pin_lock_screen.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';

class FtpSettingsScreen extends StatefulWidget {
  const FtpSettingsScreen({super.key});

  @override
  State<FtpSettingsScreen> createState() => _FtpSettingsScreenState();
}

class _FtpSettingsScreenState extends State<FtpSettingsScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (!settingsProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('FTP Server'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Title
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure your server behavior and security.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Server Profiles
                _buildSectionHeader('SERVER PROFILES'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      final active = settings.activeProfile;
                      return Column(
                        children: [
                          _buildSettingItem(
                            icon: Icons.account_tree_rounded,
                            title: 'Active Profile',
                            subtitle: active.name,
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.swap_horiz_rounded, color: Theme.of(context).colorScheme.secondary),
                              onSelected: (id) => settings.setActiveProfile(id),
                              itemBuilder: (_) => settings.profiles.map((p) {
                                final isActive = p.id == settings.activeProfileId;
                                return PopupMenuItem(
                                  value: p.id,
                                  child: Row(
                                    children: [
                                      Icon(isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                                        size: 18, color: isActive ? Theme.of(context).colorScheme.primary : null),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                                            Text('Port: ${p.port}', style: Theme.of(context).textTheme.labelSmall),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.outlineVariant),
                          _buildSettingItem(
                            icon: Icons.add_circle_outline,
                            title: 'New Profile',
                            subtitle: 'Create a new server configuration',
                            trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            onTap: () => _showProfileDialog(context, settingsProvider, null),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Network Configuration Group
                _buildSectionHeader('NETWORK CONFIGURATION'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.settings_ethernet,
                        title: 'Port Number',
                        subtitle: 'The port the FTP server listens on',
                        onTap: () => _showPortDialog(context, settingsProvider),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005EB8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${settingsProvider.port}',
                            style: AppTheme.codeSmall.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.outlineVariant),
                      _buildSettingItem(
                        icon: Icons.folder_open,
                        title: 'Root Folder',
                        subtitle: settingsProvider.rootFolder,
                        trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Security & Access Group
                _buildSectionHeader('SECURITY & ACCESS'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.person_off,
                        title: 'Anonymous Access',
                        subtitle: 'Allow logins without credentials',
                        trailing: Switch(
                          value: settingsProvider.anonymousAccess,
                          onChanged: (val) => settingsProvider.setAnonymousAccess(val),
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.outlineVariant),
                      _buildTextFieldItem(
                        label: 'FTP Username',
                        icon: Icons.person,
                        initialValue: settingsProvider.username,
                        onChanged: (val) => settingsProvider.setUsername(val),
                      ),
                      const Divider(height: 1, color: AppTheme.outlineVariant),
                      _buildTextFieldItem(
                        label: 'FTP Password',
                        icon: Icons.lock,
                        initialValue: settingsProvider.password,
                        isPassword: true,
                        onChanged: (val) => settingsProvider.setPassword(val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Appearance Group
                _buildSectionHeader('APPEARANCE'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.brightness_6,
                        title: 'Theme Mode',
                        subtitle: _getThemeModeName(settingsProvider.themeMode),
                        trailing: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.settings_brightness, size: 18),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined, size: 18),
                            ),
                          ],
                          selected: {settingsProvider.themeMode},
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            settingsProvider.setThemeMode(newSelection.first);
                          },
                          style: SegmentedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            selectedBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            selectedForegroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide.none,
                          ),
                          showSelectedIcon: false,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.outlineVariant),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.palette_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                                const SizedBox(width: 12),
                                Text(
                                  'Accent Color',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(AppTheme.accentColors.length, (i) {
                                final color = AppTheme.accentColors[i];
                                final isSelected = settingsProvider.accentColorIndex == i;
                                return GestureDetector(
                                  onTap: () => settingsProvider.setAccentColorIndex(i),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                          : null,
                                      boxShadow: isSelected
                                          ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? Icon(Icons.check, size: 18, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Advanced Group
                _buildSectionHeader('ADVANCED'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.power_settings_new,
                        title: 'Auto-Start Server',
                        subtitle: 'Automatically start server on app launch',
                        trailing: Switch(
                          value: settingsProvider.autoStart,
                          onChanged: (val) => settingsProvider.setAutoStart(val),
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.outlineVariant),
                      _buildSettingItem(
                        icon: Icons.timer_outlined,
                        title: 'Auto-Stop Timer',
                        subtitle: settingsProvider.autoStopMinutes > 0
                            ? 'Stop server after ${settingsProvider.autoStopMinutes} minutes'
                            : 'Server runs until manually stopped',
                        trailing: PopupMenuButton<int>(
                          icon: Icon(Icons.timer, color: Theme.of(context).colorScheme.secondary),
                          onSelected: (val) {
                            settingsProvider.setAutoStopMinutes(val);
                            context.read<FtpProvider>().setAutoStopMinutes(val);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 0, child: Text('Off (manual stop)')),
                            const PopupMenuItem(value: 15, child: Text('15 minutes')),
                            const PopupMenuItem(value: 30, child: Text('30 minutes')),
                            const PopupMenuItem(value: 60, child: Text('1 hour')),
                            const PopupMenuItem(value: 120, child: Text('2 hours')),
                            const PopupMenuItem(value: 480, child: Text('8 hours')),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.outlineVariant),
                      _buildSettingItem(
                        icon: Icons.speed,
                        title: 'Speed Limit (Web)',
                        subtitle: settingsProvider.speedLimitKBps > 0
                            ? '${settingsProvider.speedLimitKBps} KB/s'
                            : 'Unlimited',
                        trailing: PopupMenuButton<int>(
                          icon: Icon(Icons.speed, color: Theme.of(context).colorScheme.secondary),
                          onSelected: (val) => settingsProvider.setSpeedLimitKBps(val),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 0, child: Text('Unlimited')),
                            const PopupMenuItem(value: 100, child: Text('100 KB/s')),
                            const PopupMenuItem(value: 500, child: Text('500 KB/s')),
                            const PopupMenuItem(value: 1024, child: Text('1 MB/s')),
                            const PopupMenuItem(value: 5120, child: Text('5 MB/s')),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.outlineVariant),
                      _buildSettingItem(
                        icon: Icons.light_mode,
                        title: 'Keep Screen On',
                        subtitle: 'Prevent sleep while server is active',
                        trailing: Switch(
                          value: settingsProvider.keepScreenOn,
                          onChanged: (val) => settingsProvider.setKeepScreenOn(val),
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.outlineVariant),
                      _buildSettingItem(
                        icon: Icons.lock_outline,
                        title: 'App Lock (PIN)',
                        subtitle: settingsProvider.pinEnabled ? 'PIN enabled' : 'Protect app with a PIN',
                        trailing: Switch(
                          value: settingsProvider.pinEnabled,
                          onChanged: (val) {
                            if (val) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: settingsProvider,
                                  child: const PinLockScreen(isSetup: true),
                                ),
                              ));
                            } else {
                              settingsProvider.setPinEnabled(false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Changes to Port and Security settings will require a server restart to take effect.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _showPortDialog(BuildContext context, SettingsProvider settingsProvider) async {
    final controller = TextEditingController(text: settingsProvider.port.toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Port'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Port Number',
            hintText: 'e.g. 2121',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port > 0 && port < 65536) {
                settingsProvider.setPort(port);
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, SettingsProvider settingsProvider, ServerProfile? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final portCtrl = TextEditingController(text: (existing?.port ?? 2121).toString());
    final userCtrl = TextEditingController(text: existing?.username ?? 'admin');
    final passCtrl = TextEditingController(text: existing?.password ?? 'password');
    final anonymous = ValueNotifier(existing?.anonymousAccess ?? false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing != null ? 'Edit Profile' : 'New Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Profile Name', hintText: 'e.g. Home, Office'),),
              const SizedBox(height: 12),
              TextField(controller: portCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Port'),),
              const SizedBox(height: 12),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username'),),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password'),),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Anonymous Access'),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: anonymous,
                    builder: (_, val, _) => Switch(value: val, onChanged: (v) => anonymous.value = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final profile = ServerProfile(
                id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim().isEmpty ? 'Unnamed' : nameCtrl.text.trim(),
                port: int.tryParse(portCtrl.text) ?? 2121,
                username: userCtrl.text.trim(),
                password: passCtrl.text.trim(),
                anonymousAccess: anonymous.value,
              );
              if (existing != null) {
                settingsProvider.updateProfile(profile);
              } else {
                settingsProvider.addProfile(profile);
              }
              Navigator.pop(ctx);
            },
            child: Text(existing != null ? 'UPDATE' : 'CREATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldItem({
    required String label,
    required IconData icon,
    required String initialValue,
    bool isPassword = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            obscureText: isPassword && _obscurePassword,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.outline),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.getSurfaceColor(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
