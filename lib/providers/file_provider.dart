import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disk_space_2/disk_space_2.dart';

class FileProvider with ChangeNotifier {
  late String _currentPath;
  List<FileSystemEntity> _files = [];
  bool _isLoading = false;
  bool _isSearching = false;
  List<FileSystemEntity> _searchResults = [];
  List<String> _storageRoots = [];

  double _totalStorageGB = 0.0;
  double _usedStorageGB = 0.0;

  String get currentPath => _currentPath;
  List<FileSystemEntity> get files => _files;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  List<FileSystemEntity> get searchResults => _searchResults;
  List<String> get storageRoots => _storageRoots;
  double get totalStorageGB => _totalStorageGB;
  double get usedStorageGB => _usedStorageGB;

  FileProvider() {
    _initPath();
    _loadFiles();
  }

  void _initPath() {
    if (Platform.isAndroid) {
      _currentPath = '/storage/emulated/0';
    } else if (Platform.isWindows) {
      _currentPath = Platform.environment['USERPROFILE'] ?? Directory.current.path;
    } else {
      _currentPath = Platform.environment['HOME'] ?? Directory.current.path;
    }
    _detectStorageRoots();
  }

  void _detectStorageRoots() {
    _storageRoots = [];
    if (Platform.isAndroid) {
      _storageRoots.add('/storage/emulated/0');
      try {
        final storageDir = Directory('/storage');
        if (storageDir.existsSync()) {
          for (final entity in storageDir.listSync()) {
            final path = entity.path;
            if (path != '/storage/emulated/0' && !path.contains('self') && entity is Directory) {
              _storageRoots.add(path);
            }
          }
        }
      } catch (_) {}
    } else if (Platform.isWindows) {
      try {
        for (final drive in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']) {
          final path = '$drive:\\';
          if (Directory(path).existsSync()) {
            _storageRoots.add(path);
          }
        }
      } catch (_) {}
      if (!_storageRoots.contains(Platform.environment['USERPROFILE'] ?? '')) {
        _storageRoots.add(Platform.environment['USERPROFILE'] ?? 'C:\\');
      }
    } else {
      final home = Platform.environment['HOME'] ?? '/';
      _storageRoots.add(home);
      try {
        final mediaDir = Directory('/media');
        if (mediaDir.existsSync()) {
          for (final entity in mediaDir.listSync()) {
            if (entity is Directory && !entity.path.contains('.')) {
              _storageRoots.add(entity.path);
            }
          }
        }
        final mntDir = Directory('/mnt');
        if (mntDir.existsSync()) {
          for (final entity in mntDir.listSync()) {
            if (entity is Directory && !entity.path.contains('.')) {
              _storageRoots.add(entity.path);
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _updateStorageInfo() async {
    try {
      final totalMB = await DiskSpace.getTotalDiskSpace;
      final freeMB = await DiskSpace.getFreeDiskSpace;
      
      if (totalMB != null && freeMB != null) {
        _totalStorageGB = totalMB / 1024;
        _usedStorageGB = (totalMB - freeMB) / 1024;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error getting disk space: $e');
    }
  }

  void setPath(String path) {
    _currentPath = path;
    _loadFiles();
  }

  Future<void> refresh() async {
    await _loadFiles();
  }

  Future<void> _loadFiles() async {
    _isLoading = true;
    notifyListeners();

    await _updateStorageInfo();

    try {
      // Request and check permissions on Android
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          final req = await Permission.manageExternalStorage.request();
          if (!req.isGranted) {
            await Permission.storage.request();
          }
        }
        if (await Permission.notification.request().isGranted) {
          // Notification permission granted
        }
      }

      final dir = Directory(_currentPath);
      if (await dir.exists()) {
        _files = await dir.list().toList();
        // Sort: folders first, then files
        _files.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
      } else {
        _files = [];
      }
    } catch (e) {
      debugPrint('Error loading files: $e');
      _files = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchRecursive(String query) async {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchResults = [];
    notifyListeners();

    try {
      final dir = Directory(_currentPath);
      if (await dir.exists()) {
        final results = <FileSystemEntity>[];
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity.path.split('/').last.toLowerCase().contains(query.toLowerCase())) {
            results.add(entity);
          }
        }
        results.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
        _searchResults = results;
      }
    } catch (e) {
      debugPrint('Error searching files: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void cancelSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  // Create a new folder under current directory
  Future<bool> createFolder(String folderName) async {
    try {
      final newDir = Directory('$_currentPath/$folderName');
      if (!await newDir.exists()) {
        await newDir.create();
        await _loadFiles();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return false;
    }
  }

  // Delete a file or a folder recursively
  Future<bool> deleteEntity(FileSystemEntity entity) async {
    try {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else if (entity is File) {
        await entity.delete();
      }
      await _loadFiles();
      return true;
    } catch (e) {
      debugPrint('Error deleting entity: $e');
      return false;
    }
  }

  // Delete multiple files/folders, returns count of successful deletions
  Future<int> deleteMultiple(List<FileSystemEntity> entities) async {
    int successCount = 0;
    for (final entity in entities) {
      try {
        if (entity is Directory) {
          await entity.delete(recursive: true);
        } else if (entity is File) {
          await entity.delete();
        }
        successCount++;
      } catch (e) {
        debugPrint('Error deleting ${entity.path}: $e');
      }
    }
    await _loadFiles();
    return successCount;
  }

  // Helper method for the mock storage values
  void updateStorageInfo(double total, double used) {
    _totalStorageGB = total;
    _usedStorageGB = used;
    notifyListeners();
  }
}
