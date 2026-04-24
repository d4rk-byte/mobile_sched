// lib/widgets/loading_skeleton.dart

import 'package:flutter/material.dart';
import '../utils/theme.dart';

class LoadingSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height = 20,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.slow,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.65),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor.withValues(alpha: 0.82),
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }
}
