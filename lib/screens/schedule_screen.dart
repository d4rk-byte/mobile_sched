import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dashboard_model.dart';
import '../models/schedule_model.dart';
import '../providers/api_provider.dart';
import '../providers/schedule_provider.dart';
import 'pdf_viewer_screen.dart';
import 'schedule_change_request_screen.dart';
import '../utils/theme.dart';
import '../widgets/metadata_chip.dart';
import '../widgets/screen_shimmer.dart';
import '../widgets/section_header.dart';
import '../widgets/staggered_list.dart';

const _kScheduleListBottomPadding = 26.0;
const _kScheduleCardPadding = 14.0;
const _kScheduleSectionSpacing = 18.0;
const _kScheduleBottomPadding = 28.0;
const _kScheduleCompactGap = AppSpacing.sm - 2;
const _kSchedulePillVerticalPadding = AppSpacing.sm - 1;

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _isDownloadingTeachingLoad = false;
  int? _savingClassId;

  Future<void> _refresh(String? semester) async {
    ref.invalidate(scheduleProvider(semester));
    await ref.read(scheduleProvider(semester).future);
  }

  int? _parseNonNegativeInt(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final value = int.tryParse(trimmed);
    if (value == null || value < 0) {
      return null;
    }

    return value;
  }

  Future<int?> _promptEnrolledStudents(
      BuildContext context, ScheduleItem item) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _EnrolledStudentsDialog(item: item);
      },
    );
  }

  Future<void> _editEnrolledStudents(
    BuildContext context,
    ScheduleItem item,
    String? semester,
  ) async {
    final nextValue = await _promptEnrolledStudents(context, item);
    if (nextValue == null || nextValue == item.enrolledStudents) {
      return;
    }

    setState(() {
      _savingClassId = item.id;
    });

    try {
      await ref
          .read(apiServiceProvider)
          .updateEnrolledStudents(item.id, nextValue);
      await _refresh(semester);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student count updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update student count: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingClassId = null;
        });
      }
    }
  }

  String _buildTeachingLoadFileName(String? semester) {
    final raw = (semester ?? 'current').toLowerCase();
    final sanitized = raw
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final suffix = DateTime.now().millisecondsSinceEpoch;
    if (sanitized.isEmpty) {
      return 'teaching-load-$suffix';
    }

    return 'teaching-load-$sanitized-$suffix';
  }

  Future<String> _savePdfToDownloads(
    List<int> bytes, {
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw 'Generated PDF is empty.';
    }

    Directory? directory;
    if (Platform.isAndroid || Platform.isIOS) {
      directory = await getExternalStorageDirectory();
    }

    directory ??= await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _downloadTeachingLoadPdf(
    BuildContext context,
    String? semester,
  ) async {
    if (_isDownloadingTeachingLoad) {
      return;
    }

    setState(() {
      _isDownloadingTeachingLoad = true;
    });

    try {
      final bytes =
          await ref.read(apiServiceProvider).exportTeachingLoadPdf(semester);
      final filePath = await _savePdfToDownloads(
        bytes,
        fileName: _buildTeachingLoadFileName(semester),
      );

      if (!mounted) {
        return;
      }

      final fileName = filePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teaching Load PDF downloaded: $fileName'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    title: 'Teaching Load PDF',
                    filePath: filePath,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download Teaching Load PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingTeachingLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSemester = ref.watch(selectedSemesterProvider);
    final scheduleAsync = ref.watch(scheduleProvider(selectedSemester));
    final textTheme = Theme.of(context).textTheme;

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
          _isDownloadingTeachingLoad
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              : IconButton(
                  tooltip: 'Download Teaching Load PDF',
                  onPressed: () =>
                      _downloadTeachingLoadPdf(context, selectedSemester),
                  icon: const Icon(Icons.download_rounded),
                ),
        ],
      ),
      body: scheduleAsync.when(
        data: (schedule) => RefreshIndicator(
          onRefresh: () => _refresh(selectedSemester),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              _kScheduleListBottomPadding,
            ),
            children: [
              StaggeredItem(
                index: 0,
                child: _ScheduleOverviewCard(schedule: schedule),
              ),
              const SizedBox(height: AppSpacing.lg),
              StaggeredItem(
                index: 1,
                child: SectionHeader(
                  title: 'Schedules',
                  count: schedule.schedules.length,
                  countLabel: 'classes',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (schedule.schedules.isEmpty)
                const _ScheduleEmptyState()
              else ...[for (int i = 0; i < schedule.schedules.length; i++) ...[Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: StaggeredItem(
                  index: i + 2,
                  child: _ScheduleCard(
                    item: schedule.schedules[i],
                    isSavingStudents: _savingClassId == schedule.schedules[i].id,
                    onEditStudents: () => _editEnrolledStudents(
                        context, schedule.schedules[i], selectedSemester),
                  ),
                ),
              )]],
            ],
          ),
        ),
        loading: () => const ScheduleShimmer(),
        error: (error, stackTrace) => _ScheduleErrorState(
          message: error.toString(),
          onRetry: () => _refresh(selectedSemester),
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            'Semester: ${schedule.semester.trim().isEmpty ? 'N/A' : schedule.semester}',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _kScheduleCompactGap),
          Text(
            schedule.academicYear != null
                ? 'Academic Year ${schedule.academicYear!.year}'
                : 'Academic year unavailable',
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFFE0E7FF),
            ),
          ),
          const SizedBox(height: _kScheduleCardPadding),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              MetadataChip.onGradient(
                icon: Icons.timer_outlined,
                text: '${schedule.stats.totalHours.toStringAsFixed(1)} hrs',
              ),
              MetadataChip.onGradient(
                icon: Icons.class_outlined,
                text: '${schedule.stats.totalClasses} classes',
              ),
              MetadataChip.onGradient(
                icon: Icons.people_alt_outlined,
                text: '${schedule.stats.totalStudents} students',
              ),
              MetadataChip.onGradient(
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

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final bool isSavingStudents;
  final VoidCallback onEditStudents;

  const _ScheduleCard({
    required this.item,
    required this.isSavingStudents,
    required this.onEditStudents,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          topRight: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          left: BorderSide(color: AppColors.primaryColor, width: 3.5),
          top: const BorderSide(color: AppColors.cardBorder),
          right: const BorderSide(color: AppColors.cardBorder),
          bottom: const BorderSide(color: AppColors.cardBorder),
        ),
        boxShadow: AppShadow.card,
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
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: _kScheduleCompactGap,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardChipSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  item.section ?? 'General',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardChipText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ScheduleMetaChip(
                  icon: Icons.people_outline,
                  text: '${item.enrolledStudents} students',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: isSavingStudents ? null : onEditStudents,
                icon: isSavingStudents
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined, size: 16),
                label: Text(isSavingStudents ? 'Saving...' : 'Edit students'),
                style: OutlinedButton.styleFrom(
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: _kScheduleCompactGap,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardChipSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: _kScheduleCompactGap),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrolledStudentsDialog extends StatefulWidget {
  final ScheduleItem item;

  const _EnrolledStudentsDialog({required this.item});

  @override
  State<_EnrolledStudentsDialog> createState() =>
      _EnrolledStudentsDialogState();
}

class _EnrolledStudentsDialogState extends State<_EnrolledStudentsDialog> {
  late final TextEditingController _controller;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.enrolledStudents.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0) {
      setState(() {
        _validationError = 'Enter a valid whole number (0 or higher).';
      });
      return;
    }

    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Student Count'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.item.subject.code} - ${widget.item.subject.title}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enrolled Students',
              errorText: _validationError,
            ),
            onChanged: (_) {
              if (_validationError != null) {
                setState(() {
                  _validationError = null;
                });
              }
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: _kScheduleSectionSpacing,
        vertical: _kScheduleBottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No schedules found',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your assigned classes will appear here once available.',
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

class _ScheduleErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ScheduleErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load schedule',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: _kScheduleCompactGap),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
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
