import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedMeshBackground extends StatefulWidget {
  final Widget child;
  const AnimatedMeshBackground({super.key, required this.child});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: MeshPainter(
                progress: _controller.value,
                isDark: isDark,
                primaryColor: Theme.of(context).colorScheme.primary,
                secondaryColor: Theme.of(context).colorScheme.secondary,
              ),
              child: Container(),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class MeshPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;

  MeshPainter({
    required this.progress,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Background base
    paint.color = isDark ? const Color(0xFF111318) : const Color(0xFFF9F9FF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle Blobs
    void drawBlob(Offset center, double radius, Color color) {
      final gradient = RadialGradient(
        colors: [
          color.withOpacity(isDark ? 0.15 : 0.08),
          color.withOpacity(0),
        ],
      );
      paint.shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final double t = progress * 2 * pi;
    
    // Blob 1
    final center1 = Offset(
      size.width * (0.5 + 0.3 * cos(t)),
      size.height * (0.3 + 0.2 * sin(t * 0.5)),
    );
    drawBlob(center1, size.width * 0.8, primaryColor);

    // Blob 2
    final center2 = Offset(
      size.width * (0.2 + 0.2 * sin(t * 0.7)),
      size.height * (0.7 + 0.3 * cos(t * 0.3)),
    );
    drawBlob(center2, size.width * 0.6, secondaryColor);

    // Blob 3
    final center3 = Offset(
      size.width * (0.8 + 0.1 * cos(t * 1.2)),
      size.height * (0.5 + 0.4 * sin(t * 0.8)),
    );
    drawBlob(center3, size.width * 0.7, primaryColor.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) => true;
}
