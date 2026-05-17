import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:quick_wifi_share/widgets/glass_container.dart';

class MediaPreviewScreen extends StatelessWidget {
  final String filePath;

  const MediaPreviewScreen({
    super.key,
    required this.filePath,
  });

  String _getFileExtension() {
    return p.extension(filePath).replaceAll('.', '').toUpperCase();
  }

  String _getFileName() {
    return p.basename(filePath);
  }

  bool _isImage(String ext) {
    return ['JPG', 'JPEG', 'PNG', 'WEBP', 'GIF', 'BMP'].contains(ext.toUpperCase());
  }

  bool _isText(String ext) {
    return ['TXT', 'LOG', 'XML', 'JSON', 'MD', 'HTML', 'CSS', 'JS', 'DART', 'YAML', 'SH', 'PY'].contains(ext.toUpperCase());
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String ext = _getFileExtension();
    final String fileName = _getFileName();

    return Theme(
      // Keep a beautiful premium dark theme for media previews
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF005EB8),
          secondary: Color(0xFF007FFF),
          surface: Color(0xFF161925),
          onSurface: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            fileName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0F111A).withValues(alpha: 0.8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isText(ext))
              IconButton(
                icon: const Icon(Icons.copy_all_rounded),
                tooltip: 'Copy all text',
                onPressed: () async {
                  try {
                    final text = await File(filePath).readAsString();
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Content copied to clipboard!'),
                          backgroundColor: Color(0xFF005EB8),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to copy content'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: 'File details',
              onPressed: () => _showDetailsSheet(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPreviewBody(context, ext),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBody(BuildContext context, String ext) {
    if (_isImage(ext)) {
      return _buildImagePreview();
    } else if (_isText(ext)) {
      return _buildTextPreview(context);
    } else {
      return _buildGenericPreview(context, ext);
    }
  }

  Widget _buildImagePreview() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          maxScale: 5.0,
          minScale: 0.8,
          child: Image.file(
            File(filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded, size: 64, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text('Failed to load image preview'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextPreview(BuildContext context) {
    return FutureBuilder<String>(
      future: File(filePath).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildGenericPreview(context, _getFileExtension(), errorText: 'Cannot read file as text (possible binary data)');
        }

        final text = snapshot.data!;
        if (text.trim().isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('This file is empty', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161925),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          padding: const EdgeInsets.all(16),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Text(
                  text,
                  style: GoogleFonts.firaCode(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenericPreview(BuildContext context, String ext, {String? errorText}) {
    Color iconColor = Colors.grey;
    IconData iconData = Icons.insert_drive_file_rounded;

    if (['MP4', 'MKV', 'MOV'].contains(ext)) {
      iconColor = Colors.purpleAccent;
      iconData = Icons.video_library_rounded;
    } else if (['PDF'].contains(ext)) {
      iconColor = Colors.redAccent;
      iconData = Icons.picture_as_pdf_rounded;
    } else if (['ZIP', 'RAR', '7Z'].contains(ext)) {
      iconColor = Colors.amberAccent;
      iconData = Icons.archive_rounded;
    } else if (['MP3', 'WAV', 'M4A', 'FLAC'].contains(ext)) {
      iconColor = Colors.tealAccent;
      iconData = Icons.audiotrack_rounded;
    }

    FileStat stat;
    try {
      stat = File(filePath).statSync();
    } catch (_) {
      return const Center(child: Text('Failed to read file info'));
    }

    return Center(
      child: SingleChildScrollView(
        child: GlassContainer(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          borderRadius: BorderRadius.circular(24),
          blur: 20,
          opacity: 0.07,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                errorText ?? 'Preview is not available for this file type',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(color: Colors.white12),
              const SizedBox(height: 20),
              _buildDetailRow(context, 'Name', _getFileName()),
              _buildDetailRow(context, 'Type', ext.isEmpty ? 'Unknown' : '$ext File'),
              _buildDetailRow(context, 'Size', _formatBytes(stat.size)),
              _buildDetailRow(context, 'Last Modified', _formatDate(stat.modified)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: filePath));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Absolute path copied!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFF005EB8),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Path', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005EB8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    FileStat stat;
    try {
      stat = File(filePath).statSync();
    } catch (_) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF007FFF)),
                  const SizedBox(width: 12),
                  Text(
                    'File Specifications',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Filename', _getFileName()),
              _buildDetailRow(context, 'Format', _getFileExtension()),
              _buildDetailRow(context, 'Size', _formatBytes(stat.size)),
              _buildDetailRow(context, 'Location', filePath),
              _buildDetailRow(context, 'Modified', _formatDate(stat.modified)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005EB8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
