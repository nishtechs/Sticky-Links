import 'dart:math';
import 'package:flutter/material.dart';

class DynamicBackground extends StatefulWidget {
  final Widget child;
  final bool isEnabled;
  final Color seedColor;

  const DynamicBackground({
    super.key,
    required this.child,
    this.isEnabled = true,
    required this.seedColor,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return widget.child;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: MeshPainter(
                progress: _controller.value,
                color: widget.seedColor,
                isDark: Theme.of(context).brightness == Brightness.dark,
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
  final Color color;
  final bool isDark;

  MeshPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final List<Color> colors = [
      color.withValues(alpha: isDark ? 0.3 : 0.2),
      color.withValues(alpha: isDark ? 0.2 : 0.1),
      Colors.blue.withValues(alpha: isDark ? 0.15 : 0.1),
      Colors.purple.withValues(alpha: isDark ? 0.15 : 0.1),
    ];

    for (int i = 0; i < 4; i++) {
      final double angle = (progress * 2 * pi) + (i * pi / 2);
      final double x = size.width / 2 + cos(angle) * size.width * 0.4;
      final double y = size.height / 2 + sin(angle * 1.5) * size.height * 0.4;

      paint.color = colors[i];
      canvas.drawCircle(Offset(x, y), 200 + sin(progress * pi) * 100, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
