import 'package:flutter/material.dart';

import '../app/configs/theme.dart';

/// A white card with soft shadow, consistent padding, and an optional left
/// accent border. Designed to be the single card primitive for the entire app.
///
/// Usage:
/// ```dart
/// ElegantCard(
///   accentColor: AppColors.success,
///   child: Text('Hello'),
/// )
/// ```
class ElegantCard extends StatelessWidget {
  const ElegantCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.onTap,
    this.elevated = false,
  });

  /// The card content.
  final Widget child;

  /// Optional left-edge accent color (3.5 px wide).
  /// Great for status indication (green = active, blue = upcoming, etc.).
  final Color? accentColor;

  /// Content padding — defaults to `AppSpacing.lg` (16) on all sides.
  final EdgeInsetsGeometry? padding;

  /// If provided, the card becomes tappable with an ink ripple.
  final VoidCallback? onTap;

  /// Use `true` for cards that need slightly more visual weight
  /// (e.g. expanded detail cards or active states).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.all(AppSpacing.lg);

    final hasAccent = accentColor != null;

    final decoration = BoxDecoration(
      color: AppColors.cardSurface,
      borderRadius: hasAccent
          ? const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
              topRight: Radius.circular(AppRadius.lg),
              bottomRight: Radius.circular(AppRadius.lg),
            )
          : BorderRadius.circular(AppRadius.lg),
      border: hasAccent
          ? Border(
              left: BorderSide(color: accentColor!, width: 3.5),
              top: BorderSide(color: AppColors.cardBorder),
              right: BorderSide(color: AppColors.cardBorder),
              bottom: BorderSide(color: AppColors.cardBorder),
            )
          : Border.all(color: AppColors.cardBorder),
      boxShadow: elevated ? AppShadow.cardElevated : AppShadow.card,
    );

    final content = Container(
      decoration: decoration,
      padding: effectivePadding,
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
