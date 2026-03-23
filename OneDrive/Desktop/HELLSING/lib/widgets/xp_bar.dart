import 'package:flutter/material.dart';
import '../theme/yamada_theme.dart';

/// Animated XP progress bar with count-up effect.
class XpBar extends StatelessWidget {
  final double progress;
  final int currentXp;
  final int nextLevelXp;

  const XpBar({
    super.key,
    required this.progress,
    required this.currentXp,
    required this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // XP numbers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: currentXp),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Text('$value XP', style: YamadaTheme.dataMedium);
              },
            ),
            Text('$nextLevelXp XP',
                style: YamadaTheme.caption
                    .copyWith(color: YamadaTheme.inkSubtle)),
          ],
        ),
        const SizedBox(height: 8),
        // Bar
        Container(
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: YamadaTheme.ink, width: 2),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(color: YamadaTheme.ink),
              );
            },
          ),
        ),
      ],
    );
  }
}
