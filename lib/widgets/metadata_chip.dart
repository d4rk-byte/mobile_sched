import 'package:flutter/material.dart';

import '../app/configs/theme.dart';

/// A small icon + text chip for displaying metadata like time, room, day
/// pattern, or student count. Replaces the multiple inline chip widgets
/// (`_ScheduleMetaChip`, `_HeroPill`, `_OverviewPill`, `_NotificationPill`).
///
/// Two visual variants:
/// - **surface** (default) — tinted background on a card
/// - **onGradient** — white-on-transparent for use on gradient hero cards
///
/// Usage:
/// ```dart
/// MetadataChip(
///   icon: Icons.schedule_rounded,
///   text: '8:00 AM - 9:30 AM',
/// )
///
/// MetadataChip.onGradient(
///   icon: Icons.today_outlined,
///   text: 'Monday, Apr 23',
/// )
/// ```
class MetadataChip extends StatelessWidget {
  const MetadataChip({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  /// Factory for chips shown on top of gradient hero cards.
  const MetadataChip.onGradient({
    super.key,
    required this.icon,
    required this.text,
  })  : iconColor = Colors.white,
        textColor = Colors.white,
        backgroundColor = const Color(0x29FFFFFF), // 16% white
        borderColor = null;

  final IconData icon;
  final String text;

  /// Defaults to `AppColors.textSecondary`.
  final Color? iconColor;

  /// Defaults to `AppColors.textSecondary`.
  final Color? textColor;

  /// Defaults to `AppColors.cardChipSurface`.
  final Color? backgroundColor;

  /// Optional border — omitted by default for a cleaner look.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effectiveIconColor = iconColor ?? AppColors.textSecondary;
    final effectiveTextColor = textColor ?? AppColors.textSecondary;
    final effectiveBgColor = backgroundColor ?? AppColors.cardChipSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - 1,
      ),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveIconColor),
          const SizedBox(width: AppSpacing.sm - 2),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: effectiveTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
