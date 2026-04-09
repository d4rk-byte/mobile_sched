import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/class_notification_provider.dart';
import '../utils/theme.dart';

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

    final fallbackName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim().split(' ').first
        : 'Professor';
    final firstName = user?.firstName?.trim().isNotEmpty == true
        ? user!.firstName!.trim()
        : fallbackName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
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
                    label: 'Today\'s Classes',
                    value: '${dashboard.stats.todayCount}',
                    helper: 'Schedule today',
                    icon: Icons.calendar_today_outlined,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${dashboard.todaySchedules.length} items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dashboard.todaySchedules.isEmpty)
                const _EmptyScheduleCard()
              else
                ..._sortSchedulesByStatus(dashboard.todaySchedules).map(
                  (schedule) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DashboardScheduleCard(schedule: schedule),
                  ),
                ),
            ],
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardPrimaryStart, AppColors.cardPrimaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardPrimaryStart.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $firstName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            period,
            style: const TextStyle(
              color: Color(0xFFE0E7FF),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.today_outlined,
                label: dateLabel,
              ),
              _HeroPill(
                icon: Icons.class_outlined,
                label: '$todayCount class${todayCount == 1 ? '' : 'es'} today',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time box (similar to web frontend)
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _getTimeBoxColor(timeStatus),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  schedule.startTime12h,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getTimeTextColor(timeStatus),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  schedule.endTime12h,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getTimeTextColor(timeStatus).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${schedule.dayPatternLabel} | Room ${schedule.room.code}${schedule.room.name != null ? ' (${schedule.room.name})' : ''} | Section ${schedule.section ?? '—'} | ${schedule.enrolledStudents} students',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBackgroundColor(timeStatus),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        timeStatus.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(timeStatus),
                        ),
                      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.free_breakfast_outlined,
            size: 34,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No classes lined up today.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Enjoy the breathing room while it lasts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Could not load dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
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
