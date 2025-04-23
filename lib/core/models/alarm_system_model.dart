import 'package:flutter/material.dart';

class AlarmSystemModel {
  final int alarmId;
  final String name;
  final String description;
  final int? departmentId;
  final int? classroomId;
  final bool isActive;
  final String armStatus; // 'disarmed', 'armed_stay', 'armed_away'
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AlarmSystemModel({
    required this.alarmId,
    required this.name,
    required this.description,
    this.departmentId,
    this.classroomId,
    required this.isActive,
    required this.armStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AlarmSystemModel.fromJson(Map<String, dynamic> json) {
    return AlarmSystemModel(
      alarmId: json['alarm_id'],
      name: json['name'],
      description: json['description'] ?? '',
      departmentId: json['department_id'],
      classroomId: json['classroom_id'],
      isActive: json['is_active'] ?? false,
      armStatus: json['arm_status'] ?? 'disarmed',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'alarm_id': alarmId != 0 ? alarmId : null, // Use null for new alarms
      'name': name,
      'description': description,
      'department_id': departmentId,
      'classroom_id': classroomId,
      'is_active': isActive,
      'arm_status': armStatus,
      // Do not include created_at and updated_at for new records
      // These will be set by the database
    };
  }
  
  // Constructor for copying with modifications
  AlarmSystemModel copyWith({
    int? alarmId,
    String? name,
    String? description,
    int? departmentId,
    int? classroomId,
    bool? isActive,
    String? armStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlarmSystemModel(
      alarmId: alarmId ?? this.alarmId,
      name: name ?? this.name,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
      classroomId: classroomId ?? this.classroomId,
      isActive: isActive ?? this.isActive,
      armStatus: armStatus ?? this.armStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Get status color based on arm status
  Color get statusColor {
    switch (armStatus) {
      case 'armed_away':
        return Colors.red;
      case 'armed_stay':
        return Colors.orange;
      case 'disarmed':
      default:
        return Colors.green;
    }
  }
  
  // Get status text for display
  String get statusText {
    switch (armStatus) {
      case 'armed_away':
        return 'Armed Away';
      case 'armed_stay':
        return 'Armed Stay';
      case 'disarmed':
        return 'Disarmed';
      default:
        return armStatus;
    }
  }
  
  // Get icon for the alarm system
  IconData get icon {
    switch (armStatus) {
      case 'armed_away':
        return Icons.security;
      case 'armed_stay':
        return Icons.home;
      case 'disarmed':
        return Icons.shield_outlined;
      default:
        return Icons.security;
    }
  }

  // Get status icon for the alarm system
  IconData get statusIcon {
    switch (armStatus) {
      case 'armed_away':
        return Icons.security;
      case 'armed_stay':
        return Icons.home;
      case 'disarmed':
        return Icons.shield_outlined;
      default:
        return Icons.security;
    }
  }

  // Get display status for the alarm system
  String get displayStatus {
    switch (armStatus) {
      case 'armed_away':
        return 'Armed Away';
      case 'armed_stay':
        return 'Armed Stay';
      case 'disarmed':
        return 'Disarmed';
      default:
        return armStatus;
    }
  }

  // Get department name
  String? get departmentName {
    if (departmentId == null) return null;
    // This should properly return the department name from somewhere
    // For now, let's return a placeholder
    return 'Department $departmentId';
  }

  // Get classroom name
  String? get classroomName {
    if (classroomId == null) return null;
    // This should properly return the classroom name from somewhere
    // For now, let's return a placeholder
    return 'Classroom $classroomId';
  }
}