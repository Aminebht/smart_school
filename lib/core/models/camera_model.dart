import 'dart:convert';

class CameraModel {
  final int cameraId;
  final int? deviceId;
  final String streamUrl;
  final bool motionDetectionEnabled; // Renamed to match DB column
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional fields needed for app functionality but not directly in DB table
  final String name;
  final String description;
  final int? classroomId; // Made optional since it's not in the DB table
  final String cameraType;
  final bool isActive;
  final bool isRecording;
  
  CameraModel({
    required this.cameraId,
    this.deviceId,
    required this.streamUrl,
    required this.motionDetectionEnabled, // Renamed parameter
    this.createdAt,
    this.updatedAt,
    
    // App fields with defaults
    this.name = '',
    this.description = '',
    this.classroomId, // No longer required
    this.cameraType = 'standard',
    this.isActive = true,
    this.isRecording = true,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      cameraId: json['camera_id'] as int,
      deviceId: json['device_id'] as int?,
      streamUrl: json['stream_url'] as String? ?? '',
      motionDetectionEnabled: json['motion_detection_enabled'] as bool? ?? true, // Updated column name
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
          
      // Map additional app fields
      name: json['name'] as String? ?? 'Camera ${json['camera_id']}',
      description: json['description'] as String? ?? '',
      classroomId: json['classroom_id'] as int?, // May come from a joined query
      cameraType: json['camera_type'] as String? ?? 'standard',
      isActive: json['is_active'] as bool? ?? false,
      isRecording: json['is_recording'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'camera_id': cameraId,
      'device_id': deviceId,
      'stream_url': streamUrl,
      'motion_detection_enabled': motionDetectionEnabled, // Updated column name
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      
      // Additional app fields - these won't be used when inserting into the cameras table
      'name': name,
      'description': description,
      'classroom_id': classroomId,
      'camera_type': cameraType,
      'is_active': isActive,
      'is_recording': isRecording,
    };
  }

  // Getter for compatibility with existing code
  bool get motionDetect => motionDetectionEnabled;
  bool get hasMotionDetection => motionDetectionEnabled;
  bool get hasMotion => motionDetectionEnabled;

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}