import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class SupabaseService {
  // Add this static client property
  static late SupabaseClient client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    // Initialize the client
    client = Supabase.instance.client;
  }

    static SupabaseClient getClient() {
    return client;
  }
  
  // Authentication methods
  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
  
  static User? getCurrentUser() {
    return client.auth.currentUser;
  }
  
  static Stream<AuthState> authStateChanges() {
    return client.auth.onAuthStateChange;
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
      final readings = await client
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
    return client
        .from('sensor_readings')
        .stream(primaryKey: ['id'])
        .eq('classroom_id', classroomId);
  }
  
  // Get recent sensor readings across all classrooms
  static Future<List<Map<String, dynamic>>> getRecentSensorReadings({int limit = 100}) async {
    final client = await getClient();
    
    try {
      // Get the most recent readings, joining with sensors to get sensor types
      final response = await client
        .from('sensor_readings')
        .select('''
          *,
          sensors:sensor_id (
            sensor_id,
            sensor_type,
            measurement_unit
          )
        ''')
        .order('timestamp', ascending: false)
        .limit(limit);
        
      // Process the response to flatten the structure
      return (response as List).map((item) {
        final sensor = item['sensors'] as Map<String, dynamic>;
        return {
          'reading_id': item['reading_id'],
          'sensor_id': item['sensor_id'],
          'value': item['value'],
          'timestamp': item['timestamp'],
          'sensor_type': sensor['sensor_type'],
          'unit': sensor['measurement_unit'],
        };
      }).toList();
    } catch (e) {
      print('Error getting recent sensor readings: $e');
      return [];
    }
  }
  
  // Device control methods
  static Future<void> updateDeviceState(String deviceId, bool state) async {
    // Convert boolean to the expected string status value
    final String statusValue = state ? 'online' : 'offline';
    
    await client
        .from('devices')
        .update({'status': statusValue})  // Use string value instead of boolean
        .eq('device_id', deviceId);
  }
  
  static Future<void> updateDeviceValue(String deviceId, double value) async {
    await client
        .from('devices')
        .update({'value': value})
        .eq('device_id', deviceId);
  }
  
  static Future<void> toggleActuator(String actuatorId, bool isOn) async {
    final client = await getClient();
    
    try {
      // Get existing actuator to preserve settings
      final response = await client
        .from('actuators')
        .select('settings')
        .eq('actuator_id', actuatorId)
        .single();
        
      Map<String, dynamic> settings = {};
      if (response != null && response['settings'] != null) {
        settings = Map<String, dynamic>.from(response['settings']);
      }
      
      // Update with preserved settings
      await client
        .from('actuators')
        .update({
          'current_state': isOn ? 'on' : 'off',
          'settings': settings, // Preserve existing settings
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('actuator_id', actuatorId);
    } catch (e) {
      print('Error toggling actuator: $e');
      throw e;
    }
  }
  
  static Future<void> toggleDeviceAndActuator(String deviceId, String actuatorId, bool isOn) async {
    // Start a transaction to update both records
    try {
      // Update device status
      await updateDeviceState(deviceId, isOn);
      
      // Update actuator state
      if (actuatorId.isNotEmpty) {
        await toggleActuator(actuatorId, isOn);
      }
    } catch (e) {
      print('Error toggling device and actuator: $e');
      throw e;
    }
  }
  
  static Future<void> updateActuatorSettings(String actuatorId, Map<String, dynamic> settings) async {
    final client = await getClient();
    
    try {
      await client
        .from('actuators')
        .update({
          'settings': settings,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('actuator_id', actuatorId);
        
    } catch (e) {
      print('Error updating actuator settings: $e');
      throw Exception('Failed to update actuator settings: $e');
    }
  }
  
  // Department and classroom methods
  static Future<List<Map<String, dynamic>>> getDepartments() async {
    final response = await client
        .from('departments')
        .select('*');
    
    return response;
  }
  
  static Future<List<Map<String, dynamic>>> getClassroomsByDepartment(String departmentId) async {
    final response = await client
        .from('classrooms')
        .select('*')
        .eq('department_id', departmentId);
    
    return response;
  }
  
  static Future<Map<String, dynamic>> getClassroomDetails(String classroomId) async {
    try {
      print('🔍 Fetching classroom details for ID: $classroomId');
      
      // Get the classroom base details
      final classroom = await client
          .from('classrooms')
          .select('*')
          .eq('classroom_id', classroomId)
          .single();
      
      print('📊 Base classroom data: $classroom');
      
      // Get the devices for the classroom
      final devices = await client
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
        try {
          sensors = await client
              .from('sensors')
              .select('*')
              .filter('device_id', 'in', deviceIds);
          print('📡 Sensors: ${sensors.length} found');
          
          // Debug each sensor's fields
          for (var i = 0; i < sensors.length; i++) {
            print('📡 Sensor $i: ${sensors[i]}');
          }
        } catch (e) {
          print('❌ Error fetching sensors: $e');
        }
      }
      
      List<Map<String, dynamic>> actuators = [];
      if (deviceIds.isNotEmpty) {
        try {
          actuators = await client
              .from('actuators')
              .select('*')
              .filter('device_id', 'in', deviceIds);
          print('🎮 Actuators: ${actuators.length} found');
        } catch (e) {
          print('❌ Error fetching actuators: $e');
        }
      }
      
      List<Map<String, dynamic>> cameras = [];
      if (deviceIds.isNotEmpty) {
        try {
          cameras = await client
              .from('cameras')
              .select('*')
              .filter('device_id', 'in', deviceIds);
          
          print('📷 Cameras: ${cameras.length} found');
          
          // Print raw camera data for debugging
          print('📷 Raw cameras data: $cameras');
          
          // Add a verification step to check and handle null values
          for (var camera in cameras) {
            // Check for null stream_url and set a default if needed
            if (camera['stream_url'] == null) {
              print('⚠️ Found null stream_url in camera ${camera['camera_id']}');
              camera['stream_url'] = ''; // Set to empty string instead of null
            }
          }
          
          // Debug each camera to find the problematic one
          for (var i = 0; i < cameras.length; i++) {
            print('📷 Camera $i: ${cameras[i]}');
            
            // Ensure stream_url is not null
            if (cameras[i]['stream_url'] == null) {
              print('⚠️ Warning: Camera $i has null stream_url. Setting default value.');
              cameras[i]['stream_url'] = '';
            }
          }
        } catch (e) {
          print('❌ Error fetching cameras: $e');
        }
      }
      
      // Get sensor readings
      final sensorIds = sensors.map((sensor) => sensor['sensor_id']).toList();
      print('🆔 Sensor IDs: $sensorIds');
      
      List<Map<String, dynamic>> readings = [];
      if (sensorIds.isNotEmpty) {
        try {
          readings = await client
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
        } catch (e) {
          print('❌ Error fetching readings: $e');
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
  
  // Get occupancy data for classrooms
  static Future<List<Map<String, dynamic>>> getOccupancyData() async {
    final client = await getClient();
    
    try {
      // Query classrooms with their latest motion sensor readings
      final classroomsResponse = await client
        .from('classrooms')
        .select('classroom_id, name, capacity');
        
      List<Map<String, dynamic>> classrooms = List<Map<String, dynamic>>.from(classroomsResponse);
      List<Map<String, dynamic>> result = [];
      
      // For each classroom, determine if it's occupied based on motion sensor readings
      for (var classroom in classrooms) {
        // Get the devices associated with this classroom
        final devicesResponse = await client
          .from('devices')
          .select('device_id')
          .eq('classroom_id', classroom['classroom_id'])
          .eq('device_type', 'sensor');
          
        List<Map<String, dynamic>> devices = List<Map<String, dynamic>>.from(devicesResponse);
        bool isOccupied = false;
        
        for (var device in devices) {
          // Get any motion sensors for this device
          final sensorResponse = await client
            .from('sensors')
            .select('sensor_id')
            .eq('device_id', device['device_id'])
            .eq('sensor_type', 'motion');
            
          List<Map<String, dynamic>> motionSensors = List<Map<String, dynamic>>.from(sensorResponse);
          
          // Check if any motion sensors detected movement in the last 15 minutes
          for (var sensor in motionSensors) {
            final DateTime fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15));
            
            final readingResponse = await client
              .from('sensor_readings')
              .select('value')
              .eq('sensor_id', sensor['sensor_id'])
              .gt('timestamp', fifteenMinutesAgo.toIso8601String())
              .eq('value', 1) // Motion detected
              .limit(1);
              
            if ((readingResponse as List).isNotEmpty) {
              isOccupied = true;
              break;
            }
          }
          
          if (isOccupied) break;
        }
        
        result.add({
          'classroom_id': classroom['classroom_id'],
          'name': classroom['name'],
          'capacity': classroom['capacity'],
          'is_occupied': isOccupied,
        });
      }
      
      return result;
    } catch (e) {
      print('Error getting occupancy data: $e');
      return [];
    }
  }
  
  // Alert methods
  static Future<List<Map<String, dynamic>>> getAlerts({int limit = 20}) async {
    final response = await client
        .from('alerts')
        .select('*')
        .order('timestamp', ascending: false)
        .limit(limit);
    
    return response;
  }
  
  static Stream<List<Map<String, dynamic>>> streamAlerts() {
    return client
        .from('alerts')
        .stream(primaryKey: ['id']);
  }
  
  // Camera feed URL
  static String getCameraFeedUrl(String cameraId) {
    return '$supabaseUrl/edge/v1/camera-stream?camera_id=$cameraId';
  }

  static getCameraDetails(int cameraId) {}

  // Get all security devices with their status
  static Future<List<Map<String, dynamic>>> getSecurityDevices() async {
    final client = await getClient();
    
    try {
      // First get security-related devices
      final response = await client
        .from('devices')
        .select('''
          *,
          classrooms:classroom_id (
            classroom_id,
            name
          )
        ''')
        .inFilter('device_type', ['door_lock', 'window_sensor', 'motion_sensor', 'camera'])
        .order('device_id');

      return (response as List).map((device) {
        final classroom = device['classrooms'];
        return {
          'device_id': device['device_id'],
          'device_type': device['device_type'],
          'name': device['name'] ?? 'Security Device',
          'location': device['location'],
          'classroom_id': classroom != null ? classroom['classroom_id'] : null,
          'classroom_name': classroom != null ? classroom['name'] : null,
          'status': _mapDeviceStatusToSecurity(device['status']),
          'is_active': device['status'] == 'online',
          'updated_at': device['updated_at'],
        };
      }).toList();
    } catch (e) {
      print('Error getting security devices: $e');
      return [];
    }
  }

  // Helper method to map device status to security status
  static String _mapDeviceStatusToSecurity(String? status) {
    if (status == null) return 'offline';
    
    switch (status.toLowerCase()) {
      case 'online':
        return 'secured';
      case 'offline':
        return 'offline';
      case 'maintenance':
        return 'offline';
      default:
        return status.toLowerCase();
    }
  }

  // Get security events
  static Future<List<Map<String, dynamic>>> getSecurityEvents({int limit = 20}) async {
    final client = await getClient();
    
    try {
      final response = await client
        .from('motion_events') // Using motion_events as a proxy for security events
        .select('''
          *,
          devices:device_id (
            device_id,
            name,
            classroom_id
          )
        ''')
        .order('timestamp', ascending: false)
        .limit(limit);

      // We'll transform motion events into security events with more details
      return (response as List).map((event) {
        final device = event['devices'];
        
        return {
          'event_id': event['event_id'],
          'device_id': event['device_id'],
          'device_name': device != null ? device['name'] : 'Unknown Device',
          'event_type': 'motion_detected', // In a real app, this would vary
          'description': 'Motion detected in the area',
          'timestamp': event['timestamp'],
          'is_acknowledged': false, // This field might not exist in your actual DB
        };
      }).toList();
    } catch (e) {
      print('Error getting security events: $e');
      return [];
    }
  }

  // Toggle security device (lock/unlock doors, etc.)
  static Future<void> toggleSecurityDevice(String deviceId, bool secure) async {
    final client = await getClient();
    
    try {
      // Update device status
      await client
        .from('devices')
        .update({
          'status': secure ? 'online' : 'offline', // Using online/offline as proxy for secured/breached
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('device_id', deviceId);
        
    } catch (e) {
      print('Error toggling security device: $e');
      throw e;
    }
  }

  // Acknowledge security event
  static Future<void> acknowledgeSecurityEvent(int eventId) async {
    final client = await getClient();
    
    try {
      // In a real app, you'd update your security_events table
      // For this example, we'll just print since motion_events doesn't have this column
      print('Acknowledged event $eventId');
      
    } catch (e) {
      print('Error acknowledging security event: $e');
      throw e;
    }
  }

  // Get alarm system status
  static Future<String> getAlarmSystemStatus() async {
    // In a real app, you'd fetch this from your database
    // For this example, we'll return a fixed value
    return 'inactive';
  }

  // Set alarm system status
  static Future<void> setAlarmSystemStatus(String status) async {
    // In a real app, you'd update this in your database
    print('Setting alarm system status to: $status');
  }
}