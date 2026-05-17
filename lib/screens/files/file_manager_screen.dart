import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/providers/file_provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';
import 'package:quick_wifi_share/screens/files/media_preview_screen.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rootFolder = context.read<SettingsProvider>().rootFolder;
      context.read<FileProvider>().setPath(rootFolder);
    });
  }

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
            icon: const Icon(Icons.create_new_folder_rounded),
            tooltip: 'New Folder',
            onPressed: () => _showCreateFolderDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
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
                        color: AppTheme.getCardColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                          Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 20),
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
                                  color: Theme.of(context).colorScheme.outline,
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
                        // Clickable Home/Root Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              final rootPath = context.read<SettingsProvider>().rootFolder;
                              fileProvider.setPath(rootPath);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.home_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Root',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Theme.of(context).colorScheme.outlineVariant),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              fileProvider.currentPath == context.read<SettingsProvider>().rootFolder
                                  ? ' (Home)'
                                  : fileProvider.currentPath.replaceFirst(context.read<SettingsProvider>().rootFolder, ''),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Persistent "Go Up" card
                    if (fileProvider.currentPath != context.read<SettingsProvider>().rootFolder && _searchQuery.isEmpty) ...[
                      const SizedBox(height: 12),
                      _buildParentFolderCard(context, fileProvider),
                    ],
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
                            itemCount: filteredFiles.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final fileEntity = filteredFiles[index];
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
                                  onDelete: () => _confirmDelete(context, fileProvider, fileEntity),
                                  icon: Icons.folder_rounded,
                                  name: p.basename(fileEntity.path),
                                  subtitle: 'Folder • ${_formatDate(stat.modified)}',
                                  color: Theme.of(context).colorScheme.primary,
                                );
                              } else {
                                return _buildFileItem(
                                  context,
                                  name: p.basename(fileEntity.path),
                                  size: _formatBytes(stat.size),
                                  date: _formatDate(stat.modified),
                                  extension: p.extension(fileEntity.path).replaceAll('.', '').toUpperCase(),
                                  path: fileEntity.path,
                                  onDelete: () => _confirmDelete(context, fileProvider, fileEntity),
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
          Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No matching files found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildParentFolderCard(BuildContext context, FileProvider fileProvider) {
    final parentPath = p.dirname(fileProvider.currentPath);
    final parentName = p.basename(parentPath);

    return InkWell(
      onTap: () {
        fileProvider.setPath(parentPath);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parent Folder',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    'Go back to ${parentName.isEmpty || parentName == '0' ? 'Root' : parentName}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_return_rounded, size: 18, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FileProvider fileProvider, FileSystemEntity entity) {
    final name = p.basename(entity.path);
    final isFolder = entity is Directory;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text('Confirm Delete'),
            ],
          ),
          content: Text('Are you sure you want to permanently delete the ${isFolder ? 'folder' : 'file'} "$name"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                final success = await fileProvider.deleteEntity(entity);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Successfully deleted "$name"' : 'Failed to delete "$name"'),
                      backgroundColor: success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    final fileProvider = context.read<FileProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.folder_open_rounded, color: Color(0xFF005EB8)),
              SizedBox(width: 8),
              Text('Create New Folder'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter folder name...',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final folderName = controller.text.trim();
                if (folderName.isEmpty) return;

                Navigator.pop(context);
                final success = await fileProvider.createFolder(folderName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Successfully created folder "$folderName"' : 'Failed to create folder "$folderName" (already exists or permission denied)'),
                      backgroundColor: success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderItem(
    BuildContext context, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
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
          color: AppTheme.getCardColor(context),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.outlineVariant),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
              ],
            ),
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
    required String path,
    required VoidCallback onDelete,
  }) {
    // Determine color based on extension
    Color extColor = Theme.of(context).colorScheme.secondary;
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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaPreviewScreen(filePath: path),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.outlineVariant),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
