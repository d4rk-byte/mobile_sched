// lib/services/class_notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/dashboard_model.dart';

class ClassNotificationService {
  static final ClassNotificationService _instance =
      ClassNotificationService._internal();
  factory ClassNotificationService() => _instance;
  ClassNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to schedule screen
  }

  /// Schedules notifications for all upcoming classes today
  /// - 5 minutes before class starts
  /// - At the exact start time
  Future<void> scheduleClassNotifications(
      List<ScheduleItem> todaySchedules) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Cancel all existing class notifications first
    await cancelAllClassNotifications();

    final now = DateTime.now();

    for (final schedule in todaySchedules) {
      final startTime = _parseTimeToDateTime(schedule.startTime);
      if (startTime == null) continue;

      // Skip if the class has already started
      if (startTime.isBefore(now)) continue;

      final subjectCode = schedule.subject.code;
      final subjectTitle = schedule.subject.title;
      final roomCode = schedule.room.code;
      final roomName = schedule.room.name;
      final section = schedule.section?.trim();
      final sectionLabel =
          section != null && section.isNotEmpty ? 'Section $section • ' : '';
      final roomDisplay = roomName != null ? '$roomCode ($roomName)' : roomCode;
      final notificationBody =
          '$subjectCode - $subjectTitle\n${sectionLabel}Room $roomDisplay';

      // Schedule "5 minutes before" notification
      final fiveMinBefore = startTime.subtract(const Duration(minutes: 5));
      if (fiveMinBefore.isAfter(now)) {
        await _scheduleNotification(
          id: schedule.id * 2, // Unique ID for 5-min reminder
          title: 'Class in 5 minutes',
          body: notificationBody,
          scheduledTime: fiveMinBefore,
        );
      }

      // Schedule "class starts now" notification
      if (startTime.isAfter(now)) {
        await _scheduleNotification(
          id: schedule.id * 2 + 1, // Unique ID for start-time reminder
          title: 'Class Starting Now',
          body: notificationBody,
          scheduledTime: startTime,
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'class_reminders',
      'Class Reminders',
      channelDescription: 'Notifications for upcoming classes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduledTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  DateTime? _parseTimeToDateTime(String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hours, minutes);
  }

  /// Cancels all scheduled class notifications
  Future<void> cancelAllClassNotifications() async {
    await _notifications.cancelAll();
  }

  /// Shows an immediate test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'class_reminders',
      'Class Reminders',
      channelDescription: 'Notifications for upcoming classes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: 0,
      title: 'Notifications Enabled',
      body: 'You will receive reminders for your classes.',
      notificationDetails: details,
    );
  }
}
