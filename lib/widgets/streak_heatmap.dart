import 'package:flutter/material.dart';
import 'package:positive_phill/theme.dart';

class StreakHeatmap extends StatelessWidget {
  final List<String> completedDates; // yyyy-MM-dd strings
  final DateTime? referenceDate; // defaults to today if null

  const StreakHeatmap({
    super.key,
    required this.completedDates,
    this.referenceDate,
  });

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = referenceDate ?? DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final completedSet = Set<String>.from(completedDates);
    final todayKey = _dateKey(today);
    final firstWeekday = monthStart.weekday % 7; // Sun=0..Sat=6

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header (wraps gracefully on narrow widths) ─────────────────
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              const Text('📅', style: TextStyle(fontSize: 14)),
              Text(
                '${_monthNames[today.month - 1]} ${today.year}',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '· Daily session log',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Calendar (compact, centered, max width) ────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  // Weekday labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekdayLabels
                        .map(
                          (d) => SizedBox(
                            width: 22,
                            child: Center(
                              child: Text(
                                d,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                      childAspectRatio: 1,
                    ),
                    itemCount: firstWeekday + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday) {
                        return const SizedBox.shrink();
                      }
                      final day = index - firstWeekday + 1;
                      final date = DateTime(today.year, today.month, day);
                      final key = _dateKey(date);
                      final isToday = key == todayKey;
                      final isCompleted = completedSet.contains(key);
                      final isFuture = date.isAfter(today);

                      Color bgColor;
                      Color borderColor = Colors.transparent;
                      double borderWidth = 0;
                      List<BoxShadow>? shadows;

                      if (isCompleted) {
                        bgColor = colorScheme.primary;
                        shadows = [
                          BoxShadow(
                            color: colorScheme.primary
                                .withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ];
                      } else if (isToday) {
                        bgColor = colorScheme.primaryContainer
                            .withValues(alpha: 0.5);
                        borderColor = colorScheme.primary;
                        borderWidth = 2.5;
                      } else if (isFuture) {
                        bgColor = colorScheme.onSurface
                            .withValues(alpha: 0.04);
                      } else {
                        bgColor = colorScheme.onSurface
                            .withValues(alpha: 0.05);
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                          boxShadow: shadows,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: isCompleted
                                  ? colorScheme.onPrimary
                                  : isToday
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                              fontWeight: isToday || isCompleted
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Legend ─────────────────────────────────────────────────────
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendDot(color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Complete',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _LegendDot(
                  color: Colors.transparent,
                  borderColor: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Today',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color? borderColor;

  const _LegendDot({required this.color, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
        ),
      );
}
