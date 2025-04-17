import '../constants/app_constants.dart';

class ActuatorModel {
  final int actuatorId;
  final int deviceId;
  final String actuatorType;
  final String controlType;
  final dynamic currentState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status;
  final String name; // Added name field

  ActuatorModel({
    required this.actuatorId,
    required this.deviceId,
    required this.actuatorType,
    required this.controlType,
    this.currentState,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
    required this.name, // Added required name parameter
  });

  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
    return ActuatorModel(
      actuatorId: json['actuator_id'] ?? 0,
      deviceId: json['device_id'] ?? 0,
      actuatorType: json['actuator_type'] ?? 'unknown',
      controlType: json['control_type'] ?? 'binary',
      currentState: json['current_state'], // This can be null
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      name: json['name'] ?? 'Unknown Actuator', // Added name with default value
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
      'actuator_type': actuatorType,
      'control_type': controlType,
      'current_state': currentState,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'name': name, // Added name to JSON
    };
  }
}