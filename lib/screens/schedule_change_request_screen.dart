import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../models/conflict_model.dart';
import '../providers/api_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/theme.dart';
import '../widgets/conflict_widgets.dart';

const _requestFilters = <String>['All', 'Pending', 'Approved', 'Rejected'];

final _scheduleChangeRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
  (ref, status) async {
    final api = ref.watch(apiServiceProvider);
    final requests = await api.listScheduleChangeRequests(status: status);

    return requests
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  },
);

final _availableRoomsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final api = ref.watch(apiServiceProvider);
    final payload = await api.listRooms(limit: 300);
    final roomList = _extractFirstList(payload);

    if (roomList == null) {
      return const <Map<String, dynamic>>[];
    }

    return roomList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((room) => _toInt(room['id']) != null)
        .toList();
  },
);

class ScheduleChangeRequestScreen extends ConsumerStatefulWidget {
  const ScheduleChangeRequestScreen({super.key});

  @override
  ConsumerState<ScheduleChangeRequestScreen> createState() =>
      _ScheduleChangeRequestScreenState();
}

class _ScheduleChangeRequestScreenState
    extends ConsumerState<ScheduleChangeRequestScreen> {
  String _selectedFilter = _requestFilters.first;
  final Set<int> _cancellingIds = <int>{};

  String? get _selectedApiStatus {
    switch (_selectedFilter.toLowerCase()) {
      case 'pending':
        return 'pending';
      case 'approved':
        return 'approved';
      case 'rejected':
        return 'rejected';
      default:
        return null;
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(_scheduleChangeRequestsProvider(_selectedApiStatus));
    await ref.read(_scheduleChangeRequestsProvider(_selectedApiStatus).future);
  }

  Future<void> _cancelRequest(Map<String, dynamic> request) async {
    final requestId = _toInt(request['id']);
    if (requestId == null || _cancellingIds.contains(requestId)) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel request'),
          content: const Text(
            'Do you want to cancel this schedule change request?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) {
      return;
    }

    setState(() {
      _cancellingIds.add(requestId);
    });

    try {
      await ref.read(apiServiceProvider).cancelScheduleChangeRequest(requestId);
      await _refresh();
      _showMessage('Request #$requestId cancelled.');
    } catch (e) {
      _showMessage('Failed to cancel request: $e');
    } finally {
      if (mounted) {
        setState(() {
          _cancellingIds.remove(requestId);
        });
      }
    }
  }

  Future<void> _openNewRequestForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewScheduleRequestSheet(),
    );

    if (created == true) {
      if (_selectedFilter != _requestFilters.first) {
        setState(() {
          _selectedFilter = _requestFilters.first;
        });
      }
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync =
        ref.watch(_scheduleChangeRequestsProvider(_selectedApiStatus));
    final requestItems =
        requestsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Change Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _RequestSummaryBanner(
              selectedFilter: _selectedFilter,
              totalCount: requestItems.length,
              pendingCount: requestItems
                  .where((item) => _effectiveRequestStatus(item) == 'pending')
                  .length,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _requestFilters
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          showCheckmark: true,
                          checkmarkColor: AppColors.cardPrimaryEnd,
                          selectedColor: AppColors.cardChipSurface,
                          backgroundColor: AppColors.whiteColor,
                          side: BorderSide(
                            color: _selectedFilter == filter
                                ? AppColors.cardPrimaryEnd
                                : AppColors.cardBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter
                                ? AppColors.cardPrimaryEnd
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) {
                            if (!selected || _selectedFilter == filter) {
                              return;
                            }

                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            requestsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _RequestsEmptyState();
                }

                return Column(
                  children: items
                      .map(
                        (request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestCard(
                            request: request,
                            isCancelling: _cancellingIds
                                .contains(_toInt(request['id']) ?? -1),
                            onCancel: () => _cancelRequest(request),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => _RequestsErrorState(
                message: error.toString(),
                onRetry: _refresh,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRequestForm,
        backgroundColor: AppColors.cardPrimaryEnd,
        foregroundColor: Colors.white,
        label: const Text(
          'New Request',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
      ),
    );
  }
}

class _NewScheduleRequestSheet extends ConsumerStatefulWidget {
  const _NewScheduleRequestSheet();

  @override
  ConsumerState<_NewScheduleRequestSheet> createState() =>
      _NewScheduleRequestSheetState();
}

class _NewScheduleRequestSheetState
    extends ConsumerState<_NewScheduleRequestSheet> {
  int? _selectedScheduleId;
  int? _selectedRoomId;
  bool _isSubmitting = false;
  bool _usePresetMode = true;
  String? _selectedPresetDayPattern;
  String? _selectedPresetTimeSlotKey;
  final Set<String> _selectedCustomDays = <String>{};
  Timer? _liveConflictDebounce;
  int _liveConflictRequestId = 0;
  bool _isCheckingConflicts = false;
  bool _hasCheckedLiveConflict = false;
  String? _liveConflictError;
  List<ConflictDetail> _liveConflicts = const <ConflictDetail>[];

  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _sectionController;
  late final TextEditingController _reasonController;
  late final TextEditingController _enrolledStudentsController;

  static const List<_DayPatternOption> _dayOptions = [
    _DayPatternOption(label: 'Mon', code: 'M'),
    _DayPatternOption(label: 'Tue', code: 'T'),
    _DayPatternOption(label: 'Wed', code: 'W'),
    _DayPatternOption(label: 'Thu', code: 'TH'),
    _DayPatternOption(label: 'Fri', code: 'F'),
    _DayPatternOption(label: 'Sat', code: 'SAT'),
    _DayPatternOption(label: 'Sun', code: 'SUN'),
  ];

  static const List<String> _defaultPresetDayPatterns = [
    'MWF',
    'TTH',
    'MTWTHF',
    'SAT',
    'SUN',
  ];

  static const List<_PresetTimeSlot> _defaultPresetTimeSlots = [
    _PresetTimeSlot(
      key: '07:00|08:30',
      label: '7:00 AM - 8:30 AM',
      start: '07:00',
      end: '08:30',
    ),
    _PresetTimeSlot(
      key: '08:30|10:00',
      label: '8:30 AM - 10:00 AM',
      start: '08:30',
      end: '10:00',
    ),
    _PresetTimeSlot(
      key: '10:00|11:30',
      label: '10:00 AM - 11:30 AM',
      start: '10:00',
      end: '11:30',
    ),
    _PresetTimeSlot(
      key: '13:00|14:30',
      label: '1:00 PM - 2:30 PM',
      start: '13:00',
      end: '14:30',
    ),
    _PresetTimeSlot(
      key: '14:30|16:00',
      label: '2:30 PM - 4:00 PM',
      start: '14:30',
      end: '16:00',
    ),
    _PresetTimeSlot(
      key: '16:00|17:30',
      label: '4:00 PM - 5:30 PM',
      start: '16:00',
      end: '17:30',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _sectionController = TextEditingController();
    _reasonController = TextEditingController();
    _enrolledStudentsController = TextEditingController(text: '0');
    _sectionController.addListener(_scheduleLiveConflictCheck);
  }

  @override
  void dispose() {
    _liveConflictDebounce?.cancel();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _sectionController.removeListener(_scheduleLiveConflictCheck);
    _sectionController.dispose();
    _reasonController.dispose();
    _enrolledStudentsController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _populateFromSchedule(ScheduleItem schedule) {
    if (_sectionController.text.trim().isEmpty) {
      _sectionController.text = schedule.section ?? '';
    }

    if (_enrolledStudentsController.text.trim().isEmpty ||
        _enrolledStudentsController.text.trim() == '0') {
      _enrolledStudentsController.text = '${schedule.enrolledStudents}';
    }

    if (_startTimeController.text.trim().isEmpty) {
      _startTimeController.text = _toMeridiemTime(
        schedule.startTime12h.trim().isNotEmpty
            ? schedule.startTime12h
            : schedule.startTime,
      );
    }

    if (_endTimeController.text.trim().isEmpty) {
      _endTimeController.text = _toMeridiemTime(
        schedule.endTime12h.trim().isNotEmpty
            ? schedule.endTime12h
            : schedule.endTime,
      );
    }

    _selectedPresetTimeSlotKey ??= _timeSlotKey(
      _toHourMinute(schedule.startTime),
      _toHourMinute(schedule.endTime),
    );

    if (_selectedPresetDayPattern == null) {
      final inferredPattern = _normalizePresetDayPattern(schedule);
      _selectedPresetDayPattern = inferredPattern;

      if (inferredPattern != null && _selectedCustomDays.isEmpty) {
        _selectedCustomDays.addAll(_customDaysFromPattern(inferredPattern));
      }
    }

    if (_selectedRoomId == null && schedule.room.id > 0) {
      _selectedRoomId = schedule.room.id;
    }
  }

  void _toggleDayCode(String code, bool selected) {
    setState(() {
      if (selected) {
        _selectedCustomDays.add(code);
      } else {
        _selectedCustomDays.remove(code);
      }
    });

    _scheduleLiveConflictCheck();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final initialTime = _parseTimeOfDay(controller.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      controller.text = _formatTimeOfDay(picked);
    });

    _scheduleLiveConflictCheck();
  }

  Map<String, dynamic>? _buildLiveConflictPayload(
      ScheduleItem? selectedSchedule) {
    if (_selectedScheduleId == null || _selectedRoomId == null) {
      return null;
    }

    final customPattern = _resolveCustomDayPattern();
    final dayPattern =
        _usePresetMode ? _selectedPresetDayPattern : customPattern;
    if (dayPattern == null || dayPattern.trim().isEmpty) {
      return null;
    }

    String startTime;
    String endTime;

    if (_usePresetMode) {
      final presetSlot = _selectedPresetSlot(selectedSchedule);
      if (presetSlot == null) {
        return null;
      }

      startTime = presetSlot.start;
      endTime = presetSlot.end;
    } else {
      final customStart = _startTimeController.text.trim();
      final customEnd = _endTimeController.text.trim();
      if (customStart.isEmpty || customEnd.isEmpty) {
        return null;
      }

      startTime = _toHourMinute(customStart);
      endTime = _toHourMinute(customEnd);
    }

    final startMinutes = _minutesFromTime(startTime);
    final endMinutes = _minutesFromTime(endTime);
    if (startMinutes == null ||
        endMinutes == null ||
        startMinutes >= endMinutes) {
      return null;
    }

    final payload = <String, dynamic>{
      'schedule_id': _selectedScheduleId,
      'day_pattern': dayPattern,
      'start_time': startTime,
      'end_time': endTime,
      'room_id': _selectedRoomId,
    };

    final sectionText = _sectionController.text.trim();
    final section = sectionText.isNotEmpty
        ? sectionText
        : (selectedSchedule?.section?.trim() ?? '');
    if (section.isNotEmpty) {
      payload['section'] = section;
    }

    return payload;
  }

  void _scheduleLiveConflictCheck() {
    _liveConflictDebounce?.cancel();

    final selectedSchedule = _selectedScheduleFromProvider();
    final payload = _buildLiveConflictPayload(selectedSchedule);

    if (payload == null) {
      _liveConflictRequestId++;
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingConflicts = false;
        _hasCheckedLiveConflict = false;
        _liveConflictError = null;
        _liveConflicts = const <ConflictDetail>[];
      });
      return;
    }

    _liveConflictDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_runLiveConflictCheck(payload));
    });
  }

  Future<void> _runLiveConflictCheck(Map<String, dynamic> payload) async {
    final requestId = ++_liveConflictRequestId;

    if (mounted) {
      setState(() {
        _isCheckingConflicts = true;
        _liveConflictError = null;
      });
    }

    try {
      final response = await ref
          .read(apiServiceProvider)
          .checkScheduleChangeConflict(payload);
      if (!mounted || requestId != _liveConflictRequestId) {
        return;
      }

      final conflictResult = ConflictCheckResult.fromJson(response);
      setState(() {
        _isCheckingConflicts = false;
        _hasCheckedLiveConflict = true;
        _liveConflictError = null;
        _liveConflicts = conflictResult.hasConflict
            ? conflictResult.conflicts
            : const <ConflictDetail>[];
      });
    } catch (error) {
      if (!mounted || requestId != _liveConflictRequestId) {
        return;
      }

      setState(() {
        _isCheckingConflicts = false;
        _hasCheckedLiveConflict = false;
        _liveConflicts = const <ConflictDetail>[];
        _liveConflictError = 'Could not check conflicts right now.';
      });
    }
  }

  String? _validateInput(ScheduleItem? selectedSchedule) {
    if (_selectedScheduleId == null) {
      return 'Please select a class schedule.';
    }
    if (_selectedRoomId == null) {
      return 'Please select a room.';
    }
    final enrolledStudents =
        _parseNonNegativeInt(_enrolledStudentsController.text.trim());
    if (enrolledStudents == null) {
      return 'Please enter a valid enrolled student count.';
    }

    String dayPattern = '';
    String startTime = '';
    String endTime = '';

    if (_usePresetMode) {
      if (_selectedPresetDayPattern == null ||
          _selectedPresetDayPattern!.trim().isEmpty) {
        return 'Please select a day pattern.';
      }

      dayPattern = _selectedPresetDayPattern!;

      final presetSlot = _selectedPresetSlot(selectedSchedule);
      if (presetSlot == null) {
        return 'Please select a time slot.';
      }

      startTime = presetSlot.start;
      endTime = presetSlot.end;
    } else {
      if (_selectedCustomDays.isEmpty) {
        return 'Please select at least one day for custom day pattern.';
      }

      final customPattern = _resolveCustomDayPattern();
      if (customPattern == null) {
        return 'Please choose a valid custom day pattern.';
      }

      dayPattern = customPattern;

      if (_startTimeController.text.trim().isEmpty) {
        return 'Please select a start time.';
      }
      if (_endTimeController.text.trim().isEmpty) {
        return 'Please select an end time.';
      }

      startTime = _startTimeController.text;
      endTime = _endTimeController.text;
    }

    final normalizedStartTime = _toHourMinute(startTime);
    final normalizedEndTime = _toHourMinute(endTime);

    final startMinutes = _minutesFromTime(startTime);
    final endMinutes = _minutesFromTime(endTime);

    if (startMinutes == null || endMinutes == null) {
      return 'Please use a valid time format (e.g. 7:00 AM).';
    }

    if (startMinutes >= endMinutes) {
      return 'End time must be later than start time.';
    }

    if (_isSameAsCurrentSchedule(
      selectedSchedule: selectedSchedule,
      requestedDayPattern: dayPattern,
      requestedStartTime: normalizedStartTime,
      requestedEndTime: normalizedEndTime,
      requestedRoomId: _selectedRoomId,
    )) {
      return 'This request matches the current schedule. Please change day pattern, time, or room before submitting.';
    }

    return null;
  }

  Future<bool> _confirmConflict(Map<String, dynamic> payload) async {
    // Parse conflict result using new model
    final conflictResult = ConflictCheckResult.fromJson(payload);

    if (!conflictResult.hasConflict || conflictResult.conflicts.isEmpty) {
      return true; // No conflicts, proceed
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ConflictListDialog(
          conflicts: conflictResult.conflicts,
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );

    _showMessage(
        'Resolve the detected conflicts before submitting this request.');
    return false;
  }

  Future<bool> _confirmProceedWithoutConflictCheck(String error) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Conflict check unavailable'),
          content: Text(
            'Could not validate conflicts before submit.\n\n$error\n\nDo you still want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return shouldContinue == true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final selectedSchedule = _selectedScheduleFromProvider();

    final validationError = _validateInput(selectedSchedule);
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    final customPattern = _resolveCustomDayPattern();
    final dayPattern =
        _usePresetMode ? _selectedPresetDayPattern! : (customPattern ?? '');
    final presetSlot =
        _usePresetMode ? _selectedPresetSlot(selectedSchedule) : null;
    final startTime = _usePresetMode
        ? presetSlot!.start
        : _toHourMinute(_startTimeController.text);
    final endTime = _usePresetMode
        ? presetSlot!.end
        : _toHourMinute(_endTimeController.text);

    final payload = <String, dynamic>{
      'schedule_id': _selectedScheduleId,
      'day_pattern': dayPattern,
      'start_time': startTime,
      'end_time': endTime,
      'room_id': _selectedRoomId,
    };

    final reasonText = _reasonController.text.trim();
    if (reasonText.isNotEmpty) {
      // Send both keys for compatibility across API variants.
      payload['reason'] = reasonText;
      payload['request_reason'] = reasonText;
    }

    final section = _sectionController.text.trim();
    if (section.isNotEmpty) {
      payload['section'] = section;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      bool allowSubmit = true;

      try {
        final conflict = await api.checkScheduleChangeConflict(payload);
        if (_hasConflict(conflict)) {
          allowSubmit = await _confirmConflict(conflict);
        }
      } catch (error) {
        allowSubmit =
            await _confirmProceedWithoutConflictCheck(error.toString());
      }

      if (!allowSubmit) {
        return;
      }

      await api.createScheduleChangeRequest(payload);

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Schedule change request submitted.')),
      );
    } catch (error) {
      _showMessage('Failed to submit request: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSemester = ref.watch(selectedSemesterProvider);
    final schedulesAsync = ref.watch(scheduleProvider(selectedSemester));
    final roomsAsync = ref.watch(_availableRoomsProvider);

    final schedules =
        schedulesAsync.valueOrNull?.schedules ?? const <ScheduleItem>[];
    final rooms = roomsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    ScheduleItem? selectedSchedule;
    for (final schedule in schedules) {
      if (schedule.id == _selectedScheduleId) {
        selectedSchedule = schedule;
        break;
      }
    }

    final requiredCapacity =
        _parsePositiveInt(_enrolledStudentsController.text) ??
            selectedSchedule?.enrolledStudents;
    final filteredRooms = _filterRooms(
      rooms,
      requiredCapacity: requiredCapacity,
    );

    final presetDayPatterns = _presetDayPatternOptions(selectedSchedule);
    final presetTimeSlots = _presetTimeSlotOptions(selectedSchedule);

    final selectedRoomData = _findRoomById(rooms, _selectedRoomId);
    final roomOptions = _withSelectedRoomOption(
      filteredRooms,
      selectedRoomData,
      _selectedRoomId,
    );

    final selectedScheduleExists =
        schedules.any((schedule) => schedule.id == _selectedScheduleId);
    final selectedRoomExists =
        roomOptions.any((room) => _toInt(room['id']) == _selectedRoomId);

    final scheduleValue = selectedScheduleExists ? _selectedScheduleId : null;
    final roomValue = selectedRoomExists ? _selectedRoomId : null;
    final dayPatternValue =
        presetDayPatterns.contains(_selectedPresetDayPattern)
            ? _selectedPresetDayPattern
            : null;
    final presetTimeValue =
        presetTimeSlots.any((slot) => slot.key == _selectedPresetTimeSlotKey)
            ? _selectedPresetTimeSlotKey
            : null;
    final selectedDayLabels = _dayOptions
        .where((day) => _selectedCustomDays.contains(day.code))
        .map((day) => day.label)
        .toList();
    final resolvedCustomPattern = _resolveCustomDayPattern();
    final isNoEffectiveChange = _isCurrentSelectionUnchanged(selectedSchedule);

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'New Schedule Change Request',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _usePresetMode
                                ? 'Using preset day pattern and time slot.'
                                : 'Using custom day pattern and manual time range.',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _usePresetMode = !_usePresetMode;
                          });

                          _scheduleLiveConflictCheck();
                        },
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: AppColors.cardPrimaryEnd,
                        ),
                        label: Text(
                          _usePresetMode ? 'Use Custom' : 'Use Preset',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: const BorderSide(
                            color: AppColors.cardPrimaryEnd,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        tooltip: 'Close',
                        padding: EdgeInsets.zero,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (schedulesAsync.isLoading || roomsAsync.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (schedulesAsync.hasError)
                        _InlineNotice(
                          message:
                              'Unable to load schedules: ${schedulesAsync.error}',
                          color: AppColors.error,
                        ),
                      if (roomsAsync.hasError)
                        _InlineNotice(
                          message: 'Unable to load rooms: ${roomsAsync.error}',
                          color: AppColors.error,
                        ),
                      _SelectField<int>(
                        label: 'Class',
                        hint: 'Select class schedule',
                        value: scheduleValue,
                        items: schedules
                            .map(
                              (schedule) => DropdownMenuItem<int>(
                                value: schedule.id,
                                child: Text(
                                  '${schedule.subject.code} • ${schedule.section ?? 'General'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: schedules.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedScheduleId = value;
                                  if (value != null) {
                                    for (final schedule in schedules) {
                                      if (schedule.id == value) {
                                        _populateFromSchedule(schedule);
                                        break;
                                      }
                                    }
                                  }
                                });

                                _scheduleLiveConflictCheck();
                              },
                      ),
                      if (selectedSchedule != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _InlineNotice(
                            message:
                                'Current: ${selectedSchedule.subject.code} • ${selectedSchedule.dayPatternLabel} • ${selectedSchedule.startTime12h}-${selectedSchedule.endTime12h} • ${selectedSchedule.enrolledStudents} students',
                            color: AppColors.info,
                          ),
                        ),
                      if (schedules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'No schedules found. You need an assigned class before creating a request.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _sectionController,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (roomOptions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            requiredCapacity != null && requiredCapacity > 0
                                ? '${roomOptions.length} room${roomOptions.length == 1 ? '' : 's'} can fit $requiredCapacity students'
                                : '${roomOptions.length} room${roomOptions.length == 1 ? '' : 's'} available',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      _SelectField<int>(
                        label: 'Room',
                        hint: 'Select a room',
                        value: roomValue,
                        items: roomOptions
                            .map((room) {
                              final id = _toInt(room['id']);
                              if (id == null) {
                                return null;
                              }

                              final label = _roomLabel(room);

                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            })
                            .whereType<DropdownMenuItem<int>>()
                            .toList(),
                        onChanged: roomOptions.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedRoomId = value;
                                });

                                _scheduleLiveConflictCheck();
                              },
                      ),
                      if (roomOptions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'No available rooms for the current student count.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (_usePresetMode) ...[
                        _SelectField<String>(
                          label: 'Day Pattern',
                          hint: 'Select day pattern',
                          value: dayPatternValue,
                          items: presetDayPatterns
                              .map(
                                (pattern) => DropdownMenuItem<String>(
                                  value: pattern,
                                  child: Text(pattern),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPresetDayPattern = value;
                            });

                            _scheduleLiveConflictCheck();
                          },
                        ),
                        const SizedBox(height: 10),
                        _SelectField<String>(
                          label: 'Time Slot',
                          hint: 'Select time slot',
                          value: presetTimeValue,
                          items: presetTimeSlots
                              .map(
                                (slot) => DropdownMenuItem<String>(
                                  value: slot.key,
                                  child: Text(slot.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPresetTimeSlotKey = value;
                            });

                            _scheduleLiveConflictCheck();
                          },
                        ),
                      ] else ...[
                        const Text(
                          'Custom Day Pattern',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _dayOptions
                              .map(
                                (dayOption) => FilterChip(
                                  label: Text(dayOption.label),
                                  selected: _selectedCustomDays
                                      .contains(dayOption.code),
                                  selectedColor: AppColors.cardChipSurface,
                                  backgroundColor: AppColors.whiteColor,
                                  checkmarkColor: AppColors.cardPrimaryEnd,
                                  side: BorderSide(
                                    color: _selectedCustomDays
                                            .contains(dayOption.code)
                                        ? AppColors.cardPrimaryEnd
                                        : AppColors.cardBorder,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelStyle: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: _selectedCustomDays
                                            .contains(dayOption.code)
                                        ? AppColors.cardPrimaryEnd
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  onSelected: (selected) =>
                                      _toggleDayCode(dayOption.code, selected),
                                  showCheckmark: false,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selected: ${selectedDayLabels.isEmpty ? 'None' : selectedDayLabels.join(', ')}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (selectedDayLabels.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              resolvedCustomPattern != null
                                  ? 'Resolved Pattern: $resolvedCustomPattern'
                                  : 'Resolved Pattern: Invalid combination',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                color: resolvedCustomPattern != null
                                    ? AppColors.cardPrimaryEnd
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeField(
                                label: 'Start Time',
                                controller: _startTimeController,
                                onTap: () => _pickTime(_startTimeController),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _TimeField(
                                label: 'End Time',
                                controller: _endTimeController,
                                onTap: () => _pickTime(_endTimeController),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: _enrolledStudentsController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                          _scheduleLiveConflictCheck();
                        },
                        decoration: const InputDecoration(
                            labelText: 'Enrolled Students'),
                      ),
                      const SizedBox(height: 10),
                      if (_isCheckingConflicts)
                        const _InlineNotice(
                          message: 'Checking conflicts for selected schedule…',
                          color: AppColors.info,
                        ),
                      if (_liveConflictError != null)
                        _InlineNotice(
                          message: _liveConflictError!,
                          color: AppColors.warning,
                        ),
                      if (_liveConflicts.isNotEmpty) ...[
                        const Text(
                          'Live Conflict Detector',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: _liveConflicts
                              .map(
                                (conflict) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ConflictDetailCard(conflict: conflict),
                                ),
                              )
                              .toList(),
                        ),
                      ] else if (_hasCheckedLiveConflict)
                        const _InlineNotice(
                          message:
                              'No conflicts detected for the selected day, time, and room.',
                          color: AppColors.success,
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reasonController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Request (Optional)',
                          hintText: 'Add context for this schedule change.',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isNoEffectiveChange)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _InlineNotice(
                    message:
                        'No changes detected from the current schedule. Please update day pattern, time, or room to submit.',
                    color: AppColors.warning,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _isSubmitting || isNoEffectiveChange
                              ? null
                              : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Submit Request'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasConflict(Map<String, dynamic> payload) {
    // Use new conflict model parsing
    try {
      final conflictResult = ConflictCheckResult.fromJson(payload);
      return conflictResult.hasConflict;
    } catch (e) {
      // Fallback to old logic if parsing fails
      final explicit = payload['has_conflict'] ??
          payload['conflict'] ??
          payload['is_conflict'] ??
          payload['hasConflict'];
      if (explicit is bool) {
        return explicit;
      }

      final available = payload['available'];
      if (available is bool) {
        return !available;
      }

      final nested = payload['data'];
      if (nested is Map<String, dynamic>) {
        return _hasConflict(nested);
      }

      return false;
    }
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final normalized = _toHourMinute(value);
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(normalized);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _toHourMinute(String raw) {
    final input = raw.trim();

    final twelveHourMatch =
        RegExp(r'^([1-9]|1[0-2]):([0-5]\d)(?::[0-5]\d)?\s*([AaPp][Mm])$')
            .firstMatch(input);
    if (twelveHourMatch != null) {
      final hour12 = int.parse(twelveHourMatch.group(1)!);
      final minute = twelveHourMatch.group(2)!;
      final period = twelveHourMatch.group(3)!.toUpperCase();

      var hour24 = hour12 % 12;
      if (period == 'PM') {
        hour24 += 12;
      }

      return '${hour24.toString().padLeft(2, '0')}:$minute';
    }

    final match =
        RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)(?::[0-5]\d)?$').firstMatch(input);
    if (match == null) {
      return input;
    }

    final hour = int.parse(match.group(1)!).toString().padLeft(2, '0');
    final minute = match.group(2)!;
    return '$hour:$minute';
  }

  String _toMeridiemTime(String raw) {
    final normalized = _toHourMinute(raw);
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(normalized);
    if (match == null) {
      return raw.trim();
    }

    final hour24 = int.tryParse(match.group(1) ?? '');
    final minute = match.group(2) ?? '';
    if (hour24 == null) {
      return raw.trim();
    }

    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  int? _minutesFromTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(_toHourMinute(value));
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return null;
    }

    return (hour * 60) + minute;
  }

  int? _parseNonNegativeInt(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return null;
    }

    return parsed;
  }

  int? _parsePositiveInt(String value) {
    final parsed = _parseNonNegativeInt(value);
    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed;
  }

  bool _isCurrentSelectionUnchanged(ScheduleItem? selectedSchedule) {
    if (selectedSchedule == null || _selectedRoomId == null) {
      return false;
    }

    final requestedDayPattern = _usePresetMode
        ? _selectedPresetDayPattern?.trim()
        : _resolveCustomDayPattern();
    if (requestedDayPattern == null || requestedDayPattern.isEmpty) {
      return false;
    }

    String requestedStartTime;
    String requestedEndTime;

    if (_usePresetMode) {
      final presetSlot = _selectedPresetSlot(selectedSchedule);
      if (presetSlot == null) {
        return false;
      }

      requestedStartTime = presetSlot.start;
      requestedEndTime = presetSlot.end;
    } else {
      final start = _startTimeController.text.trim();
      final end = _endTimeController.text.trim();
      if (start.isEmpty || end.isEmpty) {
        return false;
      }

      requestedStartTime = _toHourMinute(start);
      requestedEndTime = _toHourMinute(end);
    }

    return _isSameAsCurrentSchedule(
      selectedSchedule: selectedSchedule,
      requestedDayPattern: requestedDayPattern,
      requestedStartTime: _toHourMinute(requestedStartTime),
      requestedEndTime: _toHourMinute(requestedEndTime),
      requestedRoomId: _selectedRoomId,
    );
  }

  bool _isSameAsCurrentSchedule({
    required ScheduleItem? selectedSchedule,
    required String requestedDayPattern,
    required String requestedStartTime,
    required String requestedEndTime,
    required int? requestedRoomId,
  }) {
    if (selectedSchedule == null || requestedRoomId == null) {
      return false;
    }

    if (requestedRoomId != selectedSchedule.room.id) {
      return false;
    }

    final currentStartTime = _toHourMinute(selectedSchedule.startTime);
    final currentEndTime = _toHourMinute(selectedSchedule.endTime);
    if (requestedStartTime != currentStartTime ||
        requestedEndTime != currentEndTime) {
      return false;
    }

    final requestedSignature = _dayPatternSignature(requestedDayPattern);
    if (requestedSignature.isEmpty) {
      return false;
    }

    final currentPatternSignature =
        _dayPatternSignature(selectedSchedule.dayPattern);
    final currentLabelSignature =
        _dayPatternSignature(selectedSchedule.dayPatternLabel);
    final currentSignature = currentPatternSignature.isNotEmpty
        ? currentPatternSignature
        : currentLabelSignature;

    return currentSignature.isNotEmpty &&
        requestedSignature == currentSignature;
  }

  String _dayPatternSignature(String? rawPattern) {
    final dayCodes = _extractDayCodes(rawPattern);
    if (dayCodes.isEmpty) {
      return '';
    }

    final ordered = _dayOptions
        .where((option) => dayCodes.contains(option.code))
        .map((option) => option.code)
        .toList();

    return ordered.join('|');
  }

  Set<String> _extractDayCodes(String? rawPattern) {
    if (rawPattern == null || rawPattern.trim().isEmpty) {
      return <String>{};
    }

    var normalized = rawPattern.toUpperCase().trim();
    normalized = normalized
        .replaceAll('MONDAY', 'M')
        .replaceAll('TUESDAY', 'T')
        .replaceAll('WEDNESDAY', 'W')
        .replaceAll('THURSDAY', 'TH')
        .replaceAll('FRIDAY', 'F')
        .replaceAll('SATURDAY', 'SAT')
        .replaceAll('SUNDAY', 'SUN')
        .replaceAll('&', '-')
        .replaceAll('/', '-')
        .replaceAll(',', '-')
        .replaceAll(' ', '');

    if (normalized.isEmpty) {
      return <String>{};
    }

    final result = <String>{};
    final chunks = normalized.contains('-')
        ? normalized.split('-').where((chunk) => chunk.isNotEmpty)
        : [normalized];

    for (final chunk in chunks) {
      result.addAll(_expandDayChunk(chunk));
    }

    return result;
  }

  Set<String> _expandDayChunk(String chunk) {
    if (chunk.isEmpty) {
      return <String>{};
    }

    switch (chunk) {
      case 'MWF':
        return {'M', 'W', 'F'};
      case 'TTH':
        return {'T', 'TH'};
      case 'MTWTHF':
        return {'M', 'T', 'W', 'TH', 'F'};
      case 'SATSUN':
        return {'SAT', 'SUN'};
      case 'M':
      case 'T':
      case 'W':
      case 'TH':
      case 'F':
      case 'SAT':
      case 'SUN':
        return {chunk};
    }

    final parsed = <String>{};
    var cursor = 0;
    const tokens = ['SAT', 'SUN', 'TH', 'M', 'T', 'W', 'F'];

    while (cursor < chunk.length) {
      var matched = false;
      for (final token in tokens) {
        if (chunk.startsWith(token, cursor)) {
          parsed.add(token);
          cursor += token.length;
          matched = true;
          break;
        }
      }

      if (!matched) {
        break;
      }
    }

    if (cursor != chunk.length) {
      return <String>{};
    }

    return parsed;
  }

  ScheduleItem? _selectedScheduleFromProvider() {
    final semester = ref.read(selectedSemesterProvider);
    final schedules =
        ref.read(scheduleProvider(semester)).valueOrNull?.schedules;
    if (schedules == null || _selectedScheduleId == null) {
      return null;
    }

    for (final schedule in schedules) {
      if (schedule.id == _selectedScheduleId) {
        return schedule;
      }
    }

    return null;
  }

  List<String> _presetDayPatternOptions(ScheduleItem? selectedSchedule) {
    final options = List<String>.from(_defaultPresetDayPatterns);
    final inferred = selectedSchedule != null
        ? _normalizePresetDayPattern(selectedSchedule)
        : null;

    if (inferred != null && !options.contains(inferred)) {
      options.insert(0, inferred);
    }

    return options;
  }

  String? _normalizePresetDayPattern(ScheduleItem schedule) {
    final candidates = [schedule.dayPattern, schedule.dayPatternLabel];
    for (final raw in candidates) {
      final normalized = raw.toUpperCase().replaceAll(' ', '');
      final compact = normalized.replaceAll('-', '');
      if (normalized.isEmpty) {
        continue;
      }

      if (compact.contains('MTWTHF')) {
        return 'MTWTHF';
      }
      if (compact.contains('MWF')) {
        return 'MWF';
      }
      if (compact.contains('TTH')) {
        return 'TTH';
      }
      if (normalized.contains('SAT') && normalized.contains('SUN')) {
        return 'SATSUN';
      }
      if (normalized.contains('SAT')) {
        return 'SAT';
      }
      if (normalized.contains('SUN')) {
        return 'SUN';
      }

      // Keep uncommon but valid patterns (e.g. M-T-TH-F) available in preset mode.
      if (normalized.contains('-')) {
        return normalized;
      }
    }

    return null;
  }

  Set<String> _customDaysFromPattern(String pattern) {
    final normalized = pattern.toUpperCase().replaceAll(' ', '');

    switch (normalized) {
      case 'MWF':
        return {'M', 'W', 'F'};
      case 'TTH':
        return {'T', 'TH'};
      case 'MTWTHF':
        return {'M', 'T', 'W', 'TH', 'F'};
      case 'SAT':
        return {'SAT'};
      case 'SUN':
        return {'SUN'};
      case 'SATSUN':
        return {'SAT', 'SUN'};
      default:
        if (normalized.isEmpty) {
          return <String>{};
        }

        // Support direct single-day patterns (M, T, W, TH, F, SAT, SUN)
        // and hyphenated combinations (e.g. M-T-TH-F).
        final tokens = normalized.contains('-')
            ? normalized.split('-').where((token) => token.isNotEmpty)
            : [normalized];

        final validCodes = _dayOptions.map((option) => option.code).toSet();
        final selected = <String>{};

        for (final token in tokens) {
          if (validCodes.contains(token)) {
            selected.add(token);
          }
        }

        return selected;
    }
  }

  String? _resolveCustomDayPattern() {
    final orderedCodes = _dayOptions
        .where((option) => _selectedCustomDays.contains(option.code))
        .map((option) => option.code)
        .toList();

    if (orderedCodes.isEmpty) {
      return null;
    }

    final sequenceKey = orderedCodes.join('|');
    switch (sequenceKey) {
      case 'M|W|F':
        return 'MWF';
      case 'T|TH':
        return 'TTH';
      case 'M|T|W|TH|F':
        return 'MTWTHF';
      case 'SAT':
        return 'SAT';
      case 'SUN':
        return 'SUN';
      default:
        // Allow valid ad-hoc combinations beyond presets (e.g. W, M-TH, M-T-TH-F).
        return orderedCodes.join('-');
    }
  }

  List<_PresetTimeSlot> _presetTimeSlotOptions(ScheduleItem? selectedSchedule) {
    final slots = List<_PresetTimeSlot>.from(_defaultPresetTimeSlots);
    if (selectedSchedule == null) {
      return slots;
    }

    final start = _toHourMinute(selectedSchedule.startTime);
    final end = _toHourMinute(selectedSchedule.endTime);
    final key = _timeSlotKey(start, end);
    final exists = slots.any((slot) => slot.key == key);

    if (!exists && start.isNotEmpty && end.isNotEmpty) {
      final startLabel = selectedSchedule.startTime12h.trim().isNotEmpty
          ? selectedSchedule.startTime12h
          : start;
      final endLabel = selectedSchedule.endTime12h.trim().isNotEmpty
          ? selectedSchedule.endTime12h
          : end;

      slots.insert(
        0,
        _PresetTimeSlot(
          key: key,
          label: '$startLabel - $endLabel (Current)',
          start: start,
          end: end,
        ),
      );
    }

    return slots;
  }

  _PresetTimeSlot? _selectedPresetSlot(ScheduleItem? selectedSchedule) {
    if (_selectedPresetTimeSlotKey == null) {
      return null;
    }

    final options = _presetTimeSlotOptions(selectedSchedule);
    for (final slot in options) {
      if (slot.key == _selectedPresetTimeSlotKey) {
        return slot;
      }
    }

    return null;
  }

  String _timeSlotKey(String start, String end) {
    return '$start|$end';
  }

  List<Map<String, dynamic>> _filterRooms(
    List<Map<String, dynamic>> rooms, {
    required int? requiredCapacity,
  }) {
    final filtered = <Map<String, dynamic>>[];

    for (final room in rooms) {
      final roomId = _toInt(room['id']);
      if (roomId == null) {
        continue;
      }

      if (requiredCapacity != null && requiredCapacity > 0) {
        final roomCapacity = _toInt(room['capacity']);
        if (roomCapacity != null && roomCapacity < requiredCapacity) {
          continue;
        }
      }

      filtered.add(room);
    }

    filtered.sort((a, b) {
      final labelA = _roomLabel(a).toLowerCase();
      final labelB = _roomLabel(b).toLowerCase();
      return labelA.compareTo(labelB);
    });

    return filtered;
  }

  Map<String, dynamic>? _findRoomById(
    List<Map<String, dynamic>> rooms,
    int? roomId,
  ) {
    if (roomId == null) {
      return null;
    }

    for (final room in rooms) {
      if (_toInt(room['id']) == roomId) {
        return room;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _withSelectedRoomOption(
    List<Map<String, dynamic>> rooms,
    Map<String, dynamic>? selectedRoom,
    int? selectedRoomId,
  ) {
    if (selectedRoomId == null) {
      return rooms;
    }

    final existsInList =
        rooms.any((room) => _toInt(room['id']) == selectedRoomId);
    if (existsInList || selectedRoom == null) {
      return rooms;
    }

    return [selectedRoom, ...rooms];
  }

  String _roomLabel(Map<String, dynamic> room) {
    final id = _toInt(room['id']) ?? 0;
    final code = _valueOrFallback(
      room['code'] ?? room['name'],
      fallback: 'Room $id',
    );
    final name =
        (room['name'] is String) ? (room['name'] as String).trim() : '';
    final building =
        (room['building'] is String) ? (room['building'] as String).trim() : '';
    final capacity = _toInt(room['capacity']);

    final parts = <String>[];
    if (name.isNotEmpty && name != code) {
      parts.add(name);
    }
    if (building.isNotEmpty) {
      parts.add(building);
    }
    if (capacity != null && capacity > 0) {
      parts.add('Cap $capacity');
    }

    if (parts.isEmpty) {
      return code;
    }

    return '$code • ${parts.join(' • ')}';
  }
}

class _SelectField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _SelectField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedValue =
        value != null && items.any((item) => item.value == value);

    return DropdownButtonFormField<T>(
      initialValue: hasSelectedValue ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.whiteColor,
      ),
      hint: Text(
        hint,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          color: Colors.grey.shade400,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      dropdownColor: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(12),
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }
}

class _DayPatternOption {
  final String label;
  final String code;

  const _DayPatternOption({required this.label, required this.code});
}

class _PresetTimeSlot {
  final String key;
  final String label;
  final String start;
  final String end;

  const _PresetTimeSlot({
    required this.key,
    required this.label,
    required this.start,
    required this.end,
  });
}

class _TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: '--:-- --',
        suffixIcon: const Icon(Icons.access_time_rounded),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final Color color;

  const _InlineNotice({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RequestSummaryBanner extends StatelessWidget {
  final String selectedFilter;
  final int totalCount;
  final int pendingCount;

  const _RequestSummaryBanner({
    required this.selectedFilter,
    required this.totalCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardPrimaryStart, AppColors.cardPrimaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardPrimaryStart.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Tracker',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Filter: $selectedFilter',
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFFE0E7FF),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _BannerPill(
                icon: Icons.assignment_outlined,
                text: '$totalCount results',
              ),
              _BannerPill(
                icon: Icons.hourglass_top_outlined,
                text: '$pendingCount pending',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BannerPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isCancelling;
  final VoidCallback onCancel;

  const _RequestCard({
    required this.request,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = _effectiveRequestStatus(request);
    final statusLabel = _requestStatusLabel(request, status);
    final statusColor = _statusColor(status);
    final adminStatus = _normalizedStatus(request['admin_status']);
    final departmentHeadStatus =
        _normalizedStatus(request['department_head_status']);

    final schedule = _asMap(request['schedule']);
    final subject = _asMap(schedule['subject']);
    final room = _asMap(schedule['room']);

    final subjectCode = _valueOrFallback(subject['code'], fallback: 'SUBJ');
    final subjectTitle =
        _valueOrFallback(subject['title'], fallback: 'No subject title');
    final section = _valueOrFallback(schedule['section'], fallback: 'General');
    final dayPattern = _valueOrFallback(
      schedule['day_pattern_label'] ?? schedule['day_pattern'],
      fallback: 'Day pattern not set',
    );
    final timeRange =
        '${_valueOrFallback(schedule['start_time_12h'] ?? schedule['start_time'], fallback: '--')} - ${_valueOrFallback(schedule['end_time_12h'] ?? schedule['end_time'], fallback: '--')}';
    final roomCode = _valueOrFallback(room['code'], fallback: 'No room');
    final reason = _valueOrFallback(
      request['request_reason'],
      fallback: 'No reason provided.',
    );

    final canCancel = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
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
                      '$subjectCode • $section',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subjectTitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaTag(icon: Icons.schedule_rounded, text: timeRange),
              _MetaTag(icon: Icons.event_note_outlined, text: dayPattern),
              _MetaTag(icon: Icons.location_on_outlined, text: roomCode),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ApprovalTag(
                label: 'Admin: ${_titleCase(adminStatus)}',
                color: _statusColor(adminStatus),
              ),
              _ApprovalTag(
                label: 'Dept Head: ${_titleCase(departmentHeadStatus)}',
                color: _statusColor(departmentHeadStatus),
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: isCancelling ? null : onCancel,
                icon: isCancelling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close_rounded, size: 16),
                label: Text(
                  isCancelling ? 'Cancelling...' : 'Cancel Request',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardChipSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalTag extends StatelessWidget {
  final String label;
  final Color color;

  const _ApprovalTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RequestsEmptyState extends StatelessWidget {
  const _RequestsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 32,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'No schedule change requests',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Requests will appear here when submitted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _RequestsErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 30, color: AppColors.error),
          const SizedBox(height: 8),
          const Text(
            'Unable to load requests',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

String _valueOrFallback(dynamic value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

String _normalizedStatus(dynamic status) {
  if (status is String && status.trim().isNotEmpty) {
    return status.trim().toLowerCase();
  }
  return 'pending';
}

String _normalizedOptionalStatus(dynamic status) {
  if (status is String && status.trim().isNotEmpty) {
    return status.trim().toLowerCase();
  }
  return '';
}

String _effectiveRequestStatus(Map<String, dynamic> request) {
  final fallbackStatus = _normalizedStatus(request['status']);
  final adminStatus = _normalizedOptionalStatus(request['admin_status']);
  final departmentHeadStatus =
      _normalizedOptionalStatus(request['department_head_status']);

  if (adminStatus == 'rejected' || departmentHeadStatus == 'rejected') {
    return 'rejected';
  }

  if (adminStatus == 'cancelled' || departmentHeadStatus == 'cancelled') {
    return 'cancelled';
  }

  final hasApproverStatuses =
      adminStatus.isNotEmpty || departmentHeadStatus.isNotEmpty;

  if (hasApproverStatuses) {
    if (adminStatus == 'approved' && departmentHeadStatus == 'approved') {
      return 'approved';
    }

    if (adminStatus == 'pending' || departmentHeadStatus == 'pending') {
      return 'pending';
    }

    // One approver has acted while the other is not finalized yet.
    if (adminStatus == 'approved' || departmentHeadStatus == 'approved') {
      return 'pending';
    }
  }

  return fallbackStatus;
}

String _requestStatusLabel(Map<String, dynamic> request, String status) {
  if (_isPartiallyApproved(request)) {
    return 'Partially Approved';
  }

  return _titleCase(status.isEmpty ? 'pending' : status);
}

bool _isPartiallyApproved(Map<String, dynamic> request) {
  final adminStatus = _normalizedOptionalStatus(request['admin_status']);
  final departmentHeadStatus =
      _normalizedOptionalStatus(request['department_head_status']);

  final hasExactlyOneApproved =
      (adminStatus == 'approved' && departmentHeadStatus != 'approved') ||
          (departmentHeadStatus == 'approved' && adminStatus != 'approved');

  if (!hasExactlyOneApproved) {
    return false;
  }

  // Do not show partial label when already finalized.
  if (adminStatus == 'rejected' ||
      departmentHeadStatus == 'rejected' ||
      adminStatus == 'cancelled' ||
      departmentHeadStatus == 'cancelled') {
    return false;
  }

  return true;
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }

  final normalized = value.replaceAll('_', ' ').trim().toLowerCase();
  final words = normalized.split(' ');

  return words
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

Color _statusColor(String status) {
  switch (status) {
    case 'approved':
      return AppColors.cardPrimaryEnd;
    case 'rejected':
    case 'cancelled':
      return AppColors.error;
    case 'pending':
    default:
      return AppColors.warning;
  }
}

List<dynamic>? _extractFirstList(dynamic source) {
  if (source is List) {
    return source;
  }

  if (source is! Map<String, dynamic>) {
    return null;
  }

  const candidateKeys = [
    'data',
    'items',
    'results',
    'rooms',
    'hydra:member',
    'member',
    'content',
    'values',
  ];

  for (final key in candidateKeys) {
    final list = _extractFirstList(source[key]);
    if (list != null) {
      return list;
    }
  }

  for (final value in source.values) {
    final list = _extractFirstList(value);
    if (list != null) {
      return list;
    }
  }

  return null;
}
