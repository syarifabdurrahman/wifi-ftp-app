import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_wifi_share/providers/file_provider.dart';
import 'package:quick_wifi_share/providers/ftp_provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';
import 'package:quick_wifi_share/widgets/animated_mesh_background.dart';
import 'package:quick_wifi_share/widgets/glass_container.dart';
import 'package:quick_wifi_share/widgets/native_ad_card.dart';
import 'package:quick_wifi_share/widgets/pulse_animation.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  Future<void> _toggleServer(BuildContext context, FtpProvider ftpProvider, SettingsProvider settingsProvider) async {
    HapticFeedback.mediumImpact();
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
            const SnackBar(content: Text('Failed to start FTP Server.')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permissions required.')),
          );
        }
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
      ),
      body: AnimatedMeshBackground(
        child: Consumer2<FtpProvider, SettingsProvider>(
          builder: (context, ftpProvider, settingsProvider, child) {
            final isRunning = ftpProvider.isRunning;
            final statusColor = isRunning ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline;
            final ftpAddress = isRunning
                ? 'ftp://${ftpProvider.ipAddress}:${settingsProvider.port}'
                : 'Server offline';

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.0, MediaQuery.of(context).padding.top + 56 + 20, 16.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Stat
                  _buildQuickStat(
                    context,
                    title: 'Status',
                    value: isRunning ? 'Online' : 'Offline',
                    color: statusColor,
                    icon: isRunning ? Icons.cloud_done : Icons.cloud_off,
                  ),
                  const SizedBox(height: 24),
                  
                  // Connection Hero Card (Glassmorphism)
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (isRunning) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: ftpAddress,
                              version: QrVersions.auto,
                              size: 140.0,
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: Color(0xFF191C21),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'FTP CONNECTION URL',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            if (isRunning) {
                              Clipboard.setData(ClipboardData(text: ftpAddress));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('URL copied to clipboard')),
                              );
                              HapticFeedback.selectionClick();
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, color: statusColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ftpAddress,
                                    style: AppTheme.codeSmall.copyWith(
                                      color: isRunning ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outline,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isRunning) Icon(Icons.copy, size: 18, color: Theme.of(context).colorScheme.outline),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Power Button
                  Center(
                    child: PulseAnimation(
                      isRunning: isRunning,
                      color: statusColor,
                      child: GestureDetector(
                        onTap: () => _toggleServer(context, ftpProvider, settingsProvider),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isRunning 
                                ? [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer]
                                : [Theme.of(context).colorScheme.outline, Theme.of(context).colorScheme.outlineVariant],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            isRunning ? Icons.power_settings_new : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Transfer Stats Card
                  if (isRunning) ...[
                    _buildSectionHeader(context, 'DATA USAGE'),
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _buildTransferItem(
                            context,
                            label: 'Total Transferred',
                            value: _formatBytes(ftpProvider.totalBytesTransferred),
                            icon: Icons.swap_vert_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Storage Insight
                  _buildSectionHeader(context, 'STORAGE INSIGHT'),
                  Consumer<FileProvider>(
                    builder: (context, fileProvider, _) {
                      final usedPercent = fileProvider.totalStorageGB > 0 
                          ? fileProvider.usedStorageGB / fileProvider.totalStorageGB 
                          : 0.0;
                      return GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Device Storage',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${fileProvider.usedStorageGB.toStringAsFixed(1)} / ${fileProvider.totalStorageGB.toStringAsFixed(1)} GB',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: usedPercent,
                                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                                color: usedPercent > 0.9 ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                                minHeight: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Native Ad Card
                  const NativeAdCard(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      opacity: 0.05,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferItem(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 2.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
