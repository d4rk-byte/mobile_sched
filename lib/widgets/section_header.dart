import 'package:flutter/material.dart';

import '../app/configs/theme.dart';

/// A section title row with an optional trailing count badge.
/// Provides consistent heading style across all screens.
///
/// Usage:
/// ```dart
/// SectionHeader(
///   title: "Today's Schedule",
///   count: 3,
///   countLabel: 'items',
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.countLabel,
    this.trailing,
  });

  /// The section heading text.
  final String title;

  /// Optional item count shown in a pill badge (e.g. "3 items").
  final int? count;

  /// Label appended to count (e.g. "items", "classes"). Defaults to "items".
  final String? countLabel;

  /// Optional custom trailing widget. If [count] is also provided,
  /// [trailing] takes priority and the count badge is not shown.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2, // 6px
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count ${countLabel ?? 'items'}',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
      ],
    );
  }
}
