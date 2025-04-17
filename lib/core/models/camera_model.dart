import 'dart:convert';

class CameraModel {
  final int cameraId;
  final String name;
  final String description;
  final int classroomId;
  final String streamUrl;
  final String cameraType;
  final bool isActive;
  final bool hasMotionDetection;
  final bool isRecording;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CameraModel({
    required this.cameraId,
    required this.name,
    required this.description,
    required this.classroomId,
    required this.streamUrl,
    required this.cameraType,
    required this.isActive,
    required this.hasMotionDetection,
    required this.isRecording,
    this.createdAt,
    this.updatedAt,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      cameraId: json['camera_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      classroomId: json['classroom_id'] as int,
      streamUrl: json['stream_url'] as String? ?? '',
      cameraType: json['camera_type'] as String? ?? 'standard',
      isActive: json['is_active'] as bool? ?? false,
      hasMotionDetection: json['has_motion_detection'] as bool? ?? false,
      isRecording: json['is_recording'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'camera_id': cameraId,
      'name': name,
      'description': description,
      'classroom_id': classroomId,
      'stream_url': streamUrl,
      'camera_type': cameraType,
      'is_active': isActive,
      'has_motion_detection': hasMotionDetection,
      'is_recording': isRecording,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}