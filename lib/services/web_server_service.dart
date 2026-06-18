import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class WebServerService {
  HttpServer? _server;
  final String rootPath;
  final int port;
  final Function(String) logFunction;
  int speedLimitKBps = 0;

  WebServerService({
    required this.rootPath,
    this.port = 8080,
    this.speedLimitKBps = 0,
    required this.logFunction,
  });

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
        backlog: 256,
      );
      logFunction("Web Server started on http://0.0.0.0:$port");

      _server!.listen((HttpRequest request) async {
        try {
          await _handleRequest(request);
        } catch (e) {
          logFunction("Error handling web request: $e");
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.write("Internal Server Error: $e");
            await request.response.close();
          } catch (_) {}
        }
      });
    } catch (e) {
      logFunction("Failed to start Web Server: $e");
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      logFunction("Web Server stopped.");
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final uri = request.uri;
    final path = uri.path;

    // CORS Headers to allow any client connection
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    if (path == '/') {
      request.response.headers.contentType = ContentType.html;
      request.response.write(_getHtmlContent());
      await request.response.close();
      return;
    }

    if (path == '/api/files') {
      await _handleApiFiles(request);
      return;
    }

    if (path == '/download') {
      await _handleDownload(request);
      return;
    }

    if (path == '/download-zip') {
      await _handleDownloadZip(request);
      return;
    }

    if (path == '/upload' && request.method == 'POST') {
      await _handleUpload(request);
      return;
    }

    // Default 404
    request.response.statusCode = HttpStatus.notFound;
    request.response.write("404 Not Found");
    await request.response.close();
  }

  Future<void> _handleApiFiles(HttpRequest request) async {
    final relativePath = Uri.decodeComponent(request.uri.queryParameters['dir'] ?? '');
    final safePath = _getSafePath(relativePath);

    if (safePath == null) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write(jsonEncode({'error': 'Access Denied: Path outside root directory.'}));
      await request.response.close();
      return;
    }

    final directory = Directory(safePath);
    if (!await directory.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode({'error': 'Directory not found.'}));
      await request.response.close();
      return;
    }

    try {
      final items = <Map<String, dynamic>>[];
      await for (final entity in directory.list()) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue; // skip hidden files

        final isDir = entity is Directory;
        int size = 0;
        DateTime modified = DateTime.now();

        try {
          final stat = await entity.stat();
          size = stat.size;
          modified = stat.modified;
        } catch (_) {}

        final rel = p.relative(entity.path, from: rootPath);

        items.add({
          'name': name,
          'path': rel == '.' ? '' : rel,
          'isDirectory': isDir,
          'size': size,
          'modified': modified.toIso8601String(),
          'extension': isDir ? '' : p.extension(entity.path).replaceAll('.', '').toUpperCase(),
        });
      }

      // Sort: Directories first, then alphabetically by name
      items.sort((a, b) {
        if (a['isDirectory'] && !b['isDirectory']) return -1;
        if (!a['isDirectory'] && b['isDirectory']) return 1;
        return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
      });

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'currentDir': relativePath,
        'items': items,
      }));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleDownload(HttpRequest request) async {
    final relativePath = Uri.decodeComponent(request.uri.queryParameters['file'] ?? '');
    final safePath = _getSafePath(relativePath);

    if (safePath == null) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write("Access Denied.");
      await request.response.close();
      return;
    }

    final file = File(safePath);
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write("File not found.");
      await request.response.close();
      return;
    }

    try {
      final stat = await file.stat();
      final filename = p.basename(file.path);

      request.response.statusCode = HttpStatus.ok;
      request.response.bufferOutput = false;
      request.response.headers.add('Content-Length', stat.size.toString());
      request.response.headers.add(
        'Content-Disposition',
        'attachment; filename="${Uri.encodeComponent(filename)}"',
      );
      
      // Attempt generic content type mapping
      final ext = p.extension(file.path).toLowerCase();
      if (ext == '.jpg' || ext == '.jpeg') {
        request.response.headers.contentType = ContentType('image', 'jpeg');
      } else if (ext == '.png') {
        request.response.headers.contentType = ContentType('image', 'png');
      } else if (ext == '.mp4') {
        request.response.headers.contentType = ContentType('video', 'mp4');
      } else if (ext == '.mp3') {
        request.response.headers.contentType = ContentType('audio', 'mpeg');
      } else if (ext == '.pdf') {
        request.response.headers.contentType = ContentType('application', 'pdf');
      } else if (ext == '.txt') {
        request.response.headers.contentType = ContentType.text;
      } else {
        request.response.headers.contentType = ContentType.binary;
      }

      int transferred = 0;
      try {
        Stream<List<int>> stream = file.openRead();
        if (speedLimitKBps > 0) {
          final chunkSize = speedLimitKBps * 1024; // bytes per chunk
          final delay = const Duration(milliseconds: 1000);
          stream = stream.transform(
            StreamTransformer.fromHandlers(
              handleData: (chunk, sink) async {
                for (int i = 0; i < chunk.length; i += chunkSize) {
                  final int end = (i + chunkSize > chunk.length) ? chunk.length : i + chunkSize;
                  sink.add(chunk.sublist(i, end));
                  transferred += end - i;
                  await Future.delayed(delay);
                }
              },
            ),
          );
        } else {
          stream = stream.map((chunk) {
            transferred += chunk.length;
            return chunk;
          });
        }
        await request.response.addStream(stream);
        await request.response.close();
      } finally {
        if (transferred > 0) {
          logFunction("$transferred bytes transferred via Web Download");
        }
      }
    } catch (e) {
      logFunction("Error streaming download: $e");
    }
  }

  Future<void> _handleDownloadZip(HttpRequest request) async {
    final relativePath = Uri.decodeComponent(request.uri.queryParameters['dir'] ?? '');
    final safePath = _getSafePath(relativePath);

    if (safePath == null) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write('Access Denied.');
      await request.response.close();
      return;
    }

    final dir = Directory(safePath);
    if (!await dir.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Directory not found.');
      await request.response.close();
      return;
    }

    final dirName = p.basename(safePath);
    final zipName = '${dirName.isEmpty ? 'files' : dirName}.zip';

    try {
      final archive = Archive();
      await _addDirToArchive(archive, dir, '');
      final encoded = ZipEncoder().encode(archive);

      request.response.statusCode = HttpStatus.ok;
      request.response.bufferOutput = false;
      request.response.headers.add('Content-Type', 'application/zip');
      request.response.headers.add('Content-Disposition', 'attachment; filename="$zipName"');
      request.response.add(encoded);
      await request.response.close();
      logFunction('ZIP downloaded: $zipName');
    } catch (e) {
      logFunction('Error creating ZIP: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Error creating ZIP: $e');
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _addDirToArchive(Archive archive, Directory dir, String prefix) async {
    try {
      await for (final entity in dir.list()) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        final relPath = prefix.isEmpty ? name : '$prefix/$name';
        if (entity is File) {
          try {
            final data = await entity.readAsBytes();
            archive.addFile(ArchiveFile(relPath, data.length, data));
          } catch (_) {}
        } else if (entity is Directory) {
          await _addDirToArchive(archive, entity, relPath);
        }
      }
    } catch (_) {}
  }

  Future<void> _handleUpload(HttpRequest request) async {
    final relativeDir = Uri.decodeComponent(request.uri.queryParameters['dir'] ?? '');
    final filename = Uri.decodeComponent(request.uri.queryParameters['filename'] ?? '');
    
    if (filename.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write("Filename is required.");
      await request.response.close();
      return;
    }

    final safeDirPath = _getSafePath(relativeDir);
    if (safeDirPath == null) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write("Access Denied.");
      await request.response.close();
      return;
    }

    final dir = Directory(safeDirPath);
    if (!await dir.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write("Directory not found.");
      await request.response.close();
      return;
    }

    final safeFilePath = p.normalize(p.join(safeDirPath, filename));
    if (!p.isWithin(safeDirPath, safeFilePath) && safeFilePath != safeDirPath) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write("Invalid filename.");
      await request.response.close();
      return;
    }

    final file = File(safeFilePath);
    IOSink? sink;
    int transferred = 0;
    
    try {
      sink = file.openWrite(mode: FileMode.write);
      await request.cast<List<int>>().pipe(sink);
      transferred = await file.length();
      
      request.response.statusCode = HttpStatus.ok;
      request.response.write(jsonEncode({'success': true, 'path': safeFilePath}));
    } catch (e) {
      logFunction("Error handling upload: $e");
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write("Upload failed: $e");
    } finally {
      await sink?.flush();
      await sink?.close();
      await request.response.close();
      if (transferred > 0) {
        logFunction("$transferred bytes transferred via Web Upload");
      }
    }
  }

  String? _getSafePath(String relPath) {
    // Prevent directory traversal
    final fullPath = p.normalize(p.join(rootPath, relPath));
    if (p.isWithin(rootPath, fullPath) || fullPath == rootPath) {
      return fullPath;
    }
    return null;
  }

  String _getHtmlContent() {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WiFi Share Portal</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/lucide@latest"></script>
    <style>
        :root {
            --bg-base: #090b11;
            --bg-sidebar: #05060a;
            --bg-card: #121622;
            --bg-card-hover: #1e2436;
            --text-base: #f8fafc;
            --text-muted: #64748b;
            --accent: #22c55e;
            --accent-hover: #16a34a;
            --border-color: rgba(255, 255, 255, 0.04);
            --font-family: 'Plus Jakarta Sans', sans-serif;
        }

        [data-theme="light"] {
            --bg-base: #f8fafc;
            --bg-sidebar: #ffffff;
            --bg-card: #ffffff;
            --bg-card-hover: #f1f5f9;
            --text-base: #0f172a;
            --text-muted: #64748b;
            --accent: #22c55e;
            --accent-hover: #16a34a;
            --border-color: rgba(0, 0, 0, 0.05);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: var(--font-family);
            transition: background-color 0.3s, border-color 0.3s, color 0.3s;
        }

        body {
            background-color: var(--bg-base);
            color: var(--text-base);
            min-height: 100vh;
            display: flex;
            overflow: hidden;
            -webkit-overflow-scrolling: touch;
            touch-action: manipulation;
            overscroll-behavior: contain;
            position: fixed;
            width: 100%;
            height: 100%;
        }

        /* Sidebar Styling (Spotify/Linear-like) */
        .sidebar {
            width: 260px;
            background-color: var(--bg-sidebar);
            border-right: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            gap: 28px;
            padding: 24px;
            z-index: 10;
        }

        .logo-container {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 6px;
        }

        .logo-icon-box {
            background-color: var(--accent);
            color: #05060a;
            width: 36px;
            height: 36px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 8px 16px rgba(34, 197, 94, 0.25);
        }

        .logo-text {
            font-size: 18px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }

        .nav-menu {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 10px 14px;
            border-radius: 8px;
            color: var(--text-muted);
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
        }

        .nav-item:hover, .nav-item.active {
            color: var(--text-base);
            background-color: var(--bg-card-hover);
        }

        .nav-item.active i {
            color: var(--accent);
        }

        .storage-card {
            margin-top: auto;
            background: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 14px;
            padding: 18px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .storage-card-title {
            font-size: 11px;
            font-weight: 700;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 1.2px;
        }

        .storage-bar-outer {
            background-color: var(--bg-base);
            height: 6px;
            border-radius: 3px;
            overflow: hidden;
        }

        .storage-bar-inner {
            background-color: var(--accent);
            height: 100%;
            width: 80%;
            border-radius: 3px;
            box-shadow: 0 0 8px rgba(34, 197, 94, 0.4);
        }

        /* Main Workspace Container */
        .workspace {
            flex: 1;
            display: flex;
            flex-direction: column;
            height: 100vh;
            overflow: hidden;
            background: linear-gradient(180deg, rgba(34, 197, 94, 0.02) 0%, rgba(9, 11, 17, 0) 100%);
        }

        /* Header Navigation Panel */
        .workspace-header {
            padding: 20px 32px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--border-color);
            backdrop-filter: blur(16px);
            background-color: rgba(9, 11, 17, 0.2);
            z-index: 5;
        }

        .search-bar {
            display: flex;
            align-items: center;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            padding: 6px 16px;
            width: 340px;
            gap: 10px;
        }

        .search-bar input {
            background: transparent;
            border: none;
            color: var(--text-base);
            font-size: 14px;
            outline: none;
            width: 100%;
        }

        .search-bar input::placeholder {
            color: var(--text-muted);
        }

        .search-bar i {
            color: var(--text-muted);
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .round-button {
            width: 38px;
            height: 38px;
            border-radius: 50%;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            color: var(--text-base);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }

        .round-button:hover {
            transform: scale(1.05);
            background-color: var(--bg-card-hover);
            border-color: rgba(34, 197, 94, 0.2);
        }

        /* Content Panel Layout */
        .workspace-content {
            flex: 1;
            overflow-y: auto;
            overflow-x: hidden;
            padding: 32px;
            -webkit-overflow-scrolling: touch;
            overscroll-behavior: contain;
            touch-action: auto;
            min-height: 0;
        }

        .breadcrumb-trail {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 24px;
            font-size: 13px;
        }

        .breadcrumb-pill {
            cursor: pointer;
            padding: 5px 12px;
            border-radius: 20px;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            font-weight: 500;
            color: var(--text-base);
        }

        .breadcrumb-pill:hover {
            background-color: var(--bg-card-hover);
        }

        .breadcrumb-pill.active {
            background-color: transparent;
            border-color: transparent;
            color: var(--text-muted);
            cursor: default;
        }

        .breadcrumb-divider {
            color: var(--text-muted);
            font-size: 10px;
        }

        .content-header-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }

        .content-title {
            font-size: 24px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }

        .layout-selectors {
            display: flex;
            gap: 8px;
            background: var(--bg-sidebar);
            padding: 3px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
        }

        .layout-btn {
            background: transparent;
            border: none;
            color: var(--text-muted);
            padding: 6px 10px;
            border-radius: 6px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .layout-btn.active {
            background-color: var(--bg-card);
            color: var(--text-base);
        }

        /* Track/File Row Layout (Spotify Playlist Style) */
        .playlist-header-row {
            display: grid;
            grid-template-columns: 44px 4fr 2fr 1fr 80px;
            padding: 10px 16px;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-muted);
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }

        .playlist-row {
            display: grid;
            grid-template-columns: 44px 4fr 2fr 1fr 80px;
            padding: 12px 16px;
            border-radius: 8px;
            align-items: center;
            cursor: pointer;
        }

        .playlist-row:hover {
            background-color: var(--bg-card-hover);
        }

        .playlist-index {
            color: var(--text-muted);
            font-size: 13px;
            display: flex;
            align-items: center;
        }

        .playlist-title-cell {
            display: flex;
            align-items: center;
            gap: 16px;
            min-width: 0;
        }

        .playlist-icon-box {
            width: 38px;
            height: 38px;
            border-radius: 6px;
            background-color: var(--bg-sidebar);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--text-muted);
        }

        .playlist-row:hover .playlist-icon-box {
            color: var(--accent);
        }

        .playlist-name {
            font-size: 14px;
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            color: var(--text-base);
        }

        .playlist-modified {
            font-size: 13px;
            color: var(--text-muted);
        }

        .playlist-size {
            font-size: 13px;
            color: var(--text-muted);
        }

        .playlist-action-cell {
            display: flex;
            justify-content: flex-end;
        }

        .playlist-row-btn {
            background-color: var(--accent);
            color: #05060a;
            border: none;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            opacity: 0;
            transform: scale(0.8);
            transition: opacity 0.2s, transform 0.2s, background-color 0.2s;
        }

        .playlist-row:hover .playlist-row-btn {
            opacity: 1;
            transform: scale(1);
        }

        .playlist-row-btn:hover {
            background-color: var(--accent-hover);
            transform: scale(1.08) !important;
        }

        /* Modern Grid View Layout */
        .spotify-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 24px;
        }

        .spotify-card {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 16px;
            display: flex;
            flex-direction: column;
            gap: 12px;
            cursor: pointer;
            position: relative;
        }

        .spotify-card:hover {
            background-color: var(--bg-card-hover);
            transform: translateY(-2px);
        }

        .spotify-card-icon {
            width: 100%;
            height: 120px;
            border-radius: 8px;
            background-color: var(--bg-sidebar);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--text-muted);
        }

        .spotify-card:hover .spotify-card-icon {
            color: var(--accent);
        }

        .spotify-card-info {
            display: flex;
            flex-direction: column;
            gap: 4px;
            min-width: 0;
        }

        .spotify-card-name {
            font-size: 14px;
            font-weight: 700;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .spotify-card-meta {
            font-size: 11px;
            color: var(--text-muted);
        }

        .spotify-card-play-btn {
            position: absolute;
            right: 20px;
            bottom: 64px;
            width: 42px;
            height: 42px;
            border-radius: 50%;
            background-color: var(--accent);
            color: #05060a;
            border: none;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 8px 16px rgba(0,0,0,0.3);
            opacity: 0;
            transform: translateY(8px);
            transition: opacity 0.2s, transform 0.2s, background-color 0.2s;
            cursor: pointer;
        }

        .spotify-card:hover .spotify-card-play-btn {
            opacity: 1;
            transform: translateY(0);
        }

        .spotify-card-play-btn:hover {
            background-color: var(--accent-hover);
            transform: scale(1.06);
        }

        /* Empty State */
        .empty-view {
            text-align: center;
            padding: 80px 20px;
            color: var(--text-muted);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 16px;
        }

        /* Upload Toast */
        .upload-toast {
            position: fixed;
            bottom: 32px;
            right: 32px;
            background-color: var(--bg-sidebar);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 16px 20px;
            width: 320px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.5);
            display: flex;
            flex-direction: column;
            gap: 12px;
            transform: translateY(150%);
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            z-index: 50;
        }

        .upload-toast.show {
            transform: translateY(0);
        }

        .toast-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .toast-title {
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .toast-title i {
            color: var(--accent);
        }

        .toast-progress-bar {
            height: 6px;
            background-color: var(--bg-base);
            border-radius: 3px;
            overflow: hidden;
        }

        .toast-progress-fill {
            height: 100%;
            background-color: var(--accent);
            width: 0%;
            transition: width 0.2s;
        }

        /* Drag & Drop Overlay */
        .drag-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(9, 11, 17, 0.85);
            backdrop-filter: blur(8px);
            z-index: 9999;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: var(--accent);
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.2s;
        }
        
        .drag-overlay.active {
            opacity: 1;
        }

        .drag-overlay i {
            width: 80px; height: 80px;
            margin-bottom: 20px;
        }

        .drag-overlay h2 {
            font-size: 28px;
            color: var(--text-base);
            font-weight: 700;
        }

        /* Custom Scrollbars */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }

        ::-webkit-scrollbar-track {
            background: transparent;
        }

        ::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.08);
            border-radius: 4px;
        }

        ::-webkit-scrollbar-thumb:hover {
            background: rgba(255, 255, 255, 0.16);
        }

        /* Mobile Adjustments */
        @media (max-width: 900px) {
            body {
                flex-direction: column;
            }

            .sidebar {
                width: 100%;
                border-right: none;
                border-bottom: 1px solid var(--border-color);
                padding: 16px;
                flex-direction: row;
                justify-content: space-between;
                align-items: center;
                gap: 12px;
            }

            .storage-card {
                display: none;
            }

            .workspace {
                height: calc(var(--vh, 1vh) * 100 - 72px);
            }

            .workspace-header {
                padding: 12px 16px;
                flex-shrink: 0;
            }

            .search-bar {
                width: 170px;
            }

            .workspace-content {
                padding: 16px;
                min-height: 0;
                flex: 1 1 auto;
                height: 0;
            }

            .playlist-header-row {
                grid-template-columns: 44px 1fr 60px;
            }
            .playlist-row {
                grid-template-columns: 44px 1fr 60px;
            }
            .playlist-modified, .playlist-size {
                display: none;
            }
            .playlist-row-btn {
                opacity: 1;
                transform: scale(1);
            }
        }
    </style>
</head>
<body>
    <!-- Premium Sidebar Panel -->
    <aside class="sidebar">
        <div class="logo-container">
            <div class="logo-icon-box">
                <i data-lucide="wifi"></i>
            </div>
            <div class="logo-text">WiFi Share</div>
        </div>

        <nav class="nav-menu">
            <div class="nav-item active" onclick="navigateTo('')">
                <i data-lucide="folder-heart"></i>
                <span>Library</span>
            </div>
            <a class="nav-item" href="https://github.com" target="_blank">
                <i data-lucide="github"></i>
                <span>Source Code</span>
            </a>
        </nav>

        <div class="storage-card">
            <div class="storage-card-title">Device Storage</div>
            <div class="storage-bar-outer">
                <div class="storage-bar-inner"></div>
            </div>
            <div class="storage-text">Using Local Network</div>
        </div>
    </aside>

    <!-- Main Panel Dashboard Workspace -->
    <main class="workspace">
        <header class="workspace-header">
            <div class="search-bar">
                <i data-lucide="search"></i>
                <input type="text" id="searchInput" placeholder="Search files..." oninput="handleSearch()">
            </div>
            <div class="header-actions">
                <input type="file" id="fileUploadInput" multiple style="display: none;" onchange="handleFilesSelected(event)">
                <button class="round-button" onclick="document.getElementById('fileUploadInput').click()" title="Upload files">
                    <i data-lucide="upload-cloud"></i>
                </button>
                <button class="round-button" onclick="downloadZip()" id="zipBtn" title="Download current folder as ZIP">
                    <i data-lucide="file-archive"></i>
                </button>
                <button class="round-button" onclick="toggleTheme()" id="themeBtn" title="Toggle theme">
                    <i data-lucide="moon"></i>
                </button>
            </div>
        </header>

        <div class="workspace-content">
            <div class="breadcrumb-trail" id="breadcrumbs">
                <!-- Dynamic Path Breadcrumbs -->
            </div>

            <div class="content-header-row">
                <h2 class="content-title" id="dirTitle">All Files</h2>
                <div class="layout-selectors">
                    <button class="layout-btn active" id="listLayoutBtn" onclick="setLayout('list')" title="List view">
                        <i data-lucide="list"></i>
                    </button>
                    <button class="layout-btn" id="gridLayoutBtn" onclick="setLayout('grid')" title="Grid view">
                        <i data-lucide="grid"></i>
                    </button>
                </div>
            </div>

            <!-- List View Wrapper -->
            <div id="listViewWrapper">
                <div class="playlist-header-row">
                    <div class="playlist-index">#</div>
                    <div>Title</div>
                    <div class="playlist-modified">Date Modified</div>
                    <div class="playlist-size">Size</div>
                    <div class="playlist-action-cell"></div>
                </div>
                <div id="listItems">
                    <!-- Loaded dynamically -->
                </div>
            </div>

            <!-- Grid View Wrapper (Hidden initially) -->
            <div id="gridViewWrapper" style="display: none;">
                <div class="spotify-grid" id="gridItems">
                    <!-- Loaded dynamically -->
                </div>
            </div>
        </div>
    </main>

    <!-- Drag Overlay -->
    <div class="drag-overlay" id="dragOverlay">
        <i data-lucide="upload-cloud"></i>
        <h2>Drop files to upload</h2>
    </div>

    <!-- Upload Toast -->
    <div class="upload-toast" id="uploadToast">
        <div class="toast-header">
            <div class="toast-title"><i data-lucide="upload"></i> <span>Uploading...</span></div>
            <span id="uploadPercent" style="font-size: 12px; color: var(--text-muted);">0%</span>
        </div>
        <div class="toast-progress-bar">
            <div class="toast-progress-fill" id="uploadProgressFill"></div>
        </div>
        <div id="uploadFilename" style="font-size: 11px; color: var(--text-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"></div>
    </div>

    <script>
        let currentDir = '';
        let allItems = [];
        let viewMode = 'list';

        // Fix mobile viewport height
        function setVH() {
            const vh = window.innerHeight * 0.01;
            document.documentElement.style.setProperty('--vh', vh + 'px');
        }
        setVH();
        window.addEventListener('resize', setVH);
        window.addEventListener('orientationchange', function() {
            setTimeout(setVH, 100);
        });

        // Load files initially
        loadFiles('');

        // Apply theme preferences
        if (localStorage.getItem('theme') === 'light') {
            document.body.setAttribute('data-theme', 'light');
            updateThemeIcon(true);
        }

        // Initialize Lucide Icons
        setTimeout(() => lucide.createIcons(), 200);

        function toggleTheme() {
            if (document.body.getAttribute('data-theme') === 'light') {
                document.body.removeAttribute('data-theme');
                localStorage.setItem('theme', 'dark');
                updateThemeIcon(false);
            } else {
                document.body.setAttribute('data-theme', 'light');
                localStorage.setItem('theme', 'light');
                updateThemeIcon(true);
            }
        }

        function updateThemeIcon(isLight) {
            const btn = document.getElementById('themeBtn');
            btn.innerHTML = isLight ? '<i data-lucide="sun"></i>' : '<i data-lucide="moon"></i>';
            lucide.createIcons();
        }

        function setLayout(mode) {
            viewMode = mode;
            document.getElementById('listLayoutBtn').classList.toggle('active', mode === 'list');
            document.getElementById('gridLayoutBtn').classList.toggle('active', mode === 'grid');
            
            document.getElementById('listViewWrapper').style.display = mode === 'list' ? 'block' : 'none';
            document.getElementById('gridViewWrapper').style.display = mode === 'grid' ? 'block' : 'none';
            
            renderFiles(allItems);
        }

        async function loadFiles(dir) {
            currentDir = dir;
            const listItems = document.getElementById('listItems');
            const gridItems = document.getElementById('gridItems');
            const loadingHTML = '<div style="grid-column: 1/-1; text-align: center; padding: 40px; color: var(--text-muted);">Loading files...</div>';
            
            listItems.innerHTML = loadingHTML;
            gridItems.innerHTML = loadingHTML;
            document.getElementById('searchInput').value = '';

            try {
                const response = await fetch('/api/files?dir=' + encodeURIComponent(dir));
                const data = await response.json();
                
                if (data.error) {
                    const errHTML = `<div class="empty-view" style="grid-column: 1/-1;">
                        <i data-lucide="alert-circle" style="width: 48px; height: 48px; color: var(--text-muted);"></i>
                        <div>\${data.error}</div>
                    </div>`;
                    listItems.innerHTML = errHTML;
                    gridItems.innerHTML = errHTML;
                    lucide.createIcons();
                    return;
                }

                allItems = data.items || [];
                
                // Update directory title
                const parts = dir.split('/');
                document.getElementById('dirTitle').innerText = parts[parts.length - 1] || 'All Files';

                renderBreadcrumbs(dir);
                renderFiles(allItems);

            } catch (err) {
                const errHTML = `<div class="empty-view" style="grid-column: 1/-1;">
                    <i data-lucide="x-circle" style="width: 48px; height: 48px; color: var(--text-muted);"></i>
                    <div>Failed to load files: \${err.message}</div>
                </div>`;
                listItems.innerHTML = errHTML;
                gridItems.innerHTML = errHTML;
                lucide.createIcons();
            }
        }

        function renderFiles(items) {
            const listItems = document.getElementById('listItems');
            const gridItems = document.getElementById('gridItems');
            
            if (items.length === 0) {
                const emptyHTML = `<div class="empty-view" style="grid-column: 1/-1;">
                    <i data-lucide="folder" style="width: 48px; height: 48px; color: var(--text-muted);"></i>
                    <div>No files found matching criteria</div>
                </div>`;
                listItems.innerHTML = emptyHTML;
                gridItems.innerHTML = emptyHTML;
                lucide.createIcons();
                return;
            }

            if (viewMode === 'list') {
                listItems.innerHTML = '';
                items.forEach((item, index) => {
                    const row = document.createElement('div');
                    row.className = 'playlist-row';
                    
                    const isDir = item.isDirectory;
                    const iconName = getFileIcon(item.extension, isDir);
                    
                    row.innerHTML = `
                        <div class="playlist-index">\${index + 1}</div>
                        <div class="playlist-title-cell">
                            <div class="playlist-icon-box">
                                <i data-lucide="\${iconName}"></i>
                            </div>
                            <div class="playlist-name" title="\${item.name}">\${item.name}</div>
                        </div>
                        <div class="playlist-modified">\${formatDate(item.modified)}</div>
                        <div class="playlist-size">\${isDir ? '--' : formatBytes(item.size)}</div>
                        <div class="playlist-action-cell">
                            \${isDir ? '' : `
                                <a class="playlist-row-btn" href="/download?file=\${encodeURIComponent(item.path)}" onclick="event.stopPropagation()">
                                    <i data-lucide="download"></i>
                                </a>
                            `}
                        </div>
                    `;

                    if (isDir) {
                        row.onclick = () => navigateTo(item.path);
                    }
                    listItems.appendChild(row);
                });
            } else {
                gridItems.innerHTML = '';
                items.forEach(item => {
                    const card = document.createElement('div');
                    card.className = 'spotify-card';
                    
                    const isDir = item.isDirectory;
                    const iconName = getFileIcon(item.extension, isDir);
                    
                    card.innerHTML = `
                        <div class="spotify-card-icon">
                            <i data-lucide="\${iconName}" style="width: 48px; height: 48px;"></i>
                        </div>
                        <div class="spotify-card-info">
                            <div class="spotify-card-name" title="\${item.name}">\${item.name}</div>
                            <div class="spotify-card-meta">\${isDir ? 'Folder' : formatBytes(item.size)}</div>
                        </div>
                        \${isDir ? '' : `
                            <a class="spotify-card-play-btn" href="/download?file=\${encodeURIComponent(item.path)}" onclick="event.stopPropagation()">
                                <i data-lucide="download"></i>
                            </a>
                        `}
                    `;

                    if (isDir) {
                        card.onclick = () => navigateTo(item.path);
                    }
                    gridItems.appendChild(card);
                });
            }

            // Bind/Render Icons
            lucide.createIcons();
        }

        function handleSearch() {
            const query = document.getElementById('searchInput').value.toLowerCase();
            const filtered = allItems.filter(item => item.name.toLowerCase().includes(query));
            renderFiles(filtered);
        }

        function navigateTo(path) {
            loadFiles(path);
        }

        function downloadZip() {
            if (currentDir === '') {
                alert('Please navigate into a folder first.');
                return;
            }
            window.location.href = '/download-zip?dir=' + encodeURIComponent(currentDir);
        }

        function renderBreadcrumbs(dir) {
            const container = document.getElementById('breadcrumbs');
            container.innerHTML = '<span class="breadcrumb-pill" onclick="navigateTo(&apos;&apos;)">Root</span>';

            if (!dir) return;

            const parts = dir.split('/');
            let accumulatedPath = '';
            
            parts.forEach((part, index) => {
                if (!part) return;
                accumulatedPath += (accumulatedPath ? '/' : '') + part;
                
                const divider = document.createElement('span');
                divider.className = 'breadcrumb-divider';
                divider.innerHTML = '<i data-lucide="chevron-right" style="width: 12px; height: 12px;"></i>';
                container.appendChild(divider);

                const item = document.createElement('span');
                item.className = 'breadcrumb-pill';
                
                if (index === parts.length - 1) {
                    item.className += ' active';
                    item.innerText = part;
                } else {
                    const currentPath = accumulatedPath;
                    item.onclick = () => navigateTo(currentPath);
                    item.innerText = part;
                }
                
                container.appendChild(item);
            });
            lucide.createIcons();
        }

        function getFileIcon(ext, isDir) {
            if (isDir) return 'folder';
            if (!ext) return 'file';
            ext = ext.toUpperCase();
            if (['JPG', 'PNG', 'WEBP', 'GIF', 'JPEG'].includes(ext)) return 'image';
            if (['MP4', 'MKV', 'MOV', 'AVI'].includes(ext)) return 'video';
            if (['PDF', 'DOC', 'TXT', 'DOCX', 'XLS', 'PPT'].includes(ext)) return 'file-text';
            if (['ZIP', 'RAR', '7Z', 'TAR', 'GZ'].includes(ext)) return 'archive';
            if (['MP3', 'WAV', 'M4A', 'FLAC'].includes(ext)) return 'music';
            return 'file';
        }

        function formatBytes(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
        }

        function formatDate(isoString) {
            if (!isoString) return '--';
            const d = new Date(isoString);
            return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
        }

        function handleFilesSelected(event) {
            const files = event.target.files;
            if (files.length === 0) return;
            uploadFiles(files);
            event.target.value = ''; // reset
        }

        async function uploadFiles(files) {
            const toast = document.getElementById('uploadToast');
            const progressFill = document.getElementById('uploadProgressFill');
            const percentText = document.getElementById('uploadPercent');
            const filenameText = document.getElementById('uploadFilename');
            
            toast.classList.add('show');
            
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                filenameText.innerText = `(\${i+1}/\${files.length}) \${file.name}`;
                progressFill.style.width = '0%';
                percentText.innerText = '0%';
                
                try {
                    await new Promise((resolve, reject) => {
                        const xhr = new XMLHttpRequest();
                        xhr.open('POST', `/upload?dir=\${encodeURIComponent(currentDir)}&filename=\${encodeURIComponent(file.name)}`);
                        
                        xhr.upload.onprogress = (e) => {
                            if (e.lengthComputable) {
                                const percent = Math.round((e.loaded / e.total) * 100);
                                progressFill.style.width = percent + '%';
                                percentText.innerText = percent + '%';
                            }
                        };
                        
                        xhr.onload = () => {
                            if (xhr.status === 200) resolve();
                            else reject(xhr.responseText);
                        };
                        
                        xhr.onerror = () => reject("Network Error");
                        xhr.send(file);
                    });
                } catch (e) {
                    console.error("Upload failed for " + file.name, e);
                }
            }
            
            filenameText.innerText = "Upload Complete!";
            setTimeout(() => {
                toast.classList.remove('show');
                loadFiles(currentDir);
            }, 2000);
        }

        // Drag and drop support
        const dragOverlay = document.getElementById('dragOverlay');
        let dragCounter = 0;

        window.addEventListener('dragenter', (e) => {
            e.preventDefault();
            dragCounter++;
            dragOverlay.classList.add('active');
        });

        window.addEventListener('dragleave', (e) => {
            e.preventDefault();
            dragCounter--;
            if (dragCounter === 0) {
                dragOverlay.classList.remove('active');
            }
        });

        window.addEventListener('dragover', (e) => {
            e.preventDefault();
        });

        window.addEventListener('drop', (e) => {
            e.preventDefault();
            dragCounter = 0;
            dragOverlay.classList.remove('active');
            
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                uploadFiles(files);
            }
        });
    </script>
</body>
</html>
''';
  }
}
