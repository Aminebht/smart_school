import 'package:flutter/material.dart';

class SecurityEventModel {
  final int eventId;
  final int deviceId;
  final String deviceName;
  final String eventType;
  final String description;
  final DateTime timestamp;
  final bool isAcknowledged;
  final String? classroomName;

  SecurityEventModel({
    required this.eventId,
    required this.deviceId,
    required this.deviceName,
    required this.eventType,
    required this.description,
    required this.timestamp,
    required this.isAcknowledged,
    this.classroomName,
  });

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      eventId: json['event_id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'] ?? 'Unknown Device',
      eventType: json['event_type'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      isAcknowledged: json['is_acknowledged'] ?? false,
      classroomName: json['classroom_name'],
    );
  }

  Color get eventColor {
    switch (eventType.toLowerCase()) {
      case 'unauthorized_access':
      case 'door_forced':
      case 'window_breach':
      case 'alarm_triggered':
        return Colors.red;
      case 'access_granted':
      case 'door_secured':
      case 'window_secured':
        return Colors.green;
      case 'motion_detected':
        return Colors.blue;
      case 'access_denied':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get eventIcon {
    switch (eventType.toLowerCase()) {
      case 'unauthorized_access':
        return Icons.no_accounts;
      case 'door_forced':
        return Icons.door_sliding_outlined;
      case 'window_breach':
        return Icons.sensor_window_outlined;
      case 'alarm_triggered':
        return Icons.alarm_on;
      case 'access_granted':
        return Icons.check_circle;
      case 'access_denied':
        return Icons.cancel;
      case 'door_secured':
        return Icons.lock;
      case 'door_unlocked':
        return Icons.lock_open;
      case 'motion_detected':
        return Icons.motion_photos_on;
      default:
        return Icons.event_note;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  SecurityEventModel copyWith({
  int? eventId,
  int? ruleId,
  int? deviceId,
  String? eventType,
  String? description,
  String? deviceName,
  String? location,
  String? deviceType,
  String? severity,
  DateTime? timestamp,
  bool? isAcknowledged,
  DateTime? acknowledgedAt,
  int? acknowledgedById,
}) {
  return SecurityEventModel(
    eventId: eventId ?? this.eventId,
    deviceId: deviceId ?? this.deviceId,
    eventType: eventType ?? this.eventType,
    description: description ?? this.description,
    deviceName: deviceName ?? this.deviceName,
    timestamp: timestamp ?? this.timestamp,
    isAcknowledged: isAcknowledged ?? this.isAcknowledged,

  );
}
}