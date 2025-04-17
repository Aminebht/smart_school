import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/camera_model.dart';
import '../utils/logger.dart';
import '../../services/supabase_service.dart';

class CameraService {
  final SupabaseClient _supabaseClient = SupabaseService.getClient();
  final Logger _logger = Logger('CameraService');

  // Get all cameras
  Future<List<CameraModel>> getAllCameras() async {
    try {
      final response = await _supabaseClient
          .from('cameras')
          .select()
          .order('camera_id');
      
      return response.map<CameraModel>((camera) => CameraModel.fromJson(camera)).toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to get all cameras', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Get cameras for a specific classroom
  Future<List<CameraModel>> getCamerasForClassroom(int classroomId) async {
    try {
      // If there's a different way cameras are associated with classrooms
      // (like through a device table or a join table), we need to adjust this query
      
      // Option 1: If cameras are linked to classrooms through devices
      final response = await _supabaseClient
          .from('cameras')
          .select('*, devices!inner(*)')  // Assuming cameras link to devices that link to classrooms
          .eq('devices.classroom_id', classroomId)
          .order('camera_id');
      
      // Option 2: If there's a separate mapping table
      // final response = await _supabaseClient
      //     .from('camera_classroom_mappings')
      //     .select('cameras(*)')
      //     .eq('classroom_id', classroomId);
      
      return response.map<CameraModel>((camera) {
        // If using Option 1, add classroom_id to the data
        if (camera['devices'] != null) {
          camera['classroom_id'] = classroomId; // Add the classroom ID to the data
        }
        return CameraModel.fromJson(camera);
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to get cameras for classroom: $classroomId', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Get a single camera by ID
  Future<CameraModel?> getCameraById(int cameraId) async {
    try {
      final response = await _supabaseClient
          .from('cameras')
          .select()
          .eq('camera_id', cameraId)
          .single();
      
      return CameraModel.fromJson(response);
    } catch (e, stackTrace) {
      _logger.error('Failed to get camera by id: $cameraId', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Update camera status (active, recording, etc.)
  Future<bool> updateCameraStatus(int cameraId, bool isActive) async {
    try {
      await _supabaseClient
          .from('cameras')
          .update({'is_active': isActive})
          .eq('camera_id', cameraId);
      
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to update camera status. Camera ID: $cameraId', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}