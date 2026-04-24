import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_mobile/app/configs/theme.dart';
import 'package:scheduling_mobile/providers/api_provider.dart';
import 'package:scheduling_mobile/screens/schedule_change_request_screen.dart';
import 'package:scheduling_mobile/services/api_service.dart';

class _FakeApiService extends ApiService {
  _FakeApiService({
    this.throwConflictCheckError = false,
    this.returnConflictOnCheck = false,
    this.conflictCheckDelay = Duration.zero,
  }) : super(enableNetworkLogs: false);

  final bool throwConflictCheckError;
  final bool returnConflictOnCheck;
  final Duration conflictCheckDelay;
  int createRequestCallCount = 0;

  @override
  Future<List<dynamic>> listScheduleChangeRequests({
    String? status,
    int limit = 100,
  }) async {
    return const <dynamic>[];
  }

  @override
  Future<Map<String, dynamic>> listRooms({
    String? search,
    int limit = 200,
  }) async {
    return <String, dynamic>{
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'code': 'R101',
          'name': 'Room 101',
          'capacity': 45,
        },
        <String, dynamic>{
          'id': 2,
          'code': 'R102',
          'name': 'Room 102',
          'capacity': 60,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> getFacultySchedule(String? semester) async {
    return <String, dynamic>{
      'data': <String, dynamic>{
        'semester': semester ?? '1st Semester',
        'schedules': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 10,
            'subject': <String, dynamic>{
              'id': 1,
              'code': 'CS101',
              'title': 'Intro to CS',
              'units': 3,
            },
            'room': <String, dynamic>{
              'id': 1,
              'code': 'R101',
              'name': 'Room 101',
              'capacity': 45,
            },
            'day_pattern': 'MWF',
            'day_pattern_label': 'Mon-Wed-Fri',
            'days': <String>['Mon', 'Wed', 'Fri'],
            'start_time': '07:00',
            'end_time': '08:30',
            'start_time_12h': '7:00 AM',
            'end_time_12h': '8:30 AM',
            'section': 'A',
            'enrolled_students': 30,
            'semester': semester ?? '1st Semester',
            'status': 'active',
          },
        ],
        'stats': <String, dynamic>{
          'total_hours': 0,
          'total_classes': 1,
          'total_students': 30,
          'total_rooms': 1,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> checkScheduleChangeConflict(
      Map<String, dynamic> data) async {
    if (conflictCheckDelay > Duration.zero) {
      await Future<void>.delayed(conflictCheckDelay);
    }

    if (throwConflictCheckError) {
      throw Exception('network unavailable');
    }

    if (returnConflictOnCheck) {
      return <String, dynamic>{
        'has_conflict': true,
        'conflicts': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'room_time_conflict',
            'message': 'Room R102 is already occupied for this time slot.',
          },
        ],
      };
    }

    return <String, dynamic>{
      'has_conflict': false,
      'conflicts': <Map<String, dynamic>>[],
    };
  }

  @override
  Future<Map<String, dynamic>> createScheduleChangeRequest(
      Map<String, dynamic> data) async {
    createRequestCallCount++;
    return <String, dynamic>{'data': data};
  }
}

Finder _findDropdownField(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<int> &&
        widget.decoration?.labelText == label,
    description: 'Dropdown field with label $label',
  );
}

Future<void> _pumpUi(WidgetTester tester, {int milliseconds = 450}) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: milliseconds));
}

Future<void> _openNewRequestAndSelectClass(WidgetTester tester) async {
  await tester.tap(find.text('New Request'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));

  final classField = _findDropdownField('Class');
  expect(classField, findsOneWidget);

  await tester.tap(classField);
  await _pumpUi(tester, milliseconds: 350);
  await tester.tap(find.text('CS101 • A').last);
  await _pumpUi(tester, milliseconds: 500);
}

Future<void> _selectAlternateRoom(WidgetTester tester) async {
  final roomField = _findDropdownField('Room');
  expect(roomField, findsOneWidget);

  await tester.tap(roomField);
  await _pumpUi(tester, milliseconds: 350);

  final alternateRoomOption = find.byWidgetPredicate(
    (widget) => widget is Text && (widget.data?.contains('R102') ?? false),
    description: 'Alternate room option containing R102',
  );
  expect(alternateRoomOption, findsWidgets);

  await tester.tap(alternateRoomOption.last);
  await _pumpUi(tester, milliseconds: 500);
}

Widget _buildHarness(ApiService apiService) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWith((ref) => apiService),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ScheduleChangeRequestScreen(),
    ),
  );
}

Future<void> _pumpScheduleRequestScreen(
  WidgetTester tester,
  _FakeApiService apiService,
) async {
  addTearDown(apiService.dispose);
  await tester.pumpWidget(_buildHarness(apiService));
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('New Request button opens schedule request bottom sheet',
      (tester) async {
    final apiService = _FakeApiService();

    await _pumpScheduleRequestScreen(tester, apiService);

    expect(find.text('New Request'), findsOneWidget);

    await tester.tap(find.text('New Request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('New Schedule Change Request'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Submit Request stays disabled when no effective change is made',
      (tester) async {
    final apiService = _FakeApiService();

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text(
        'No changes detected from the current schedule. Please update day pattern, time, or room to submit.',
      ),
      findsOneWidget,
    );

    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit Request'),
    );
    expect(submitButton.onPressed, isNull);
  });

  testWidgets('Live conflict detector shows pre-submit conflict details',
      (tester) async {
    final apiService = _FakeApiService(returnConflictOnCheck: true);

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);
    await _pumpUi(tester, milliseconds: 900);

    expect(find.text('Live Conflict Detector'), findsOneWidget);
    expect(
      find.text('Room R102 is already occupied for this time slot.'),
      findsWidgets,
    );
    expect(apiService.createRequestCallCount, 0);
  });

  testWidgets(
      'Live conflict detector shows loading state while check is in-flight',
      (tester) async {
    final apiService = _FakeApiService(
      conflictCheckDelay: const Duration(milliseconds: 900),
    );

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);

    expect(
      find.text('Checking conflicts for selected schedule…'),
      findsOneWidget,
    );

    await _pumpUi(tester, milliseconds: 1000);

    expect(
      find.text('Checking conflicts for selected schedule…'),
      findsNothing,
    );
    expect(
      find.text('No conflicts detected for the selected day, time, and room.'),
      findsOneWidget,
    );
    expect(apiService.createRequestCallCount, 0);
  });

  testWidgets('Live conflict detector shows fallback error when check fails',
      (tester) async {
    final apiService = _FakeApiService(throwConflictCheckError: true);

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);
    await _pumpUi(tester, milliseconds: 900);

    expect(find.text('Could not check conflicts right now.'), findsOneWidget);
    expect(find.text('Live Conflict Detector'), findsNothing);
    expect(apiService.createRequestCallCount, 0);
  });

  testWidgets('Conflict check unavailable dialog appears and No aborts submit',
      (tester) async {
    final apiService = _FakeApiService(throwConflictCheckError: true);

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);
    await _selectAlternateRoom(tester);

    final submitButtonFinder =
        find.widgetWithText(FilledButton, 'Submit Request');
    final submitButton = tester.widget<FilledButton>(submitButtonFinder);
    expect(submitButton.onPressed, isNotNull);

    await tester.tap(submitButtonFinder);
    await _pumpUi(tester, milliseconds: 800);

    expect(find.text('Conflict check unavailable'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'No'));
    await _pumpUi(tester, milliseconds: 500);

    expect(find.text('Conflict check unavailable'), findsNothing);
    expect(apiService.createRequestCallCount, 0);
    expect(find.text('New Schedule Change Request'), findsOneWidget);
    expect(find.text('Schedule change request submitted.'), findsNothing);
  });

  testWidgets(
      'Conflict check unavailable dialog Continue submits and closes sheet',
      (tester) async {
    final apiService = _FakeApiService(throwConflictCheckError: true);

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);
    await _selectAlternateRoom(tester);

    final submitButtonFinder =
        find.widgetWithText(FilledButton, 'Submit Request');
    await tester.tap(submitButtonFinder);
    await _pumpUi(tester, milliseconds: 800);

    expect(find.text('Conflict check unavailable'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await _pumpUi(tester, milliseconds: 700);

    expect(apiService.createRequestCallCount, 1);
    expect(find.text('New Schedule Change Request'), findsNothing);
    expect(find.text('Schedule change request submitted.'), findsOneWidget);
  });

  testWidgets(
      'Submit Request succeeds without unavailable dialog when conflict check passes',
      (tester) async {
    final apiService = _FakeApiService();

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);
    await _selectAlternateRoom(tester);

    final submitButtonFinder =
        find.widgetWithText(FilledButton, 'Submit Request');
    final submitButton = tester.widget<FilledButton>(submitButtonFinder);
    expect(submitButton.onPressed, isNotNull);

    await tester.tap(submitButtonFinder);
    await _pumpUi(tester, milliseconds: 700);

    expect(find.text('Conflict check unavailable'), findsNothing);
    expect(apiService.createRequestCallCount, 1);
    expect(find.text('New Schedule Change Request'), findsNothing);
    expect(find.text('Schedule change request submitted.'), findsOneWidget);
  });

  testWidgets(
      'Conflict detected dialog blocks submit and shows resolution guidance',
      (tester) async {
    final apiService = _FakeApiService(returnConflictOnCheck: true);

    await _pumpScheduleRequestScreen(tester, apiService);

    await _openNewRequestAndSelectClass(tester);
    await _selectAlternateRoom(tester);

    final submitButtonFinder =
        find.widgetWithText(FilledButton, 'Submit Request');
    await tester.tap(submitButtonFinder);
    await _pumpUi(tester, milliseconds: 900);

    expect(find.textContaining('Conflicts Detected'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Room Conflict'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await _pumpUi(tester, milliseconds: 700);

    expect(find.textContaining('Conflicts Detected'), findsNothing);
    expect(apiService.createRequestCallCount, 0);
    expect(find.text('New Schedule Change Request'), findsOneWidget);
    expect(
      find.text(
          'Resolve the detected conflicts before submitting this request.'),
      findsOneWidget,
    );
    expect(find.text('Schedule change request submitted.'), findsNothing);
  });
}
