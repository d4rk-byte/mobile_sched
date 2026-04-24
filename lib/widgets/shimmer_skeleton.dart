import 'package:flutter/material.dart';

import '../app/configs/theme.dart';

/// A premium shimmer loading skeleton that replaces plain
/// `CircularProgressIndicator` for a more elegant loading experience.
///
/// The shimmer animates a highlight gradient across the skeleton shape,
/// creating a polished "content is loading" effect.
///
/// Usage:
/// ```dart
/// // Single line skeleton
/// ShimmerSkeleton(width: 120, height: 14)
///
/// // Card-shaped skeleton
/// ShimmerSkeleton(width: double.infinity, height: 80, borderRadius: AppRadius.lg)
///
/// // Circular avatar skeleton
/// ShimmerSkeleton.circle(size: 48)
/// ```
class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  /// Creates a circular shimmer skeleton (e.g. for avatars).
  const ShimmerSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 999;

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion = (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A pre-built loading skeleton that mimics a typical content card layout.
/// Use this in place of `CircularProgressIndicator()` for list-based screens.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.count = 3});

  /// Number of skeleton cards to show.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerSkeleton(
                      width: MediaQuery.sizeOf(context).width * 0.45,
                      height: 16,
                    ),
                    const Spacer(),
                    const ShimmerSkeleton(width: 64, height: 22,
                        borderRadius: AppRadius.pill),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const ShimmerSkeleton(width: double.infinity, height: 12),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerSkeleton(width: 180, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
