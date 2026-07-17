import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class AnimatedNebulaBackground extends StatefulWidget {
  final double opacity;

  const AnimatedNebulaBackground({
    super.key,
    this.opacity = 1.0,
  });

  @override
  State<AnimatedNebulaBackground> createState() => _AnimatedNebulaBackgroundState();
}

class _AnimatedNebulaBackgroundState extends State<AnimatedNebulaBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: widget.opacity,
          child: CustomPaint(
            painter: NebulaPainter(progress: _controller.value),
          ),
        );
      },
    );
  }
}

class NebulaPainter extends CustomPainter {
  final double progress;

  NebulaPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid dark background color #0b1323
    final basePaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, basePaint);

    // 2. Draw subtle moving blue radial gradient glow
    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.3 + (size.width * 0.15 * math.sin(progress * 2 * math.pi)),
            size.height * 0.4 + (size.height * 0.15 * math.cos(progress * 2 * math.pi)),
          ),
          radius: size.width * 0.75,
        ),
      );
    canvas.drawRect(Offset.zero & size, bluePaint);

    // 3. Draw subtle moving AI purple radial gradient glow
    final purplePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C4DFF).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.7 - (size.width * 0.12 * math.sin(progress * 2 * math.pi)),
            size.height * 0.6 - (size.height * 0.12 * math.cos(progress * 2 * math.pi)),
          ),
          radius: size.width * 0.65,
        ),
      );
    canvas.drawRect(Offset.zero & size, purplePaint);
  }

  @override
  bool shouldRepaint(covariant NebulaPainter oldDelegate) => true;
}
