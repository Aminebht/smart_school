import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AlertModel {
  final int alertId;
  final int deviceId;
  final String alertType;
  final String severity;
  final String message;
  final DateTime timestamp;
  final bool resolved;
  final DateTime? resolvedAt;
  final int? resolvedByUserId;
  
  AlertModel({
    required this.alertId,
    required this.deviceId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.resolved,
    this.resolvedAt,
    this.resolvedByUserId,
  });
  
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alert_id'],
      deviceId: json['device_id'],
      alertType: json['alert_type'],
      severity: json['severity'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      resolved: json['resolved'] ?? false,
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at']) 
          : null,
      resolvedByUserId: json['resolved_by_user_id'],
    );
  }
  
  // Get color based on severity
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }
  
  // Get icon based on alert type
  IconData get alertIcon {
    switch (alertType.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'motion':
        return Icons.motion_photos_on;
      case 'door':
        return Icons.door_front_door;
      case 'gas':
        return Icons.air;
      case 'smoke':
        return Icons.cloud;
      case 'security':
        return Icons.security;
      case 'maintenance':
        return Icons.build;
      case 'system':
        return Icons.computer;
      default:
        return Icons.warning;
    }
  }
  
  // Create a title from alert type and severity
  String get title {
    final formattedType = alertType.split('_')
      .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
    
    return '$formattedType ${severity.toLowerCase() == 'info' ? 'Notification' : 'Alert'}';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'device_id': deviceId,
      'alert_type': alertType,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'resolved': resolved,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by_user_id': resolvedByUserId,
    };
  }
}