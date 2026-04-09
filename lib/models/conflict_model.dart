// lib/models/conflict_model.dart

class ConflictDetail {
  final String type;
  final String message;
  final ConflictSchedule? schedule;

  ConflictDetail({
    required this.type,
    required this.message,
    this.schedule,
  });

  factory ConflictDetail.fromJson(Map<String, dynamic> json) {
    return ConflictDetail(
      type: json['type'] ?? 'unknown',
      message: json['message'] ?? '',
      schedule: json['schedule'] != null
          ? ConflictSchedule.fromJson(json['schedule'])
          : null,
    );
  }

  bool get isRoomConflict => type == 'room_time_conflict';
  bool get isFacultyConflict => type == 'faculty_conflict';
  bool get isSectionConflict => type == 'section_conflict';

  String get conflictTypeLabel {
    switch (type) {
      case 'room_time_conflict':
        return 'Room Conflict';
      case 'faculty_conflict':
        return 'Faculty Conflict';
      case 'section_conflict':
        return 'Section Conflict';
      default:
        return 'Schedule Conflict';
    }
  }
}

class ConflictSchedule {
  final int? id;
  final String? dayPattern;
  final String? dayPatternLabel;
  final String? startTime;
  final String? endTime;
  final String? section;
  final ConflictRoom? room;
  final ConflictSubject? subject;
  final ConflictFaculty? faculty;

  ConflictSchedule({
    this.id,
    this.dayPattern,
    this.dayPatternLabel,
    this.startTime,
    this.endTime,
    this.section,
    this.room,
    this.subject,
    this.faculty,
  });

  factory ConflictSchedule.fromJson(Map<String, dynamic> json) {
    return ConflictSchedule(
      id: json['id'],
      dayPattern: json['day_pattern'] ?? json['dayPattern'],
      dayPatternLabel: json['day_pattern_label'] ?? json['dayPatternLabel'],
      startTime: json['start_time'] ?? json['startTime'],
      endTime: json['end_time'] ?? json['endTime'],
      section: json['section'],
      room: json['room'] != null ? ConflictRoom.fromJson(json['room']) : null,
      subject: json['subject'] != null
          ? ConflictSubject.fromJson(json['subject'])
          : null,
      faculty: json['faculty'] != null
          ? ConflictFaculty.fromJson(json['faculty'])
          : null,
    );
  }

  String get displayDayPattern => dayPatternLabel ?? dayPattern ?? 'N/A';
  String get displaySection => section ?? '—';
}

class ConflictRoom {
  final int? id;
  final String? code;
  final String? name;

  ConflictRoom({
    this.id,
    this.code,
    this.name,
  });

  factory ConflictRoom.fromJson(Map<String, dynamic> json) {
    return ConflictRoom(
      id: json['id'],
      code: json['code'],
      name: json['name'],
    );
  }

  String get displayCode => code ?? 'TBA';
}

class ConflictSubject {
  final int? id;
  final String? code;
  final String? title;
  final int? units;

  ConflictSubject({
    this.id,
    this.code,
    this.title,
    this.units,
  });

  factory ConflictSubject.fromJson(Map<String, dynamic> json) {
    return ConflictSubject(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      units: json['units'],
    );
  }

  String get displayCode => code ?? 'SUBJ';
  String get displayTitle => title ?? 'Untitled Subject';
}

class ConflictFaculty {
  final int? id;
  final String? fullName;
  final String? employeeId;

  ConflictFaculty({
    this.id,
    this.fullName,
    this.employeeId,
  });

  factory ConflictFaculty.fromJson(Map<String, dynamic> json) {
    return ConflictFaculty(
      id: json['id'],
      fullName: json['full_name'] ?? json['fullName'],
      employeeId: json['employee_id'] ?? json['employeeId'],
    );
  }

  String get displayName => fullName ?? 'Assigned faculty';
}

class ConflictCheckResult {
  final bool hasConflict;
  final List<ConflictDetail> conflicts;

  ConflictCheckResult({
    required this.hasConflict,
    required this.conflicts,
  });

  factory ConflictCheckResult.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure
    final data = json['data'] ?? json;

    final hasConflict = data['hasConflict'] ?? data['has_conflict'] ?? false;
    final conflictsList = data['conflicts'] ?? [];

    final conflicts = (conflictsList as List)
        .whereType<Map<String, dynamic>>()
        .map(ConflictDetail.fromJson)
        .toList();

    return ConflictCheckResult(
      hasConflict: hasConflict,
      conflicts: conflicts,
    );
  }
}
