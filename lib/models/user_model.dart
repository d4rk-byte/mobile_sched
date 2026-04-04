// lib/models/user_model.dart

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String fullName;
  final String? employeeId;
  final String? position;
  final String? address;
  final String? otherDesignation;
  final Department? department;
  final College? college;
  final bool profileComplete;
  final List<String> missingProfileFields;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.middleName,
    this.lastName,
    required this.fullName,
    this.employeeId,
    this.position,
    this.address,
    this.otherDesignation,
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
      middleName: json['middle_name'],
      lastName: json['last_name'],
      fullName: json['full_name'] ?? '',
      employeeId: json['employee_id'],
      position: json['position'],
      address: json['address'],
      otherDesignation: json['other_designation'],
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      college:
          json['college'] != null ? College.fromJson(json['college']) : null,
      profileComplete: json['profile_complete'] ?? false,
      missingProfileFields:
          List<String>.from(json['missing_profile_fields'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'full_name': fullName,
        'employee_id': employeeId,
        'position': position,
        'address': address,
        'other_designation': otherDesignation,
        'department': department?.toJson(),
        'college': college?.toJson(),
        'profile_complete': profileComplete,
        'missing_profile_fields': missingProfileFields,
      };
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
      };
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
      };
}
