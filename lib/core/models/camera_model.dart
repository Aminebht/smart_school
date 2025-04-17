import '../constants/app_constants.dart';

class CameraModel {
  final int cameraId;
  final int deviceId;
  final int? classroomId;
  final String name;
  final String streamUrl;
  final bool isActive;
  final bool motionDetectionEnabled;
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
    required this.motionDetectionEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing camera: $json'); // Debug logging
    
    // Handle potential null values even though they should be NOT NULL in schema
    return CameraModel(
      cameraId: json['camera_id'] ?? 0,
      deviceId: json['device_id'] ?? 0,
      classroomId: json['classroom_id'],
      name: json['name'],
      streamUrl: json['stream_url'] ?? '', // Handle null stream_url
      isActive: json['is_active'] ?? false,
      motionDetectionEnabled: json['motion_detection_enabled'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      status: json['status'] != null
          ? DeviceStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['status'],
              orElse: () => DeviceStatus.normal)
          : DeviceStatus.normal,
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
      'motion_detection_enabled': motionDetectionEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }
}