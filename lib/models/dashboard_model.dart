// lib/models/dashboard_model.dart

class DashboardData {
  final String today;
  final AcademicYear? academicYear;
  final List<ScheduleItem> todaySchedules;
  final DashboardStats stats;

  DashboardData({
    required this.today,
    this.academicYear,
    required this.todaySchedules,
    required this.stats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      today: json['today'] ?? '',
      academicYear: json['academic_year'] != null
          ? AcademicYear.fromJson(json['academic_year'])
          : null,
      todaySchedules: (json['today_schedules'] as List?)
              ?.map((s) => ScheduleItem.fromJson(s))
              .toList() ??
          [],
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'today': today,
        'academic_year': academicYear?.toJson(),
        'today_schedules': todaySchedules.map((s) => s.toJson()).toList(),
        'stats': stats.toJson(),
      };
}

class DashboardStats {
  final double totalHours;
  final int activeClasses;
  final int totalStudents;
  final int todayCount;

  DashboardStats({
    required this.totalHours,
    required this.activeClasses,
    required this.totalStudents,
    required this.todayCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      activeClasses: json['active_classes'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      todayCount: json['today_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_hours': totalHours,
        'active_classes': activeClasses,
        'total_students': totalStudents,
        'today_count': todayCount,
      };
}

class AcademicYear {
  final int id;
  final String year;
  final String semester;

  AcademicYear({
    required this.id,
    required this.year,
    required this.semester,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'] ?? 0,
      year: json['year'] ?? '',
      semester: json['semester'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'year': year,
        'semester': semester,
      };
}

enum ScheduleTimeStatus {
  inProgress,
  upcoming,
  completed;

  String get label {
    switch (this) {
      case ScheduleTimeStatus.inProgress:
        return 'In Progress';
      case ScheduleTimeStatus.upcoming:
        return 'Upcoming';
      case ScheduleTimeStatus.completed:
        return 'Completed';
    }
  }
}

class ScheduleItem {
  final int id;
  final Subject subject;
  final Room room;
  final String dayPattern;
  final String dayPatternLabel;
  final List<String> days;
  final String startTime;
  final String endTime;
  final String startTime12h;
  final String endTime12h;
  final String? section;
  final int enrolledStudents;
  final String? updatedAt;
  final String semester;
  final AcademicYear? academicYear;
  final String status;

  /// Calculates the real-time status based on current time.
  /// - In Progress: current time is between start and end
  /// - Completed: current time is past end time
  /// - Upcoming: current time is before start time
  ScheduleTimeStatus get timeStatus {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startMinutes = _parseTimeToMinutes(startTime);
    final endMinutes = _parseTimeToMinutes(endTime);

    if (startMinutes == null || endMinutes == null) {
      return ScheduleTimeStatus.upcoming;
    }

    if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
      return ScheduleTimeStatus.inProgress;
    } else if (currentMinutes >= endMinutes) {
      return ScheduleTimeStatus.completed;
    }
    return ScheduleTimeStatus.upcoming;
  }

  int? _parseTimeToMinutes(String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return hours * 60 + minutes;
  }

  ScheduleItem({
    required this.id,
    required this.subject,
    required this.room,
    required this.dayPattern,
    required this.dayPatternLabel,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.startTime12h,
    required this.endTime12h,
    this.section,
    required this.enrolledStudents,
    this.updatedAt,
    required this.semester,
    this.academicYear,
    required this.status,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] ?? 0,
      subject: Subject.fromJson(json['subject'] ?? {}),
      room: Room.fromJson(json['room'] ?? {}),
      dayPattern: json['day_pattern'] ?? '',
      dayPatternLabel: json['day_pattern_label'] ?? '',
      days: List<String>.from(json['days'] ?? []),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      startTime12h: json['start_time_12h'] ?? '',
      endTime12h: json['end_time_12h'] ?? '',
      section: json['section'],
      enrolledStudents: json['enrolled_students'] ?? 0,
      updatedAt: json['updated_at'],
      semester: json['semester'] ?? '',
      academicYear: json['academic_year'] != null
          ? AcademicYear.fromJson(json['academic_year'])
          : null,
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject.toJson(),
        'room': room.toJson(),
        'day_pattern': dayPattern,
        'day_pattern_label': dayPatternLabel,
        'days': days,
        'start_time': startTime,
        'end_time': endTime,
        'start_time_12h': startTime12h,
        'end_time_12h': endTime12h,
        'section': section,
        'enrolled_students': enrolledStudents,
        'updated_at': updatedAt,
        'semester': semester,
        'academic_year': academicYear?.toJson(),
        'status': status,
      };
}

class Subject {
  final int id;
  final String code;
  final String title;
  final int units;
  final String? type;

  Subject({
    required this.id,
    required this.code,
    required this.title,
    required this.units,
    this.type,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      units: json['units'] ?? 0,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'units': units,
        'type': type,
      };
}

class Room {
  final int id;
  final String? name;
  final String code;
  final String? building;
  final String? floor;
  final int? capacity;

  Room({
    required this.id,
    this.name,
    required this.code,
    this.building,
    this.floor,
    this.capacity,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? 0,
      name: json['name'],
      code: json['code'] ?? '',
      building: json['building'],
      floor: json['floor'],
      capacity: json['capacity'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'building': building,
        'floor': floor,
        'capacity': capacity,
      };
}
