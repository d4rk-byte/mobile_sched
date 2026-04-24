import 'package:flutter/material.dart';

import '../app/configs/theme.dart';
import 'shimmer_skeleton.dart';

/// Full-page shimmer skeleton for the Dashboard screen loading state.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        28,
      ),
      children: [
        // Hero banner skeleton
        const ShimmerSkeleton(
          width: double.infinity,
          height: 116,
          borderRadius: AppRadius.xl,
        ),
        const SizedBox(height: 18),
        // 2x2 insight grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: const [
            ShimmerSkeleton(width: double.infinity, height: double.infinity, borderRadius: AppRadius.md),
            ShimmerSkeleton(width: double.infinity, height: double.infinity, borderRadius: AppRadius.md),
            ShimmerSkeleton(width: double.infinity, height: double.infinity, borderRadius: AppRadius.md),
            ShimmerSkeleton(width: double.infinity, height: double.infinity, borderRadius: AppRadius.md),
          ],
        ),
        const SizedBox(height: 24),
        // Section header skeleton
        Row(
          children: const [
            ShimmerSkeleton(width: 140, height: 18),
            Spacer(),
            ShimmerSkeleton(width: 64, height: 18),
          ],
        ),
        const SizedBox(height: 12),
        // 3 schedule card skeletons
        const ShimmerSkeleton(width: double.infinity, height: 82, borderRadius: AppRadius.lg),
        const SizedBox(height: 12),
        const ShimmerSkeleton(width: double.infinity, height: 82, borderRadius: AppRadius.lg),
        const SizedBox(height: 12),
        const ShimmerSkeleton(width: double.infinity, height: 82, borderRadius: AppRadius.lg),
      ],
    );
  }
}

/// Full-page shimmer skeleton for the Schedule screen loading state.
class ScheduleShimmer extends StatelessWidget {
  const ScheduleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        28,
      ),
      children: [
        // Overview card skeleton
        const ShimmerSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: AppRadius.xl,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Section header
        Row(
          children: const [
            ShimmerSkeleton(width: 100, height: 18),
            Spacer(),
            ShimmerSkeleton(width: 72, height: 18),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < 4; i++) ...[
          const ShimmerSkeleton(width: double.infinity, height: 110, borderRadius: AppRadius.lg),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Full-page shimmer skeleton for the Notifications screen loading state.
class NotificationsShimmer extends StatelessWidget {
  const NotificationsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        // Summary card
        const ShimmerSkeleton(
          width: double.infinity,
          height: 108,
          borderRadius: AppRadius.xl,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (int i = 0; i < 5; i++) ...[
          _NotificationCardSkeleton(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _NotificationCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerSkeleton(width: 40, height: 40, borderRadius: AppRadius.sm),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 8),
                ShimmerSkeleton(width: double.infinity, height: 10),
                SizedBox(height: 4),
                ShimmerSkeleton(width: 180, height: 10),
                SizedBox(height: 8),
                ShimmerSkeleton(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
