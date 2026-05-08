import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_ftp_app/providers/settings_provider.dart';
import 'package:wifi_ftp_app/theme/app_theme.dart';

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
                            color: AppTheme.primaryContainer.withValues(alpha: 0.1),
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
                  child: _buildSettingItem(
                    icon: Icons.light_mode,
                    title: 'Keep Screen On',
                    subtitle: 'Prevent sleep while server is active',
                    trailing: Switch(
                      value: settingsProvider.keepScreenOn,
                      onChanged: (val) => settingsProvider.setKeepScreenOn(val),
                    ),
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
