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

  // Calculate these properties based on existing fields
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
      case 'error':
        return Icons.error;
      default:
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

  // Add title getter for consistency with your current code
  String get title {
    // Convert alertType to a more readable format
    final formattedType = alertType
        .split('_')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
    
    return '$formattedType Alert';
  }

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

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alert_id'],
      deviceId: json['device_id'],
      alertType: json['alert_type'],
      severity: json['severity'],
      message: json['message'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      resolved: json['resolved'] ?? false,
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at']) 
          : null,
      resolvedById: json['resolved_by_user_id'],
      deviceName: json['device_name'],
      deviceLocation: json['device_location'],
    );
  }
}