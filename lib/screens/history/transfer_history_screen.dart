import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/providers/ftp_provider.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';

class TransferHistoryScreen extends StatelessWidget {
  const TransferHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Optionally add a clear logs method to FtpProvider
            },
          ),
        ],
      ),
      body: Consumer<FtpProvider>(
        builder: (context, ftpProvider, _) {
          final logs = ftpProvider.logs;

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_edu_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity recorded yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start the server to see real-time events.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogEntry(context, log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, String log) {
    // Basic parsing for better icons
    IconData icon = Icons.info_outline_rounded;
    Color color = Theme.of(context).colorScheme.secondary;

    if (log.contains('Command:')) {
      icon = Icons.terminal_rounded;
      color = Theme.of(context).colorScheme.primary;
    } else if (log.contains('connected')) {
      icon = Icons.person_add_rounded;
      color = Colors.green;
    } else if (log.contains('disconnected')) {
      icon = Icons.person_remove_rounded;
      color = Colors.orange;
    } else if (log.contains('Error')) {
      icon = Icons.error_outline_rounded;
      color = Theme.of(context).colorScheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log,
                  style: AppTheme.codeSmall.copyWith(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTimeString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeString() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}
