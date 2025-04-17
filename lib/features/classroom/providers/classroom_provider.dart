import 'package:flutter/material.dart';
import '../../../core/models/classroom_model.dart';
import '../../../core/models/sensor_model.dart'; // Add this for SensorModel
import '../../../core/models/actuator_model.dart'; // Add this for ActuatorModel
import '../../../core/models/sensor_reading_model.dart';
import '../../../core/constants/app_constants.dart'; // Add this for DeviceStatus enum
import '../../../services/supabase_service.dart';

class ClassroomProvider extends ChangeNotifier {
  ClassroomModel? _classroom;
  List<SensorReadingModel> _sensorData = [];
  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _errorMessage;
  String? _selectedSensorType;
  String _selectedTimeRange = '24 hours';
  
  // Getters
  ClassroomModel? get classroom => _classroom;
  List<SensorReadingModel> get sensorData => _sensorData;
  bool get isLoading => _isLoading;
  bool get isLoadingData => _isLoadingData;
  String? get errorMessage => _errorMessage;
  String? get selectedSensorType => _selectedSensorType;
  String get selectedTimeRange => _selectedTimeRange;
  
  // Available time ranges for filtering data
  final List<String> availableTimeRanges = [
    '1 hour',
    '6 hours',
    '24 hours',
    '7 days',
    '30 days',
  ];

  // Load classroom details
  Future<void> loadClassroom(String classroomId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 Loading classroom with ID: $classroomId');
      final classroomJson = await SupabaseService.getClassroomDetails(classroomId);
      print('✅ Classroom JSON data received');
      
      try {
        _classroom = ClassroomModel.fromJson(classroomJson);
        print('✅ Classroom model created successfully');
        print('📋 Classroom: $_classroom');
      } catch (e) {
        print('❌ Error creating ClassroomModel: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        _errorMessage = 'Failed to parse classroom data: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // If we have sensor readings, set the initial selected sensor type
      final sensorTypes = getAvailableSensorTypes();
      print('📊 Available sensor types: $sensorTypes');
      
      if (sensorTypes.isNotEmpty) {
        _selectedSensorType = sensorTypes.first;
        print('📊 Selected sensor type: $_selectedSensorType');
        
        try {
          await loadSensorData(classroomId, _selectedSensorType!);
          print('✅ Sensor data loaded successfully');
        } catch (e) {
          print('❌ Error loading sensor data: $e');
          _errorMessage = 'Failed to load sensor data: ${e.toString()}';
          // Continue with classroom data even if sensor data fails
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error in loadClassroom: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _isLoading = false;
      _errorMessage = 'Failed to load classroom: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get all available sensor types from readings
  List<String> getAvailableSensorTypes() {
    if (_classroom == null || _classroom!.sensorReadings.isEmpty) {
      print('⚠️ No classroom or sensor readings available');
      return [];
    }
    
    final types = <String>{};
    print('🔍 Getting sensor types from ${_classroom!.sensorReadings.length} readings');
    
    for (var reading in _classroom!.sensorReadings) {
      print('📊 Reading sensor type: ${reading.sensorType} (${reading.sensorType.runtimeType})');
      types.add(reading.sensorType);
    }
    
    print('✅ Found ${types.length} unique sensor types: $types');
    return types.toList();
  }

  // Set selected sensor type
  void setSelectedSensorType(String type) {
    _selectedSensorType = type;
    notifyListeners();
  }

  // Set selected time range
  void setSelectedTimeRange(String range) {
    _selectedTimeRange = range;
    notifyListeners();
  }

  // Load sensor data for a specific sensor type
  Future<void> loadSensorData(String classroomId, String sensorType) async {
    _isLoadingData = true;
    notifyListeners();

    try {
      final limit = _getDataLimitFromTimeRange();
      final readings = await SupabaseService.getSensorReadings(
        classroomId,
        sensorType,
        limit: limit,
      );
      
      _sensorData = readings.map((json) => SensorReadingModel.fromJson(json)).toList();
      _isLoadingData = false;
      notifyListeners();
    } catch (e) {
      _isLoadingData = false;
      _errorMessage = 'Failed to load sensor data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Toggle device state (on/off)
  Future<void> toggleDevice(String deviceId, bool isOn) async {
    try {
      // Only toggle actuators
      String actuatorId = '';
      if (_classroom != null) {
        // First check if this is an actuator by deviceId
        for (var actuator in _classroom!.actuators) {
          if (actuator.deviceId.toString() == deviceId) {
            actuatorId = actuator.actuatorId.toString();
            break;
          }
        }
        
        // Also check if the ID itself is an actuatorId
        if (actuatorId.isEmpty) {
          for (var actuator in _classroom!.actuators) {
            if (actuator.actuatorId.toString() == deviceId) {
              actuatorId = actuator.actuatorId.toString();
              deviceId = actuator.deviceId.toString();
              break;
            }
          }
        }
        
        // If an actuator was found
        if (actuatorId.isNotEmpty) {
          // Update both device and actuator
          await SupabaseService.toggleDeviceAndActuator(deviceId, actuatorId, isOn);
          
          // Update the local state
          for (var i = 0; i < _classroom!.actuators.length; i++) {
            if (_classroom!.actuators[i].actuatorId.toString() == actuatorId) {
              // Update the actuator status
              final updatedActuator = _classroom!.actuators[i];
              _classroom!.actuators[i] = ActuatorModel(
                actuatorId: updatedActuator.actuatorId,
                deviceId: updatedActuator.deviceId,
                actuatorType: updatedActuator.actuatorType,
                controlType: updatedActuator.controlType,
                currentState: isOn ? "on" : "off", // Update current state
                createdAt: updatedActuator.createdAt,
                updatedAt: updatedActuator.updatedAt,
                status: isOn ? DeviceStatus.online : DeviceStatus.offline,
                name: updatedActuator.name,
              );
              notifyListeners();
              return;
            }
          }
        } else {
          // Not an actuator, don't toggle
          _errorMessage = 'Only actuators can be toggled';
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle device: ${e.toString()}';
      notifyListeners();
    }
  }

  // Update device value (for dimmable lights, thermostats, etc.)
  Future<void> updateDeviceValue(String deviceId, double value) async {
    try {
      await SupabaseService.updateDeviceValue(deviceId, value);
      
      // Update the local state if successful
      if (_classroom != null) {
        // Find the device and update its value
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update device value: ${e.toString()}';
      notifyListeners();
    }
  }

  // Calculate data limit based on selected time range
  int _getDataLimitFromTimeRange() {
    switch (_selectedTimeRange) {
      case '1 hour':
        return 60; // One reading per minute
      case '6 hours':
        return 72; // One reading per 5 minutes
      case '24 hours':
        return 96; // One reading per 15 minutes
      case '7 days':
        return 168; // One reading per hour
      case '30 days':
        return 240; // One reading per 3 hours
      default:
        return 100;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}