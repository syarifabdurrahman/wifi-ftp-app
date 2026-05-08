import 'dart:io';

import 'package:flutter/material.dart';

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

  // Helper method for the mock storage values
  void updateStorageInfo(double total, double used) {
    _totalStorageGB = total;
    _usedStorageGB = used;
    notifyListeners();
  }
}
