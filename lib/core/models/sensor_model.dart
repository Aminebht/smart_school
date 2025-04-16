import '../constants/app_constants.dart';

class SensorModel {
  final int sensorId;
  final int deviceId;
  final int? classroomId;
  final String name;
  final String type;
  final String unit;
  final double minValue;
  final double maxValue;
  final double warningThreshold;
  final double criticalThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status;

  SensorModel({
    required this.sensorId,
    required this.deviceId,
    this.classroomId,
    required this.name,
    required this.type,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.warningThreshold, 
    required this.criticalThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
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

    return SensorModel(
      sensorId: json['sensor_id'],
      deviceId: json['device_id'],
      classroomId: json['classroom_id'],
      name: json['name'],
      type: json['type'],
      unit: json['unit'],
      minValue: json['min_value']?.toDouble() ?? 0.0,
      maxValue: json['max_value']?.toDouble() ?? 100.0,
      warningThreshold: json['warning_threshold']?.toDouble() ?? 70.0,
      criticalThreshold: json['critical_threshold']?.toDouble() ?? 90.0,
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
      'sensor_id': sensorId,
      'device_id': deviceId,
      'classroom_id': classroomId,
      'name': name,
      'type': type,
      'unit': unit,
      'min_value': minValue,
      'max_value': maxValue,
      'warning_threshold': warningThreshold,
      'critical_threshold': criticalThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }
} 