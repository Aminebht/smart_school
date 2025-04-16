import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  // Authentication methods
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
  
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }
  
  static Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }
  
  // Sensor data methods
  static Future<List<Map<String, dynamic>>> getSensorReadings(
      String classroomId, String sensorType, {int limit = 20}) async {
    final response = await _client
        .from('sensor_readings')
        .select('*')
        .eq('classroom_id', classroomId)
        .eq('sensor_type', sensorType)
        .order('created_at', ascending: false)
        .limit(limit);
    
    return response;
  }
  
  static Stream<List<Map<String, dynamic>>> streamSensorReadings(String classroomId) {
    return _client
        .from('sensor_readings')
        .stream(primaryKey: ['id'])
        .eq('classroom_id', classroomId);
  }
  
  // Device control methods
  static Future<void> updateDeviceState(String deviceId, bool state) async {
    await _client
        .from('devices')
        .update({'state': state})
        .eq('id', deviceId);
  }
  
  static Future<void> updateDeviceValue(String deviceId, double value) async {
    await _client
        .from('devices')
        .update({'value': value})
        .eq('id', deviceId);
  }
  
  // Department and classroom methods
  static Future<List<Map<String, dynamic>>> getDepartments() async {
    final response = await _client
        .from('departments')
        .select('*');
    
    return response;
  }
  
  static Future<List<Map<String, dynamic>>> getClassroomsByDepartment(String departmentId) async {
    final response = await _client
        .from('classrooms')
        .select('*')
        .eq('department_id', departmentId);
    
    return response;
  }
  
  static Future<Map<String, dynamic>> getClassroomDetails(String classroomId) async {
    final response = await _client
        .from('classrooms')
        .select('*, devices(*), sensors(*), actuators(*), cameras(*)')
        .eq('classroom_id', classroomId)
        .single();
    
    return response;
  }
  
  // Alert methods
  static Future<List<Map<String, dynamic>>> getAlerts({int limit = 20}) async {
    final response = await _client
        .from('alerts')
        .select('*')
        .order('timestamp', ascending: false)
        .limit(limit);
    
    return response;
  }
  
  static Stream<List<Map<String, dynamic>>> streamAlerts() {
    return _client
        .from('alerts')
        .stream(primaryKey: ['id']);
  }
  
  // Camera feed URL
  static String getCameraFeedUrl(String cameraId) {
    return '$supabaseUrl/edge/v1/camera-stream?camera_id=$cameraId';
  }
} 