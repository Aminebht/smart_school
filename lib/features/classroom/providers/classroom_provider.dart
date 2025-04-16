import 'package:flutter/material.dart';
import '../../../core/models/classroom_model.dart';
import '../../../core/models/sensor_reading_model.dart';
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
      final classroomJson = await SupabaseService.getClassroomDetails(classroomId);
      _classroom = ClassroomModel.fromJson(classroomJson);
      
      // If we have sensor readings, set the initial selected sensor type
      final sensorTypes = getAvailableSensorTypes();
      if (sensorTypes.isNotEmpty) {
        _selectedSensorType = sensorTypes.first;
        await loadSensorData(classroomId, _selectedSensorType!);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load classroom: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get all available sensor types from readings
  List<String> getAvailableSensorTypes() {
    if (_classroom == null || _classroom!.sensorReadings.isEmpty) {
      return [];
    }
    
    final types = <String>{};
    for (var reading in _classroom!.sensorReadings) {
      types.add(reading.sensorType);
    }
    
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
      await SupabaseService.updateDeviceState(deviceId, isOn);
      
      // Update the local state if successful
      if (_classroom != null) {
        // Find the device and update its state
        // This would need to be implemented based on whether it's a sensor, actuator, etc.
        notifyListeners();
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