import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_ftp_app/providers/file_provider.dart';
import 'package:wifi_ftp_app/theme/app_theme.dart';
import 'package:path/path.dart' as p;

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FileProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, fileProvider, _) {
          // Filter files based on search query
          final filteredFiles = fileProvider.files.where((file) {
            final fileName = p.basename(file.path).toLowerCase();
            return fileName.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search in this folder...',
                                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.outline,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Breadcrumbs style path
                    Row(
                      children: [
                        const Icon(Icons.folder_open, size: 18, color: AppTheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              fileProvider.currentPath.replaceFirst('/storage/emulated/0', 'Root'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Files List
              Expanded(
                child: fileProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredFiles.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: filteredFiles.length + (fileProvider.currentPath == '/storage/emulated/0' || _searchQuery.isNotEmpty ? 0 : 1),
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              // Handle "Go Up" item
                              if (fileProvider.currentPath != '/storage/emulated/0' && _searchQuery.isEmpty && index == 0) {
                                return _buildFolderItem(
                                  context,
                                  onTap: () {
                                    final parentPath = p.dirname(fileProvider.currentPath);
                                    fileProvider.setPath(parentPath);
                                  },
                                  icon: Icons.keyboard_return,
                                  name: '.. (Up)',
                                  subtitle: 'Go to parent folder',
                                  color: AppTheme.outline,
                                );
                              }

                              final itemIndex = (fileProvider.currentPath == '/storage/emulated/0' || _searchQuery.isNotEmpty) ? index : index - 1;
                              final fileEntity = filteredFiles[itemIndex];
                              final isDirectory = fileEntity is Directory;
                              
                              // Use safe stat access
                              FileStat stat;
                              try {
                                stat = fileEntity.statSync();
                              } catch (_) {
                                return const SizedBox.shrink();
                              }

                              if (isDirectory) {
                                return _buildFolderItem(
                                  context,
                                  onTap: () {
                                    fileProvider.setPath(fileEntity.path);
                                    _searchController.clear();
                                    _searchQuery = '';
                                  },
                                  icon: Icons.folder_rounded,
                                  name: p.basename(fileEntity.path),
                                  subtitle: 'Folder • ${_formatDate(stat.modified)}',
                                  color: AppTheme.primary,
                                );
                              } else {
                                return _buildFileItem(
                                  context,
                                  name: p.basename(fileEntity.path),
                                  size: _formatBytes(stat.size),
                                  date: _formatDate(stat.modified),
                                  extension: p.extension(fileEntity.path).replaceAll('.', '').toUpperCase(),
                                );
                              }
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No matching files found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(
    BuildContext context, {
    required VoidCallback onTap,
    required IconData icon,
    required String name,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context, {
    required String name,
    required String size,
    required String date,
    required String extension,
  }) {
    // Determine color based on extension
    Color extColor = AppTheme.secondary;
    IconData icon = Icons.insert_drive_file_rounded;

    if (['JPG', 'PNG', 'WEBP', 'GIF'].contains(extension)) {
      extColor = Colors.orange;
      icon = Icons.image_rounded;
    } else if (['MP4', 'MKV', 'MOV'].contains(extension)) {
      extColor = Colors.purple;
      icon = Icons.videocam_rounded;
    } else if (['PDF', 'DOC', 'TXT'].contains(extension)) {
      extColor = Colors.blue;
      icon = Icons.description_rounded;
    } else if (['ZIP', 'RAR', '7Z'].contains(extension)) {
      extColor = Colors.amber;
      icon = Icons.archive_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: extColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: extension.length > 3
                  ? Icon(icon, color: extColor, size: 24)
                  : Text(
                      extension,
                      style: TextStyle(
                        color: extColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$size • $date',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: AppTheme.outlineVariant),
        ],
      ),
    );
  }
}
