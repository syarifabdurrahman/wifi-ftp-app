import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FileProvider with ChangeNotifier {
  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _files = [];
  bool _isLoading = false;

  double _totalStorageGB = 128.0; // Mocked for now, getting real storage requires native code
  double _usedStorageGB = 45.2;

  String get currentPath => _currentPath;
  List<FileSystemEntity> get files => _files;
  bool get isLoading => _isLoading;
  double get totalStorageGB => _totalStorageGB;
  double get usedStorageGB => _usedStorageGB;

  FileProvider() {
    _loadFiles();
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

  // Helper method for the mock storage values
  void updateStorageInfo(double total, double used) {
    _totalStorageGB = total;
    _usedStorageGB = used;
    notifyListeners();
  }
}
