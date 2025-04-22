import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/models/security_device_model.dart';
import '../../../core/models/security_event_model.dart';
import '../../../services/supabase_service.dart';

class SecurityProvider extends ChangeNotifier {
  List<SecurityDeviceModel> _devices = [];
  List<SecurityEventModel> _events = [];
  List<SecurityEventModel> _recentEvents = [];
  bool _isLoading = false;
  bool _alarmSystemActive = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  // Security stats
  Map<String, dynamic> _securityStats = {
    'total_devices': 0,
    'secured_devices': 0,
    'breached_devices': 0,
    'offline_devices': 0,
    'alarm_status': 'inactive',
  };
  
  // Getters
  List<SecurityDeviceModel> get devices => _devices;
  List<SecurityDeviceModel> get doorDevices => _devices.where((d) => d.deviceType == 'door_lock').toList();
  List<SecurityDeviceModel> get windowDevices => _devices.where((d) => d.deviceType == 'window_sensor').toList();
  List<SecurityDeviceModel> get motionDevices => _devices.where((d) => d.deviceType == 'motion_sensor').toList();
  List<SecurityEventModel> get events => _events;
  List<SecurityEventModel> get recentEvents => _recentEvents;
  bool get isLoading => _isLoading;
  bool get alarmSystemActive => _alarmSystemActive;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get securityStats => _securityStats;
  
  SecurityProvider() {
    // Start periodic refresh for realtime updates
    _startPeriodicRefresh();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _startPeriodicRefresh() {
    // Refresh security data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshSecurityData();
    });
  }
  
  Future<void> refreshSecurityData() async {
    // Load both devices and events without showing loading state
    try {
      await Future.wait([
        loadSecurityDevices(showLoading: false),
        loadSecurityEvents(limit: 20, showLoading: false),
        loadRecentSecurityEvents(limit: 5),
        checkAlarmSystemStatus(),
      ]);
    } catch (e) {
      // Just log the error instead of calling notifyListeners() during build
      print('Error refreshing data: ${e.toString()}');
      // Set the error message but don't notify - it will be shown on next interaction
      _errorMessage = 'Error refreshing data: ${e.toString()}';
    }
  }

  // Load security devices
  Future<void> loadSecurityDevices({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      // Only notify once before the async operation
      notifyListeners();
    }
    
    try {
      final devicesJson = await SupabaseService.getSecurityDevices();
      _devices = devicesJson.map((json) => SecurityDeviceModel.fromJson(json)).toList();
      
      // Calculate stats
      _updateSecurityStats();
      
      if (showLoading) {
        _isLoading = false;
      }
      // Only notify once after the operation is complete
      if (!showLoading) return; // Don't notify if not showing loading
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load security devices: ${e.toString()}';
      if (showLoading) {
        _isLoading = false;
      }
      // Only notify once after the operation fails
      if (!showLoading) return; // Don't notify if not showing loading
      notifyListeners();
    }
  }

  // Load security events
  Future<void> loadSecurityEvents({int limit = 20, bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      // Only notify once before the async operation
      notifyListeners();
    }
    
    try {
      final eventsJson = await SupabaseService.getSecurityEvents(limit: limit);
      _events = eventsJson.map((json) => SecurityEventModel.fromJson(json)).toList();
      
      if (showLoading) {
        _isLoading = false;
      }
      // Only notify once after the operation is complete
      if (!showLoading) return; // Don't notify if not showing loading
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load security events: ${e.toString()}';
      if (showLoading) {
        _isLoading = false;
      }
      // Only notify once after the operation fails
      if (!showLoading) return; // Don't notify if not showing loading
      notifyListeners();
    }
  }
  
  // Load only recent security events
  Future<void> loadRecentSecurityEvents({int limit = 5}) async {
    try {
      final eventsJson = await SupabaseService.getSecurityEvents(limit: limit);
      _recentEvents = eventsJson.map((json) => SecurityEventModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load recent events: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Check alarm system status
  Future<void> checkAlarmSystemStatus() async {
    try {
      final status = await SupabaseService.getAlarmSystemStatus();
      _alarmSystemActive = status == 'active';
      _securityStats['alarm_status'] = status;
      notifyListeners();
    } catch (e) {
      print('Error checking alarm status: ${e.toString()}');
    }
  }
  
  // Toggle alarm system
  Future<void> toggleAlarmSystem({required bool active}) async {
    try {
      await SupabaseService.setAlarmSystemStatus(active ? 'active' : 'inactive');
      _alarmSystemActive = active;
      _securityStats['alarm_status'] = active ? 'active' : 'inactive';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to toggle alarm system: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Toggle security device (lock/unlock)
  Future<void> toggleSecurityDevice({required int deviceId, required bool secure}) async {
    try {
      await SupabaseService.toggleSecurityDevice(deviceId.toString(), secure);
      
      // Update device in local state
      final index = _devices.indexWhere((d) => d.deviceId == deviceId);
      if (index >= 0) {
        var device = _devices[index];
        final updatedDevice = SecurityDeviceModel(
          deviceId: device.deviceId,
          deviceType: device.deviceType,
          name: device.name,
          location: device.location,
          classroomName: device.classroomName,
          classroomId: device.classroomId,
          status: secure ? 'secured' : 'breached',
          isActive: device.isActive,
          lastUpdated: DateTime.now(),
        );
        
        _devices[index] = updatedDevice;
        _updateSecurityStats();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle device: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Acknowledge security event
  Future<void> acknowledgeSecurityEvent(int eventId) async {
    try {
      await SupabaseService.acknowledgeSecurityEvent(eventId);
      
      // Update events in local state
      final index = _events.indexWhere((e) => e.eventId == eventId);
      if (index >= 0) {
        final updatedEvent = SecurityEventModel(
          eventId: _events[index].eventId,
          deviceId: _events[index].deviceId,
          deviceName: _events[index].deviceName,
          eventType: _events[index].eventType,
          description: _events[index].description,
          timestamp: _events[index].timestamp,
          isAcknowledged: true,
          classroomName: _events[index].classroomName,
        );
        
        _events[index] = updatedEvent;
        
        // Also update in recent events if needed
        final recentIndex = _recentEvents.indexWhere((e) => e.eventId == eventId);
        if (recentIndex >= 0) {
          _recentEvents[recentIndex] = updatedEvent;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to acknowledge event: ${e.toString()}';
      notifyListeners();
    }
  }
  
  void _updateSecurityStats() {
    int total = _devices.length;
    int secured = _devices.where((d) => d.status == 'secured').length;
    int breached = _devices.where((d) => d.status == 'breached').length;
    int offline = _devices.where((d) => d.status == 'offline').length;
    
    _securityStats = {
      'total_devices': total,
      'secured_devices': secured,
      'breached_devices': breached,
      'offline_devices': offline,
      'alarm_status': _securityStats['alarm_status'] ?? 'inactive',
    };
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}