import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DeviceModel {
  final int deviceId;
  final int? classroomId;
  final String name;
  final String deviceType;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status;

  DeviceModel({
    required this.deviceId,
    this.classroomId,
    required this.name,
    required this.deviceType,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    // Determine status from provided status or defaults to normal
    DeviceStatus status = DeviceStatus.normal;
    if (json['status'] != null) {
      switch (json['status']) {
        case 'warning':
          status = DeviceStatus.warning;
          break;
        case 'critical':
          status = DeviceStatus.critical;
          break;
        default:
          status = DeviceStatus.normal;
      }
    }

    return DeviceModel(
      deviceId: json['device_id'],
      classroomId: json['classroom_id'],
      name: json['name'],
      deviceType: json['device_type'],
      isOnline: json['is_online'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case DeviceStatus.warning:
        statusStr = 'warning';
        break;
      case DeviceStatus.critical:
        statusStr = 'critical';
        break;
      default:
        statusStr = 'normal';
    }

    return {
      'device_id': deviceId,
      'classroom_id': classroomId,
      'name': name,
      'device_type': deviceType,
      'is_online': isOnline,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }

  IconData get deviceIcon {
    switch (deviceType) {
      case 'light':
        return isOnline ? Icons.lightbulb : Icons.lightbulb_outline;
      case 'fan':
        return isOnline ? Icons.air : Icons.air_outlined;
      case 'door':
        return isOnline ? Icons.meeting_room : Icons.meeting_room_outlined;
      case 'window':
        return isOnline ? Icons.window : Icons.window_outlined;
      case 'ac':
        return isOnline ? Icons.ac_unit : Icons.ac_unit_outlined;
      default:
        return Icons.device_unknown;
    }
  }

  String get statusText {
    switch (deviceType) {
      case 'door':
      case 'window':
        return isOnline ? 'Open' : 'Closed';
      default:
        return isOnline ? 'On' : 'Off';
    }
  }

  bool get isToggleable {
    return deviceType == 'light' || deviceType == 'fan' || deviceType == 'ac';
  }

  bool get isAdjustable {
    return deviceType == 'fan' || deviceType == 'ac';
  }
} 