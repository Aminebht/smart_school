import '../constants/app_constants.dart';

class ActuatorModel {
  final int actuatorId;
  final int deviceId;
  final int? classroomId;
  final String name;
  final String type;
  final bool isOn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status;

  ActuatorModel({
    required this.actuatorId,
    required this.deviceId,
    this.classroomId,
    required this.name,
    required this.type,
    required this.isOn,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
  });

  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
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

    return ActuatorModel(
      actuatorId: json['actuator_id'],
      deviceId: json['device_id'],
      classroomId: json['classroom_id'],
      name: json['name'],
      type: json['type'],
      isOn: json['is_on'] ?? false,
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
      'actuator_id': actuatorId,
      'device_id': deviceId,
      'classroom_id': classroomId,
      'name': name,
      'type': type,
      'is_on': isOn,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }
} 