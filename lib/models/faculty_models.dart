// Faculty Models for Scheduling App

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String? position;
  final String? employeeId;
  final String? address;
  final Department? department;
  final College? college;
  final bool profileComplete;
  final List<String> missingProfileFields;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.fullName,
    this.position,
    this.employeeId,
    this.address,
    this.department,
    this.college,
    required this.profileComplete,
    required this.missingProfileFields,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'] ?? '',
      position: json['position'],
      employeeId: json['employee_id'],
      address: json['address'],
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      college: json['college'] != null
          ? College.fromJson(json['college'])
          : null,
      profileComplete: json['profile_complete'] ?? false,
      missingProfileFields:
          List<String>.from(json['missing_profile_fields'] ?? []),
    );
  }
}

class Department {
  final int id;
  final String name;
  final String? code;

  Department({
    required this.id,
    required this.name,
    this.code,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
    );
  }
}

class College {
  final int id;
  final String name;
  final String? code;

  College({
    required this.id,
    required this.name,
    this.code,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
    );
  }
}

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
}

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? metadata;
  final bool read;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.metadata,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      metadata: json['metadata'],
      read: json['read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
