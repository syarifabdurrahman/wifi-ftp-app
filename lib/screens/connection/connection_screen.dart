import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi_ftp_app/providers/file_provider.dart';
import 'package:wifi_ftp_app/providers/ftp_provider.dart';
import 'package:wifi_ftp_app/providers/settings_provider.dart';
import 'package:wifi_ftp_app/theme/app_theme.dart';
import 'package:wifi_ftp_app/widgets/pulse_animation.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  Future<void> _toggleServer(BuildContext context, FtpProvider ftpProvider, SettingsProvider settingsProvider) async {
    if (ftpProvider.isRunning) {
      await ftpProvider.stopServer();
    } else {
      if (await Permission.manageExternalStorage.request().isGranted || await Permission.storage.request().isGranted) {
        final success = await ftpProvider.startServer(
          port: settingsProvider.port,
          rootPath: settingsProvider.rootFolder,
          anonymous: settingsProvider.anonymousAccess,
          username: settingsProvider.username,
          password: settingsProvider.password,
        );
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start FTP Server. Check port or permissions.')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permissions are required to start the FTP Server.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer2<FtpProvider, SettingsProvider>(
        builder: (context, ftpProvider, settingsProvider, child) {
          final isRunning = ftpProvider.isRunning;
          final statusColor = isRunning ? AppTheme.primary : AppTheme.outline;
          final statusText = isRunning ? 'Online' : 'Offline';

          final ftpAddress = isRunning
              ? 'ftp://${ftpProvider.ipAddress}:${settingsProvider.port}'
              : 'Server offline';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Stats Row
                Row(
                  children: [
                    _buildQuickStat(
                      context,
                      title: 'Status',
                      value: statusText,
                      color: statusColor,
                      icon: isRunning ? Icons.cloud_done : Icons.cloud_off,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      context,
                      title: 'Active Users',
                      value: '${ftpProvider.activeConnections}',
                      color: AppTheme.secondary,
                      icon: Icons.people_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Connection Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (isRunning) ...[
                        QrImageView(
                          data: ftpAddress,
                          version: QrVersions.auto,
                          size: 160.0,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppTheme.onSurface,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'FTP Access URL',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ftpAddress,
                                style: AppTheme.codeSmall.copyWith(
                                  color: isRunning ? AppTheme.primary : AppTheme.outline,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_all, size: 20),
                              onPressed: () {},
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Pulse Button
                Center(
                  child: PulseAnimation(
                    isRunning: isRunning,
                    color: statusColor,
                    child: InkWell(
                      onTap: () => _toggleServer(context, ftpProvider, settingsProvider),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isRunning 
                              ? [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]
                              : [AppTheme.outline, AppTheme.outline.withValues(alpha: 0.7)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isRunning ? Icons.power_settings_new : Icons.play_arrow_rounded,
                              color: AppTheme.onPrimary,
                              size: 56,
                            ),
                            Text(
                              isRunning ? 'STOP' : 'START',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Storage Insight
                _buildSectionHeader(context, 'STORAGE INSIGHT'),
                Consumer<FileProvider>(
                  builder: (context, fileProvider, _) {
                    final usedPercent = fileProvider.totalStorageGB > 0 
                        ? fileProvider.usedStorageGB / fileProvider.totalStorageGB 
                        : 0.0;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Device Storage',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${fileProvider.usedStorageGB.toStringAsFixed(1)} GB / ${fileProvider.totalStorageGB.toStringAsFixed(1)} GB',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: usedPercent,
                              backgroundColor: AppTheme.surfaceContainer,
                              color: usedPercent > 0.9 ? Colors.red : AppTheme.primary,
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent Activity (Live Logs)
                _buildSectionHeader(context, 'RECENT ACTIVITY'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: ftpProvider.logs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'No activity yet',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                          ),
                        )
                      : Column(
                          children: ftpProvider.logs.take(5).map((log) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.chevron_right, size: 16, color: AppTheme.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      log,
                                      style: AppTheme.codeSmall.copyWith(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
