import 'package:flutter/material.dart';

import '../theme/yamada_theme.dart';

/// Activity heatmap — GitHub-style, 26 weeks of daily activity.
class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, double> data;

  const ActivityHeatmap({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Generate 26 weeks × 7 days = 182 cells
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return LayoutBuilder(
      builder: (context, constraints) {
        const weeks = 26;
        const days = 7;
        final cellSize =
            ((constraints.maxWidth - (weeks - 1) * 2) / weeks).floorToDouble();
        final limitedCellSize = cellSize.clamp(8.0, 16.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day-of-week labels
                Column(
                  children: ['M', '', 'W', '', 'F', '', 'S']
                      .map((label) => SizedBox(
                            height: limitedCellSize + 2,
                            width: 16,
                            child: label.isNotEmpty
                                ? Text(label,
                                    style: YamadaTheme.caption.copyWith(
                                        fontSize: 9,
                                        color: YamadaTheme.inkSubtle))
                                : const SizedBox(),
                          ))
                      .toList(),
                ),
                // Grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(weeks, (weekIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Column(
                            children: List.generate(days, (dayIndex) {
                              final dayOffset =
                                  (weeks - 1 - weekIndex) * 7 +
                                      (6 - dayIndex);
                              final date =
                                  today.subtract(Duration(days: dayOffset));

                              // Look up live data or fallback to 0
                              final dateKey = DateTime(date.year, date.month, date.day);
                              final intensity = data[dateKey] ?? 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Container(
                                  width: limitedCellSize,
                                  height: limitedCellSize,
                                  decoration: BoxDecoration(
                                    color: _getColor(intensity),
                                    border: Border.all(
                                      color: YamadaTheme.ink
                                          .withValues(alpha: 0.15),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  Color _getColor(double intensity) {
    if (intensity <= 0) return YamadaTheme.ink.withValues(alpha: 0.05);
    if (intensity < 0.25) return YamadaTheme.ink.withValues(alpha: 0.15);
    if (intensity < 0.50) return YamadaTheme.ink.withValues(alpha: 0.30);
    if (intensity < 0.75) return YamadaTheme.ink.withValues(alpha: 0.55);
    return YamadaTheme.ink.withValues(alpha: 0.85);
  }
}
