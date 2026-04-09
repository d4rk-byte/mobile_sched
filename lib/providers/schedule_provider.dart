// lib/providers/schedule_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_model.dart';
import 'api_provider.dart';

final selectedSemesterProvider = StateProvider<String?>((ref) => null);

final scheduleProvider =
    FutureProvider.family<ScheduleResponse, String?>((ref, semester) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getFacultySchedule(semester);
  return ScheduleResponse.fromJson(response);
});

final weeklyScheduleProvider =
    FutureProvider.family<WeeklyScheduleResponse, String?>(
        (ref, semester) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getWeeklySchedule(semester);
  return WeeklyScheduleResponse.fromJson(response);
});
