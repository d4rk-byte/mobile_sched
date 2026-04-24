import 'package:flutter/material.dart';

import '../app/configs/theme.dart';

/// A compact status indicator pill with tinted background and bold label.
/// Replaces inline status badge implementations across dashboard, schedule,
/// and notification screens.
///
/// Usage:
/// ```dart
/// StatusPill(
///   label: 'In Progress',
///   color: AppColors.success,
/// )
///
/// StatusPill.fromStatus(ScheduleTimeStatus.upcoming)
/// ```
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// The status label text (e.g. "In Progress", "Upcoming", "Completed").
  final String label;

  /// The accent color used for text and a 14% opacity tinted background.
  final Color color;

  /// Optional leading icon (shown at 12px before the label).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1, // 5px
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
