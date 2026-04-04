// lib/models/schedule_change_request_model.dart

class ScheduleChangeRequest {
  final int id;
  final String status;
  final String adminStatus;
  final String departmentHeadStatus;
  final String? requestReason;
  final String? submittedAt;
  final String? cancelledAt;
  final String? createdAt;
  final String? updatedAt;
  final ScheduleItem? schedule;
  final Department? subjectDepartment;
  final Map<String, dynamic>? approvers;

  ScheduleChangeRequest({
    required this.id,
    required this.status,
    required this.adminStatus,
    required this.departmentHeadStatus,
    this.requestReason,
    this.submittedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.schedule,
    this.subjectDepartment,
    this.approvers,
  });

  factory ScheduleChangeRequest.fromJson(Map<String, dynamic> json) {
    return ScheduleChangeRequest(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      adminStatus: json['admin_status'] ?? '',
      departmentHeadStatus: json['department_head_status'] ?? '',
      requestReason: json['request_reason'],
      submittedAt: json['submitted_at'],
      cancelledAt: json['cancelled_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      schedule: json['schedule'] != null
          ? ScheduleItem.fromJson(json['schedule'])
          : null,
      subjectDepartment: json['subject_department'] != null
          ? Department.fromJson(json['subject_department'])
          : null,
      approvers: json['approvers'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'admin_status': adminStatus,
        'department_head_status': departmentHeadStatus,
        'request_reason': requestReason,
        'submitted_at': submittedAt,
        'cancelled_at': cancelledAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'schedule': schedule?.toJson(),
        'subject_department': subjectDepartment?.toJson(),
        'approvers': approvers,
      };
}

class Department {
  final int id;
  final String? code;
  final String name;

  Department({
    required this.id,
    this.code,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      code: json['code'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
      };
}

class ScheduleChangeRequestInput {
  final int scheduleId;
  final String dayPattern;
  final String startTime;
  final String endTime;
  final int roomId;
  final String? section;
  final String? reason;

  ScheduleChangeRequestInput({
    required this.scheduleId,
    required this.dayPattern,
    required this.startTime,
    required this.endTime,
    required this.roomId,
    this.section,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'schedule_id': scheduleId,
        'day_pattern': dayPattern,
        'start_time': startTime,
        'end_time': endTime,
        'room_id': roomId,
        'section': section,
        'reason': reason,
      };
}
