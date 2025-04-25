// lib/core/models/alert_model.dart

import 'package:flutter/material.dart';

class AlertModel {
  final int alertId;
  final int deviceId;
  final String alertType;
  final String severity;
  final String message;
  final DateTime timestamp;
  final bool resolved;
  final DateTime? resolvedAt;
  final int? resolvedById;
  final String? deviceName;
  final String? deviceLocation;

  AlertModel({
    required this.alertId,
    required this.deviceId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.resolved,
    this.resolvedAt,
    this.resolvedById,
    this.deviceName,
    this.deviceLocation,
  });

  // Define these getters to fix the errors
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get alertIcon {
    switch (alertType.toLowerCase()) {
      case 'security':
        return Icons.security;
      case 'motion':
        return Icons.directions_run;
      case 'temperature':
        return Icons.thermostat;
      case 'smoke':
        return Icons.smoke_free;
      case 'water':
        return Icons.water_drop;
      case 'network':
        return Icons.wifi;
      case 'battery':
        return Icons.battery_alert;
      default:
        // Default icon based on severity
        switch (severity.toLowerCase()) {
          case 'critical':
            return Icons.error;
          case 'warning':
            return Icons.warning;
          default:
            return Icons.info;
        }
    }
  }
  
  // Add title getter for compatibility with RecentAlerts widget
  String get title {
    return alertType;
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
  return AlertModel(
    alertId: json['alert_id'],
    deviceId: json['device_id'],
    alertType: json['alert_type'] ?? 'unknown',
    severity: json['severity'] ?? 'info',
    message: json['message'] ?? 'No details available',
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
    resolved: json['resolved'] ?? false,
    resolvedAt: json['resolved_at'] != null 
        ? DateTime.parse(json['resolved_at']) 
        : null,
    resolvedById: json['resolved_by_user_id'],
    deviceName: json['device_name'] ?? json['devices']?['model'] ?? 'Unknown Device',
    deviceLocation: json['device_location'] ?? json['devices']?['location'] ?? 'Unknown Location',
  );
}
}