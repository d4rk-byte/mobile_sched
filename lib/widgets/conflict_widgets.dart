import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conflict_model.dart';
import '../utils/theme.dart';

class ConflictBadge extends StatelessWidget {
  final String conflictType;

  const ConflictBadge({super.key, required this.conflictType});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (conflictType) {
      case 'room_time_conflict':
        backgroundColor = const Color(0xFFFEE2E2); // red-100
        textColor = const Color(0xFFB91C1C); // red-700
        label = 'Room Conflict';
        break;
      case 'faculty_conflict':
        backgroundColor = const Color(0xFFFFEDD5); // orange-100
        textColor = const Color(0xFFC2410C); // orange-700
        label = 'Faculty Conflict';
        break;
      case 'section_conflict':
        backgroundColor = const Color(0xFFF3E8FF); // purple-100
        textColor = const Color(0xFF7E22CE); // purple-700
        label = 'Section Conflict';
        break;
      default:
        backgroundColor = AppColors.cardChipSurface;
        textColor = AppColors.cardChipText;
        label = 'Schedule Conflict';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class ConflictDetailCard extends StatelessWidget {
  final ConflictDetail conflict;

  const ConflictDetailCard({super.key, required this.conflict});

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'N/A';

    try {
      // Parse time in HH:mm format
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final dateTime = DateTime(2000, 1, 1, hour, minute);
        return DateFormat('hh:mm a').format(dateTime);
      }
    } catch (e) {
      // Return original if parsing fails
    }

    return time;
  }

  String _getConflictMessage() {
    final schedule = conflict.schedule;
    if (schedule == null) return conflict.message;

    final subjectCode = schedule.subject?.displayCode ?? 'SUBJ';
    final section = schedule.displaySection;
    final room = schedule.room?.displayCode ?? 'TBA';
    final days = schedule.displayDayPattern;
    final startTime = _formatTime(schedule.startTime);
    final endTime = _formatTime(schedule.endTime);
    final faculty = schedule.faculty?.displayName ?? 'Assigned faculty';

    switch (conflict.type) {
      case 'room_time_conflict':
        return 'Room $room is already booked for $subjectCode on $days at $startTime - $endTime.';
      case 'faculty_conflict':
        return '$faculty is already teaching $subjectCode on $days at $startTime - $endTime.';
      case 'section_conflict':
        return 'Section $section of $subjectCode already has a class on $days at $startTime - $endTime in room $room.';
      default:
        return conflict.message.isNotEmpty
            ? conflict.message
            : 'Schedule conflict detected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = conflict.schedule;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (schedule?.subject != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${schedule!.subject!.displayCode} — ${schedule.subject!.displayTitle}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Section ${schedule.displaySection}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ConflictBadge(conflictType: conflict.type),
          const SizedBox(height: 8),
          Text(
            _getConflictMessage(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ConflictListDialog extends StatelessWidget {
  final List<ConflictDetail> conflicts;
  final VoidCallback? onClose;
  final VoidCallback? onProceed;

  const ConflictListDialog({
    super.key,
    required this.conflicts,
    this.onClose,
    this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conflicts Detected (${conflicts.length})',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: conflicts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return ConflictDetailCard(conflict: conflicts[index]);
          },
        ),
      ),
      actions: [
        if (onClose != null)
          TextButton(
            onPressed: onClose,
            child: const Text('Cancel'),
          ),
        if (onProceed != null)
          FilledButton(
            onPressed: onProceed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Submit Anyway'),
          ),
      ],
    );
  }
}
