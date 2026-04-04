// lib/models/schedule_model.dart

import 'dashboard_model.dart' as dashboard;

class ScheduleResponse {
  final AcademicYearInfo? academicYear;
  final String semester;
  final List<dashboard.ScheduleItem> schedules;
  final ScheduleStats stats;

  ScheduleResponse({
    this.academicYear,
    required this.semester,
    required this.schedules,
    required this.stats,
  });

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleResponse(
      academicYear: json['academic_year'] != null
          ? AcademicYearInfo.fromJson(json['academic_year'])
          : null,
      semester: json['semester'] ?? '',
      schedules: (json['schedules'] as List?)
            ?.map((s) => dashboard.ScheduleItem.fromJson(
              Map<String, dynamic>.from(s as Map),
              ))
              .toList() ??
          [],
      stats: ScheduleStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'academic_year': academicYear?.toJson(),
        'semester': semester,
        'schedules': schedules.map((s) => s.toJson()).toList(),
        'stats': stats.toJson(),
      };
}

class AcademicYearInfo {
  final int id;
  final String year;

  AcademicYearInfo({
    required this.id,
    required this.year,
  });

  factory AcademicYearInfo.fromJson(Map<String, dynamic> json) {
    return AcademicYearInfo(
      id: json['id'] ?? 0,
      year: json['year'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'year': year,
      };
}

class ScheduleStats {
  final double totalHours;
  final int totalClasses;
  final int totalStudents;
  final int totalRooms;

  ScheduleStats({
    required this.totalHours,
    required this.totalClasses,
    required this.totalStudents,
    required this.totalRooms,
  });

  factory ScheduleStats.fromJson(Map<String, dynamic> json) {
    return ScheduleStats(
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalClasses: json['total_classes'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      totalRooms: json['total_rooms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_hours': totalHours,
        'total_classes': totalClasses,
        'total_students': totalStudents,
        'total_rooms': totalRooms,
      };
}

class WeeklyScheduleResponse {
  final String semester;
  final Map<String, List<dashboard.ScheduleItem>> weekly;

  WeeklyScheduleResponse({
    required this.semester,
    required this.weekly,
  });

  factory WeeklyScheduleResponse.fromJson(Map<String, dynamic> json) {
    final weeklyJson = json['weekly'] as Map<String, dynamic>? ?? {};
    final weekly = <String, List<dashboard.ScheduleItem>>{};

    weeklyJson.forEach((day, schedules) {
      weekly[day] = (schedules as List?)
              ?.map((s) => dashboard.ScheduleItem.fromJson(
                    Map<String, dynamic>.from(s as Map),
                  ))
              .toList() ??
          [];
    });

    return WeeklyScheduleResponse(
      semester: json['semester'] ?? '',
      weekly: weekly,
    );
  }

  Map<String, dynamic> toJson() => {
        'semester': semester,
        'weekly': weekly.map(
          (k, v) => MapEntry(k, v.map((s) => s.toJson()).toList()),
        ),
      };
}
