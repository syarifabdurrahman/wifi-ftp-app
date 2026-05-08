import 'package:flutter/material.dart';

class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool isRunning;

  const PulseAnimation({
    super.key,
    required this.child,
    required this.color,
    required this.isRunning,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isRunning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isRunning && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use a fixed-size Stack wrapped in a SizedBox to prevent layout shifting.
    // The pulse effect happens "under" the child without resizing the parent container.
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Allow the pulse to go slightly outside if needed
        children: [
          if (widget.isRunning)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return Opacity(
                  opacity: (1.4 - _animation.value).clamp(0.0, 1.0),
                  child: Container(
                    width: 160 * _animation.value,
                    height: 160 * _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          if (widget.isRunning)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                // Secondary pulse with delay/different scale
                final secondaryScale = ((_animation.value - 1.0) * 0.8) + 1.0;
                return Opacity(
                  opacity: (1.2 - secondaryScale).clamp(0.0, 1.0),
                  child: Container(
                    width: 160 * secondaryScale,
                    height: 160 * secondaryScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.2),
                    ),
                  ),
                );
              },
            ),
          // The actual button (child) stays at the center and doesn't move
          widget.child,
        ],
      ),
    );
  }
}
