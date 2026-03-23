import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/yamada_theme.dart';

/// Identity score with animated progress ring and count-up number.
class IdentityScoreWidget extends StatelessWidget {
  final double score;

  const IdentityScoreWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: YamadaTheme.hardBorder,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 100,
            height: 100,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 10),
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    strokeWidth: 6,
                    backgroundColor: YamadaTheme.inkGhost,
                    progressColor: YamadaTheme.ink,
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: YamadaTheme.dataLarge,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IDENTITY SCORE', style: YamadaTheme.sectionLabel),
                const SizedBox(height: 4),
                Text('OUT OF 10',
                    style: YamadaTheme.caption
                        .copyWith(color: YamadaTheme.inkSubtle)),
                const SizedBox(height: 8),
                Text(
                  _getScoreLabel(score),
                  style: YamadaTheme.dataMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 9.0) return 'UNSTOPPABLE';
    if (score >= 7.5) return 'LOCKED IN';
    if (score >= 6.0) return 'ON TRACK';
    if (score >= 4.0) return 'WARMING UP';
    if (score >= 2.0) return 'FALLING BEHIND';
    return 'WAKE UP';
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}
