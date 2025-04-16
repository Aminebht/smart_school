import '../constants/app_constants.dart';

class CameraModel {
  final int cameraId;
  final int deviceId;
  final int? classroomId;
  final String name;
  final String streamUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status;

  CameraModel({
    required this.cameraId,
    required this.deviceId,
    this.classroomId,
    required this.name,
    required this.streamUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
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

    return CameraModel(
      cameraId: json['camera_id'],
      deviceId: json['device_id'],
      classroomId: json['classroom_id'],
      name: json['name'],
      streamUrl: json['stream_url'] ?? '',
      isActive: json['is_active'] ?? false,
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
      'camera_id': cameraId,
      'device_id': deviceId,
      'classroom_id': classroomId,
      'name': name,
      'stream_url': streamUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }
} 