import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AlertModel {
  final String id;
  final String title;
  final String message;
  final String classroomId;
  final String? departmentId;
  final DateTime timestamp;
  final String type;
  final bool isRead;
  final DeviceStatus severity;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.classroomId,
    this.departmentId,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    required this.severity,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    DeviceStatus severity = DeviceStatus.normal;
    if (json['severity'] != null) {
      switch (json['severity']) {
        case 'warning':
          severity = DeviceStatus.warning;
          break;
        case 'critical':
          severity = DeviceStatus.critical;
          break;
        default:
          severity = DeviceStatus.normal;
      }
    }

    return AlertModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      classroomId: json['classroom_id'],
      departmentId: json['department_id'],
      timestamp: DateTime.parse(json['created_at']),
      type: json['type'],
      isRead: json['is_read'] ?? false,
      severity: severity,
    );
  }

  Map<String, dynamic> toJson() {
    String severityStr;
    switch (severity) {
      case DeviceStatus.warning:
        severityStr = 'warning';
        break;
      case DeviceStatus.critical:
        severityStr = 'critical';
        break;
      default:
        severityStr = 'normal';
    }

    return {
      'id': id,
      'title': title,
      'message': message,
      'classroom_id': classroomId,
      'department_id': departmentId,
      'created_at': timestamp.toIso8601String(),
      'type': type,
      'is_read': isRead,
      'severity': severityStr,
    };
  }

  Color get severityColor {
     switch (severity) {
      case DeviceStatus.normal:
        return AppColors.success;
      case DeviceStatus.warning:
        return AppColors.warning;
      case DeviceStatus.critical:
        return AppColors.error;
      case DeviceStatus.offline:
        return AppColors.error;
      case DeviceStatus.maintenance:
        return AppColors.warning;
      case DeviceStatus.online:
        return AppColors.success;
      default:
        return AppColors.success; // Fallback color
    }
  }

  IconData get alertIcon {
    switch (type) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'gas':
        return Icons.cloud;
      case 'motion':
        return Icons.motion_photos_on;
      case 'door':
        return Icons.meeting_room;
      case 'window':
        return Icons.window;
      case 'security':
        return Icons.security;
      default:
        return Icons.warning;
    }
  }
} 