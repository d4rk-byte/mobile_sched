import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/class_notification_provider.dart';
import '../utils/theme.dart';
import '../widgets/elegant_card.dart';
import '../widgets/metadata_chip.dart';
import '../widgets/screen_shimmer.dart';
import '../widgets/section_header.dart';
import '../widgets/staggered_list.dart';
import '../widgets/status_pill.dart';

const _kDashboardListBottomPadding = 28.0;
const _kDashboardSectionSpacing = 18.0;
const _kDashboardGridSpacing = 10.0;
const _kDashboardLargeGap = 24.0;
const _kDashboardCardPadding = 14.0;
const _kDashboardTinyGap = 2.0;
const _kDashboardCompactGap = AppSpacing.sm - 2;
const _kDashboardPillVerticalPadding = AppSpacing.sm - 1;
const _kDashboardStatusPillVerticalPadding = AppSpacing.sm - 3;

/// Sorts schedules by status: In Progress first, then Upcoming, then Completed
List<ScheduleItem> _sortSchedulesByStatus(List<ScheduleItem> schedules) {
  final sorted = List<ScheduleItem>.from(schedules);
  sorted.sort((a, b) {
    final aStatus = a.timeStatus;
    final bStatus = b.timeStatus;

    // Priority: inProgress (0) > upcoming (1) > completed (2)
    int getPriority(ScheduleTimeStatus status) {
      switch (status) {
        case ScheduleTimeStatus.inProgress:
          return 0;
        case ScheduleTimeStatus.upcoming:
          return 1;
        case ScheduleTimeStatus.completed:
          return 2;
      }
    }

    return getPriority(aStatus).compareTo(getPriority(bStatus));
  });
  return sorted;
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    await ref.read(dashboardProvider.future);
  }

  void _scheduleNotificationsForClasses(List<ScheduleItem> schedules) {
    final notificationService = ref.read(classNotificationServiceProvider);
    notificationService.scheduleClassNotifications(schedules);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;
    final textTheme = Theme.of(context).textTheme;

    final fallbackName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim().split(' ').first
        : 'Professor';
    final firstName = user?.firstName?.trim().isNotEmpty == true
        ? user!.firstName!.trim()
        : fallbackName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: dashboardAsync.when(
        data: (dashboard) {
          // Schedule notifications for today's upcoming classes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scheduleNotificationsForClasses(dashboard.todaySchedules);
          });

          return RefreshIndicator(
            onRefresh: () => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                _kDashboardListBottomPadding,
              ),
              children: [
                StaggeredList(
                  children: [
                    _HeroBanner(
                      firstName: firstName,
                      period: dashboard.academicYear != null
                          ? '${dashboard.academicYear!.year} • ${dashboard.academicYear!.semester} Semester'
                          : 'No active academic period',
                      dateLabel: dashboard.today.trim().isNotEmpty
                          ? dashboard.today
                          : 'Today',
                      todayCount: dashboard.stats.todayCount,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: _kDashboardSectionSpacing),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        mainAxisSpacing: _kDashboardGridSpacing,
                        crossAxisSpacing: _kDashboardGridSpacing,
                        children: [
                          _InsightCard(
                            label: 'Teaching Hours',
                            value: dashboard.stats.totalHours.toStringAsFixed(1),
                            helper: 'Weekly load',
                            icon: Icons.timer_outlined,
                            color: const Color(0xFF3B82F6),
                          ),
                          _InsightCard(
                            label: 'Active Classes',
                            value: '${dashboard.stats.activeClasses}',
                            helper: 'Current term',
                            icon: Icons.menu_book_outlined,
                            color: const Color(0xFF0EA5A5),
                          ),
                          _InsightCard(
                            label: 'Total Students',
                            value: '${dashboard.stats.totalStudents}',
                            helper: 'Across classes',
                            icon: Icons.groups_2_outlined,
                            color: const Color(0xFFF97316),
                          ),
                          _InsightCard(
                            label: "Today's Classes",
                            value: '${dashboard.stats.todayCount}',
                            helper: 'Schedule today',
                            icon: Icons.calendar_today_outlined,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: _kDashboardLargeGap),
                      child: SectionHeader(
                        title: "Today's Schedule",
                        count: dashboard.todaySchedules.length,
                        countLabel: 'items',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (dashboard.todaySchedules.isEmpty)
                  const _EmptyScheduleCard()
                else ...[
                  for (int i = 0; i < dashboard.todaySchedules.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: StaggeredItem(
                        index: i + 3,
                        child: _DashboardScheduleCard(
                          schedule: _sortSchedulesByStatus(
                              dashboard.todaySchedules)[i],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
        loading: () => const DashboardShimmer(),
        error: (error, stackTrace) => _DashboardErrorState(
          message: error.toString(),
          onRetry: () => _refresh(),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String firstName;
  final String period;
  final String dateLabel;
  final int todayCount;

  const _HeroBanner({
    required this.firstName,
    required this.period,
    required this.dateLabel,
    required this.todayCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_kDashboardSectionSpacing),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardPrimaryStart, AppColors.cardPrimaryEnd],
        ),
        boxShadow: AppShadow.hero(AppColors.cardPrimaryStart),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $firstName',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            period,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFFE0E7FF),
            ),
          ),
          const SizedBox(height: _kDashboardCardPadding),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              MetadataChip.onGradient(
                icon: Icons.today_outlined,
                text: dateLabel,
              ),
              MetadataChip.onGradient(
                icon: Icons.class_outlined,
                text: '$todayCount class${todayCount == 1 ? '' : 'es'} today',
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: color.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
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

class _DashboardScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;

  const _DashboardScheduleCard({required this.schedule});

  Color _getStatusColor(ScheduleTimeStatus status) {
    switch (status) {
      case ScheduleTimeStatus.inProgress:
        return const Color(0xFF10B981); // Green
      case ScheduleTimeStatus.upcoming:
        return const Color(0xFF3B82F6); // Blue
      case ScheduleTimeStatus.completed:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Color _getStatusBackgroundColor(ScheduleTimeStatus status) {
    switch (status) {
      case ScheduleTimeStatus.inProgress:
        return const Color(0xFFD1FAE5); // Light green
      case ScheduleTimeStatus.upcoming:
        return const Color(0xFFDBEAFE); // Light blue
      case ScheduleTimeStatus.completed:
        return const Color(0xFFF3F4F6); // Light gray
    }
  }

  Color _getTimeBoxColor(ScheduleTimeStatus status) {
    switch (status) {
      case ScheduleTimeStatus.inProgress:
        return const Color(0xFFD1FAE5);
      case ScheduleTimeStatus.upcoming:
        return const Color(0xFFDBEAFE);
      case ScheduleTimeStatus.completed:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getTimeTextColor(ScheduleTimeStatus status) {
    switch (status) {
      case ScheduleTimeStatus.inProgress:
        return const Color(0xFF059669);
      case ScheduleTimeStatus.upcoming:
        return const Color(0xFF2563EB);
      case ScheduleTimeStatus.completed:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStatus = schedule.timeStatus;
    final textTheme = Theme.of(context).textTheme;

    return ElegantCard(
      accentColor: _getStatusColor(timeStatus),
      padding: const EdgeInsets.all(_kDashboardCardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time box (similar to web frontend)
          Container(
            width: 56,
            padding:
                const EdgeInsets.symmetric(vertical: _kDashboardGridSpacing),
            decoration: BoxDecoration(
              color: _getTimeBoxColor(timeStatus),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  schedule.startTime12h,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _getTimeTextColor(timeStatus),
                  ),
                ),
                const SizedBox(height: _kDashboardTinyGap),
                Text(
                  schedule.endTime12h,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getTimeTextColor(timeStatus).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${schedule.subject.code} - ${schedule.subject.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              MetadataChip(
                                icon: Icons.location_on_outlined,
                                text: schedule.room.code,
                              ),
                              MetadataChip(
                                icon: Icons.calendar_today_outlined,
                                text: schedule.dayPatternLabel,
                              ),
                              if (schedule.section != null)
                                MetadataChip(
                                  icon: Icons.groups_2_outlined,
                                  text: 'Sec. ${schedule.section}',
                                ),
                              MetadataChip(
                                icon: Icons.people_outline,
                                text: '${schedule.enrolledStudents}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusPill(
                      label: timeStatus.label,
                      color: _getStatusColor(timeStatus),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: _kDashboardSectionSpacing,
        vertical: _kDashboardLargeGap,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.free_breakfast_outlined,
            size: 34,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No classes lined up today.',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enjoy the breathing room while it lasts.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 42, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load dashboard',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: _kDashboardCompactGap),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: _kDashboardCardPadding),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
