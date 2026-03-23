import 'package:flutter/material.dart';

import '../theme/yamada_theme.dart';

/// Stats row: Level badge, Streak counter, Total XP — all count-up animated.
class StatsRow extends StatelessWidget {
  final int level;
  final int streak;
  final int totalXp;

  const StatsRow({
    super.key,
    required this.level,
    required this.streak,
    required this.totalXp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Level badge
        Expanded(child: _StatCard(label: 'LEVEL', value: level, suffix: '')),
        const SizedBox(width: 12),
        // Streak
        Expanded(
            child: _StatCard(
                label: 'STREAK', value: streak, suffix: ' DAYS')),
        const SizedBox(width: 12),
        // Total XP
        Expanded(
            child: _StatCard(label: 'TOTAL XP', value: totalXp, suffix: '')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final String suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: YamadaTheme.hardBorder,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: YamadaTheme.caption),
          const SizedBox(height: 4),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Text(
                '$animValue$suffix',
                style: YamadaTheme.dataLarge,
              );
            },
          ),
        ],
      ),
    );
  }
}
