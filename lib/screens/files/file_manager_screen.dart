import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/providers/file_provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';
import 'package:quick_wifi_share/screens/files/media_preview_screen.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';
import 'package:quick_wifi_share/widgets/bookmarks_dialog.dart';
import 'package:path/path.dart' as p;

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

enum FileFilter { all, images, videos, documents, archives, audio }

extension FileFilterLabel on FileFilter {
  String get label {
    switch (this) {
      case FileFilter.all: return 'All';
      case FileFilter.images: return 'Images';
      case FileFilter.videos: return 'Videos';
      case FileFilter.documents: return 'Docs';
      case FileFilter.archives: return 'Archives';
      case FileFilter.audio: return 'Audio';
    }
  }
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  FileFilter _fileFilter = FileFilter.all;
  final Set<String> _selectedPaths = {};
  bool _isSelectionMode = false;

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

  bool _matchesFilter(String extension) {
    if (_fileFilter == FileFilter.all) return true;
    final ext = extension.toUpperCase();
    switch (_fileFilter) {
      case FileFilter.images:
        return ['JPG', 'JPEG', 'PNG', 'WEBP', 'GIF', 'BMP'].contains(ext);
      case FileFilter.videos:
        return ['MP4', 'MKV', 'MOV', 'AVI', 'WMV', 'FLV'].contains(ext);
      case FileFilter.documents:
        return ['PDF', 'DOC', 'DOCX', 'XLS', 'XLSX', 'PPT', 'PPTX', 'TXT', 'CSV'].contains(ext);
      case FileFilter.archives:
        return ['ZIP', 'RAR', '7Z', 'TAR', 'GZ', 'TGZ'].contains(ext);
      case FileFilter.audio:
        return ['MP3', 'WAV', 'M4A', 'FLAC', 'AAC', 'OGG'].contains(ext);
      case FileFilter.all:
        return true;
    }
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
        title: _isSelectionMode
            ? Text('${_selectedPaths.length} selected')
            : const Text('File Explorer'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedPaths.clear();
                }),
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: _selectedPaths.isEmpty ? null : Colors.red),
              tooltip: 'Delete selected',
              onPressed: _selectedPaths.isEmpty
                  ? null
                  : () => _confirmBatchDelete(context),
            ),
          // Storage root selector
          Consumer<FileProvider>(
            builder: (context, fp, _) {
              if (fp.storageRoots.length <= 1) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: Icon(Icons.storage_rounded, color: Theme.of(context).colorScheme.secondary),
                tooltip: 'Switch storage',
                onSelected: (path) {
                  fp.setPath(path);
                  _searchController.clear();
                  _searchQuery = '';
                  context.read<FileProvider>().cancelSearch();
                },
                itemBuilder: (_) => fp.storageRoots.map((path) {
                  final isActive = fp.currentPath == path || fp.currentPath.startsWith(path);
                  return PopupMenuItem(
                    value: path,
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.drive_file_move_rounded : Icons.storage_rounded,
                          size: 18,
                          color: isActive ? Theme.of(context).colorScheme.primary : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          path.split('/').last,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        Text(path, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
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
          // Determine files source: normal list or recursive search results
          final bool isRecursiveSearch = _searchQuery.isNotEmpty;
          final filesSource = isRecursiveSearch ? fileProvider.searchResults : fileProvider.files;

          // Apply type filter
          final filteredFiles = filesSource.where((file) {
            if (file is Directory) return _fileFilter == FileFilter.all || isRecursiveSearch;
            final ext = p.extension(file.path).replaceAll('.', '');
            return _matchesFilter(ext);
          }).toList();

          // Client-side filter for search (when not recursive, still filter client-side)
          final displayedFiles = isRecursiveSearch
              ? filteredFiles
              : filteredFiles.where((file) {
                  final fileName = p.basename(file.path).toLowerCase();
                  return fileName.contains(_searchQuery.toLowerCase());
                }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
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
                                setState(() => _searchQuery = value);
                                if (value.isNotEmpty) {
                                  context.read<FileProvider>().searchRecursive(value);
                                } else {
                                  context.read<FileProvider>().cancelSearch();
                                }
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
                                context.read<FileProvider>().cancelSearch();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Breadcrumbs style path with bookmarks
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
                        // Bookmark toggle
                        Consumer<SettingsProvider>(
                          builder: (context, settings, _) {
                            final isBookmarked = settings.isBookmarked(fileProvider.currentPath);
                            return IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                size: 20,
                                color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
                              ),
                              tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark this folder',
                              onPressed: () => settings.toggleBookmark(fileProvider.currentPath),
                            );
                          },
                        ),
                        // View bookmarks
                        IconButton(
                          icon: Icon(Icons.bookmarks_rounded, size: 20, color: Theme.of(context).colorScheme.secondary),
                          tooltip: 'Bookmarked folders',
                          onPressed: () => BookmarksDialog.show(context),
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

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: FileFilter.values.map((filter) {
                      final isSelected = _fileFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.label, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _fileFilter = filter),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Files List
              Expanded(
                child: fileProvider.isLoading || fileProvider.isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : displayedFiles.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: displayedFiles.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final fileEntity = displayedFiles[index];
                              final isDirectory = fileEntity is Directory;
                              final filePath = fileEntity.path;
                              final isSelected = _selectedPaths.contains(filePath);

                              // Use safe stat access
                              FileStat stat;
                              try {
                                stat = fileEntity.statSync();
                              } catch (_) {
                                return const SizedBox.shrink();
                              }

                              void onToggleSelect() {
                                setState(() {
                                  if (_selectedPaths.contains(filePath)) {
                                    _selectedPaths.remove(filePath);
                                    if (_selectedPaths.isEmpty) {
                                      _isSelectionMode = false;
                                    }
                                  } else {
                                    _selectedPaths.add(filePath);
                                  }
                                });
                              }

                              if (isDirectory) {
                                return _buildFolderItem(
                                  context,
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      onToggleSelect();
                                    } else {
                                      fileProvider.setPath(filePath);
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }
                                  },
                                  onDelete: () => _confirmDelete(context, fileProvider, fileEntity),
                                  icon: Icons.folder_rounded,
                                  name: p.basename(filePath),
                                  subtitle: 'Folder • ${_formatDate(stat.modified)}',
                                  color: Theme.of(context).colorScheme.primary,
                                  isSelected: isSelected,
                                  onToggleSelect: _isSelectionMode ? onToggleSelect : null,
                                );
                              } else {
                                return _buildFileItem(
                                  context,
                                  name: p.basename(filePath),
                                  size: _formatBytes(stat.size),
                                  date: _formatDate(stat.modified),
                                  extension: p.extension(filePath).replaceAll('.', '').toUpperCase(),
                                  path: filePath,
                                  onDelete: () => _confirmDelete(context, fileProvider, fileEntity),
                                  isSelected: isSelected,
                                  onToggleSelect: _isSelectionMode ? onToggleSelect : null,
                                );
                              }
                            },
                          ),
              ),
            ],
          ),
        ),
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

  void _confirmBatchDelete(BuildContext context) {
    final fileProvider = context.read<FileProvider>();
    final count = _selectedPaths.length;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text('Delete $count items'),
            ],
          ),
          content: Text('Are you sure you want to permanently delete $count selected item${count > 1 ? 's' : ''}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final entities = _selectedPaths
                    .map((p) => FileSystemEntity.typeSync(p) == FileSystemEntityType.directory
                        ? Directory(p) as FileSystemEntity
                        : File(p) as FileSystemEntity)
                    .toList();
                final successCount = await fileProvider.deleteMultiple(entities);
                if (context.mounted) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedPaths.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(successCount == count
                          ? 'Successfully deleted $count item${count > 1 ? 's' : ''}'
                          : 'Deleted $successCount/$count item${count > 1 ? 's' : ''}'),
                      backgroundColor: successCount == count ? Colors.green : Colors.orange,
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
    bool isSelected = false,
    VoidCallback? onToggleSelect,
  }) {
    return InkWell(
      onTap: onToggleSelect ?? onTap,
      onLongPress: onToggleSelect != null
          ? () {}
          : () {
              setState(() {
                _isSelectionMode = true;
                _selectedPaths.clear();
              });
              onToggleSelect!();
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : AppTheme.getCardColor(context),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  size: 24,
                ),
              ),
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
            if (!_isSelectionMode)
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
    bool isSelected = false,
    VoidCallback? onToggleSelect,
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
      onTap: onToggleSelect ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaPreviewScreen(filePath: path),
          ),
        );
      },
      onLongPress: onToggleSelect != null
          ? () {}
          : () {
              setState(() {
                _isSelectionMode = true;
                _selectedPaths.clear();
              });
              onToggleSelect!();
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : AppTheme.getCardColor(context),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  size: 24,
                ),
              ),
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
            if (!_isSelectionMode)
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
