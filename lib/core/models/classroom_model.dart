import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'device_model.dart';
import 'sensor_model.dart';
import 'sensor_reading_model.dart';
import 'actuator_model.dart';
import 'camera_model.dart';

class ClassroomModel {
  final int classroomId;
  final int departmentId;
  final String name;
  final int capacity;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Non-database fields - calculated or fetched separately
  final List<DeviceModel> devices;
  final List<SensorModel> sensors;
  final List<ActuatorModel> actuators;
  final List<CameraModel> cameras;
  final List<SensorReadingModel> sensorReadings;
  final DeviceStatus status;

  ClassroomModel({
    required this.classroomId,
    required this.departmentId,
    required this.name,
    required this.capacity,
    required this.createdAt,
    required this.updatedAt,
    this.devices = const [],
    this.sensors = const [],
    this.actuators = const [],
    this.cameras = const [],
    this.sensorReadings = const [],
    this.status = DeviceStatus.normal,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    // Parse devices if present
    List<DeviceModel> devicesList = [];
    if (json['devices'] != null) {
      if (json['devices'] is List) {
        devicesList = (json['devices'] as List)
            .map((deviceJson) => DeviceModel.fromJson(deviceJson))
            .toList();
      }
    }

    // Parse sensors if present
    List<SensorModel> sensorsList = [];
    List<ActuatorModel> actuatorsList = [];
    List<CameraModel> camerasList = [];
    
    // Parse sensor readings if present
    List<SensorReadingModel> sensorReadingsList = [];
    if (json['sensor_readings'] != null) {
      if (json['sensor_readings'] is List) {
        sensorReadingsList = (json['sensor_readings'] as List)
            .map((readingJson) => SensorReadingModel.fromJson(readingJson))
            .toList();
      }
    }

    // Determine status from sensor readings or provided status
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
    } else {
      // Determine status from sensor readings if available
      for (var sensor in sensorReadingsList) {
        if (sensor.status == DeviceStatus.critical) {
          status = DeviceStatus.critical;
          break;
        } else if (sensor.status == DeviceStatus.warning) {
          status = DeviceStatus.warning;
        }
      }
    }

    return ClassroomModel(
      classroomId: json['classroom_id'],
      departmentId: json['department_id'],
      name: json['name'],
      capacity: json['capacity'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      devices: devicesList,
      sensors: sensorsList,
      actuators: actuatorsList,
      cameras: camerasList,
      sensorReadings: sensorReadingsList,
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
      'classroom_id': classroomId,
      'department_id': departmentId,
      'name': name,
      'capacity': capacity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }

  // Get the latest reading of a specific sensor type
  SensorReadingModel? getLatestReading(String sensorType) {
    final filteredReadings = sensorReadings
        .where((reading) => reading.sensorType == sensorType)
        .toList();
    
    if (filteredReadings.isEmpty) {
      return null;
    }
    
    filteredReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filteredReadings.first;
  }

  // Get all devices of a specific type
  List<DeviceModel> getDevicesByType(String deviceType) {
    return devices.where((device) => device.deviceType == deviceType).toList();
  }

  // Check if classroom has a camera
  bool get hasCamera => cameras.isNotEmpty;

  // Get overall status color
  Color get statusColor {
    switch (status) {
      case DeviceStatus.normal:
        return AppColors.success;
      case DeviceStatus.warning:
        return AppColors.warning;
      case DeviceStatus.critical:
        return AppColors.error;
    }
  }
} 