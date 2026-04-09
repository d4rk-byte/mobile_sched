import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import 'schedule_change_request_screen.dart';
import '../utils/theme.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  Future<void> _refresh(WidgetRef ref, String? semester) async {
    ref.invalidate(scheduleProvider(semester));
    await ref.read(scheduleProvider(semester).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSemester = ref.watch(selectedSemesterProvider);
    final scheduleAsync = ref.watch(scheduleProvider(selectedSemester));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Schedule'),
        actions: [
          IconButton(
            tooltip: 'Change Requests',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScheduleChangeRequestScreen(),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(ref, selectedSemester),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: scheduleAsync.when(
        data: (schedule) => RefreshIndicator(
          onRefresh: () => _refresh(ref, selectedSemester),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
            children: [
              _ScheduleOverviewCard(schedule: schedule),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Schedules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardChipSurface,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${schedule.schedules.length} classes',
                      style: const TextStyle(
                        color: AppColors.cardChipText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (schedule.schedules.isEmpty)
                const _ScheduleEmptyState()
              else
                ...schedule.schedules.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(item: item),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ScheduleErrorState(
          message: error.toString(),
          onRetry: () => _refresh(ref, selectedSemester),
        ),
      ),
    );
  }
}

class _ScheduleOverviewCard extends StatelessWidget {
  final ScheduleResponse schedule;

  const _ScheduleOverviewCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardPrimaryStart, AppColors.cardPrimaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardPrimaryStart.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semester: ${schedule.semester.trim().isEmpty ? 'N/A' : schedule.semester}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            schedule.academicYear != null
                ? 'Academic Year ${schedule.academicYear!.year}'
                : 'Academic year unavailable',
            style: const TextStyle(
              color: Color(0xFFE0E7FF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OverviewPill(
                icon: Icons.timer_outlined,
                text: '${schedule.stats.totalHours.toStringAsFixed(1)} hrs',
              ),
              _OverviewPill(
                icon: Icons.class_outlined,
                text: '${schedule.stats.totalClasses} classes',
              ),
              _OverviewPill(
                icon: Icons.people_alt_outlined,
                text: '${schedule.stats.totalStudents} students',
              ),
              _OverviewPill(
                icon: Icons.meeting_room_outlined,
                text: '${schedule.stats.totalRooms} rooms',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OverviewPill({required this.icon, required this.text});

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
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
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

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;

  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.subject.code} • ${item.subject.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardChipSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.section ?? 'General',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardChipText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScheduleMetaChip(
                icon: Icons.schedule_rounded,
                text: '${item.startTime12h} - ${item.endTime12h}',
              ),
              _ScheduleMetaChip(
                icon: Icons.calendar_today_outlined,
                text: item.dayPatternLabel,
              ),
              _ScheduleMetaChip(
                icon: Icons.location_on_outlined,
                text: item.room.code,
              ),
              _ScheduleMetaChip(
                icon: Icons.people_outline,
                text: '${item.enrolledStudents} students',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScheduleMetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardChipSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No schedules found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your assigned classes will appear here once available.',
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

class _ScheduleErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ScheduleErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Unable to load schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
