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
    try {
      // First, get the classroom details which includes devices and sensors
      final classroom = await getClassroomDetails(classroomId);
      
      if (classroom['sensors'] == null || !(classroom['sensors'] is List) || 
          (classroom['sensors'] as List).isEmpty) {
        return [];
      }
      
      final sensors = classroom['sensors'] as List<dynamic>;
      
      // Filter sensors by type
      final filteredSensors = sensors.where((s) => s['sensor_type'] == sensorType).toList();
      
      if (filteredSensors.isEmpty) {
        return [];
      }
      
      // Get sensor IDs
      final sensorIds = filteredSensors.map((s) => s['sensor_id']).toList();
      
      if (sensorIds.isEmpty) {
        return [];
      }
      
      // Get readings for these sensors
      final readings = await _client
          .from('sensor_readings')
          .select('*')
          .filter('sensor_id', 'in', sensorIds)
          .order('timestamp', ascending: false)
          .limit(limit);
      
      // Add sensor_type to each reading if it doesn't already have one
      for (var reading in readings) {
        // If sensor_type is null, find which sensor this reading belongs to
        if (reading['sensor_type'] == null) {
          for (var sensor in filteredSensors) {
            if (sensor['sensor_id'] == reading['sensor_id']) {
              reading['sensor_type'] = sensor['sensor_type'] ?? sensorType;
              break;
            }
          }
          
          // If we still couldn't find the sensor type, use the requested sensorType
          if (reading['sensor_type'] == null) {
            reading['sensor_type'] = sensorType;
          }
        }
      }
      
      return readings;
    } catch (e) {
      print('Error in getSensorReadings: $e');
      return [];
    }
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
        .update({'is_online': state})
        .eq('device_id', deviceId);
  }
  
  static Future<void> updateDeviceValue(String deviceId, double value) async {
    await _client
        .from('devices')
        .update({'value': value})
        .eq('device_id', deviceId);
  }
  
  static Future<void> toggleActuator(String actuatorId, bool isOn) async {
    await _client
        .from('actuators')
        .update({'is_on': isOn})
        .eq('actuator_id', actuatorId);
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
    try {
      print('🔍 Fetching classroom details for ID: $classroomId');
      
      // Get the classroom base details
      final classroom = await _client
          .from('classrooms')
          .select('*')
          .eq('classroom_id', classroomId)
          .single();
      
      print('📊 Base classroom data: $classroom');
      
      // Get the devices for the classroom
      final devices = await _client
          .from('devices')
          .select('*')
          .eq('classroom_id', classroomId);
      
      print('🔌 Devices: ${devices.length} found');
      
      // Get device IDs for this classroom
      final deviceIds = devices.map((device) => device['device_id']).toList();
      print('🆔 Device IDs: $deviceIds');
      
      // Get sensors and actuators using device_id
      List<Map<String, dynamic>> sensors = [];
      if (deviceIds.isNotEmpty) {
        sensors = await _client
            .from('sensors')
            .select('*')
            .filter('device_id', 'in', deviceIds);
        print('📡 Sensors: ${sensors.length} found');
        // Debug each sensor's fields
        for (var i = 0; i < sensors.length; i++) {
          print('📡 Sensor $i: ${sensors[i]}');
        }
      }
      
      List<Map<String, dynamic>> actuators = [];
      if (deviceIds.isNotEmpty) {
        actuators = await _client
            .from('actuators')
            .select('*')
            .filter('device_id', 'in', deviceIds);
        print('🎮 Actuators: ${actuators.length} found');
      }
      
      List<Map<String, dynamic>> cameras = [];
      if (deviceIds.isNotEmpty) {
        cameras = await _client
            .from('cameras')
            .select('*')
            .filter('device_id', 'in', deviceIds);
        print('📷 Cameras: ${cameras.length} found');
      }
      
      // Get sensor readings
      final sensorIds = sensors.map((sensor) => sensor['sensor_id']).toList();
      print('🆔 Sensor IDs: $sensorIds');
      
      List<Map<String, dynamic>> readings = [];
      if (sensorIds.isNotEmpty) {
        readings = await _client
            .from('sensor_readings')
            .select('*')
            .filter('sensor_id', 'in', sensorIds)
            .order('timestamp', ascending: false)
            .limit(50);
        
        print('📈 Readings: ${readings.length} found');
        
        // Enhance sensor readings with sensor type
        for (var i = 0; i < readings.length; i++) {
          var reading = readings[i];
          print('📊 Before enhancement - Reading $i: $reading');
          
          // Find the sensor for this reading
          final sensorId = reading['sensor_id'];
          final sensor = sensors.firstWhere(
            (s) => s['sensor_id'] == sensorId,
            orElse: () => {'sensor_type': 'unknown'}
          );
          
          print('🔍 Matching sensor for reading $i: $sensor');
          
          // Add the sensor type to the reading
          reading['sensor_type'] = sensor['sensor_type'] ?? 'unknown';
          print('📊 After enhancement - Reading $i: $reading');
        }
      }
      
      // Combine all the data
      classroom['devices'] = devices;
      classroom['sensors'] = sensors;
      classroom['actuators'] = actuators;
      classroom['cameras'] = cameras;
      classroom['sensor_readings'] = readings;
      
      print('🏫 Final classroom data structure keys: ${classroom.keys.toList()}');
      return classroom;
    } catch (e) {
      print('❌ Error in getClassroomDetails: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      throw e;
    }
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