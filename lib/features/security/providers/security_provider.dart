import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/models/security_device_model.dart';
import '../../../core/models/security_event_model.dart';
import '../../../core/models/alarm_system_model.dart';
import '../../../core/models/alarm_rule_model.dart';
import '../../../core/models/alarm_event_model.dart';
import '../../../core/models/alarm_action_model.dart';
import '../../../core/models/department_model.dart';
import '../../../core/models/classroom_model.dart';
import '../../../core/models/sensor_model.dart';
import '../../../core/models/actuator_model.dart';
import '../../../core/models/camera_model.dart';
import '../../../services/supabase_service.dart';

class SecurityProvider extends ChangeNotifier {
  // Initialize empty collections
  List<SecurityDeviceModel> _devices = [];
  List<SensorModel> _sensors = [];
  List<ActuatorModel> _actuators = [];
  List<CameraModel> _cameras = [];

  // Existing properties
  List<SecurityEventModel> _events = [];
  List<SecurityEventModel> _recentEvents = [];
  bool _isLoading = false;
  bool _alarmSystemActive = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  // New properties for alarm management
  List<AlarmSystemModel> _alarmSystems = [];
  AlarmSystemModel? _currentAlarmSystem;
  List<AlarmRuleModel> _alarmRules = [];
  List<AlarmEventModel> _alarmEvents = [];
  List<AlarmActionModel> _alarmActions = [];

  // Security stats
  Map<String, dynamic> _securityStats = {
    'total_devices': 0,
    'secured_devices': 0,
    'breached_devices': 0,
    'offline_devices': 0,
    'alarm_status': 'inactive',
    'active_alarms': 0,
  };

  // Getters
  // Existing getters
  List<SecurityDeviceModel> get devices => _devices;
  List<SensorModel> get sensors => _sensors;
  List<ActuatorModel> get actuators => _actuators;
  List<CameraModel> get cameras => _cameras;
  List<SecurityDeviceModel> get doorDevices => _devices.where((d) => d.deviceType == 'door_lock').toList();
  List<SecurityDeviceModel> get windowDevices => _devices.where((d) => d.deviceType == 'window_sensor').toList();
  List<SecurityDeviceModel> get motionDevices => _devices.where((d) => d.deviceType == 'motion_sensor').toList();
  List<SecurityEventModel> get events => _events;
  List<SecurityEventModel> get recentEvents => _recentEvents;
  bool get isLoading => _isLoading;
  bool get alarmSystemActive => _alarmSystemActive;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get securityStats => _securityStats;

  // New getters for alarm management
  List<AlarmSystemModel> get alarmSystems => _alarmSystems;
  AlarmSystemModel? get currentAlarmSystem => _currentAlarmSystem;
  List<AlarmRuleModel> get alarmRules => _alarmRules;
  List<AlarmEventModel> get alarmEvents => _alarmEvents;
  List<AlarmActionModel> get alarmActions => _alarmActions;
  int get activeAlarms => _alarmSystems.where((alarm) => alarm.isActive).length;

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

  // Updated refreshSecurityData to include alarm systems
  Future<void> refreshSecurityData() async {
    // Load both devices and events without showing loading state
    try {
      await Future.wait([
        loadSecurityDevices(showLoading: false),
        loadSecurityEvents(limit: 20, showLoading: false),
        loadRecentSecurityEvents(limit: 5),
        loadAlarmSystems(showLoading: false),
        checkAlarmSystemStatus(),
      ]);
    } catch (e) {
      print('Error refreshing data: ${e.toString()}');
      _errorMessage = 'Error refreshing data: ${e.toString()}';
    }
  }

  Future<bool> saveAlarmSystem(AlarmSystemModel alarm) async {
    try {
      Map<String, dynamic> data = alarm.toJson();
      
      // For new records, remove the alarm_id field to let the database generate it
      if (alarm.alarmId == 0) {
        data.remove('alarm_id'); // Remove the ID for new records
        
        // Create new alarm
        final json = await SupabaseService.createAlarmSystem(data);
        if (json != null) {
          final newAlarm = AlarmSystemModel.fromJson(json);
          _alarmSystems.add(newAlarm);
          notifyListeners();
          return true;
        }
      } else {
        // Update existing alarm
        final success = await SupabaseService.updateAlarmSystem(alarm.alarmId, data);
        if (success) {
          final index = _alarmSystems.indexWhere((a) => a.alarmId == alarm.alarmId);
          if (index >= 0) {
            _alarmSystems[index] = alarm;
            notifyListeners();
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to save alarm system: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update this method in your SecurityProvider class
  Future<void> loadSecurityDevices({bool showLoading = true, int? alarmId}) async {
    if (showLoading) {
      _isLoading = true;
    }

    try {
      // Load all devices
      final devicesJson = alarmId != null && alarmId > 0 
          ? await SupabaseService.getSecurityDevicesByAlarm(alarmId)
          : await SupabaseService.getSecurityDevices();
          
      _devices = devicesJson.map((json) => SecurityDeviceModel.fromJson(json)).toList();

      // Additionally load all sensors - regardless of alarm association
      final sensorsJson = await SupabaseService.getSensors();
      _sensors = sensorsJson.map((json) => SensorModel.fromJson(json)).toList();

      // Additionally load all cameras - regardless of alarm association
      final camerasJson = await SupabaseService.getCameras();
      _cameras = camerasJson.map((json) => CameraModel.fromJson(json)).toList();

      // Additionally load all actuators - regardless of alarm association
      final actuatorsJson = await SupabaseService.getActuators();
      _actuators = actuatorsJson.map((json) => ActuatorModel.fromJson(json)).toList();

      // Calculate stats
      _updateSecurityStats();

      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load security devices: ${e.toString()}';
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }
  
  Future<List<ClassroomModel>> getClassroomsByDepartment(int? departmentId) async {
    try {
      final jsonList = await SupabaseService.getClassrooms(departmentId: departmentId);
      return jsonList.map((json) => ClassroomModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load classrooms: ${e.toString()}';
      notifyListeners();
      throw e;
    }
  }

  // Load security events
  Future<void> loadSecurityEvents({int limit = 20, bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final eventsJson = await SupabaseService.getSecurityEvents(limit: limit);
      _events = eventsJson.map((json) => SecurityEventModel.fromJson(json)).toList();

      if (showLoading) {
        _isLoading = false;
      }
      if (!showLoading) return;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load security events: ${e.toString()}';
      if (showLoading) {
        _isLoading = false;
      }
      if (!showLoading) return;
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
      'active_alarms': activeAlarms,
    };
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // New methods for alarm management
  // Load all alarm systems
  Future<void> loadAlarmSystems({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final alarmsJson = await SupabaseService.getAlarmSystems();
      _alarmSystems = alarmsJson.map((json) => AlarmSystemModel.fromJson(json)).toList();

      // Update security stats
      _securityStats['active_alarms'] = activeAlarms;

      if (showLoading) {
        _isLoading = false;
      }

      if (!showLoading) return;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load alarm systems: ${e.toString()}';
      if (showLoading) {
        _isLoading = false;
      }
      if (!showLoading) return;
      notifyListeners();
    }
  }

  // Update the loadAlarmSystem method in SecurityProvider class
  Future<void> loadAlarmSystem(int alarmId) async {
    _isLoading = true;
    
    try {
      final alarm = await SupabaseService.getAlarmSystemById(alarmId);
      
      // Convert to model and set current alarm
      _currentAlarmSystem = AlarmSystemModel.fromJson(alarm);
      
      // Clear previous collections
      _devices = [];
      _sensors = [];
      _actuators = [];
      _cameras = [];
      
      // Load devices if they exist
      if (alarm.containsKey('devices') && alarm['devices'] is List) {
        _devices = (alarm['devices'] as List)
            .map((d) => SecurityDeviceModel.fromJson(d))
            .toList();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load alarm system: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Fix the loadAlarmRules method in SecurityProvider
  Future<void> loadAlarmRules(int alarmId) async {
    _isLoading = true;
    
    try {
      final rulesJson = await SupabaseService.getAlarmRules(alarmId);
      _alarmRules = rulesJson.map((json) => AlarmRuleModel.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load alarm rules: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Save a new alarm rule
  Future<bool> saveAlarmRule(AlarmRuleModel rule) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Save the rule
      final savedRule = await SupabaseService.saveAlarmRule(rule);
      
      // Create model from response and add to list
      final newRule = AlarmRuleModel.fromJson(savedRule);
      _alarmRules.add(newRule);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save alarm rule: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an existing alarm rule
  Future<bool> updateAlarmRule(AlarmRuleModel rule) async {
    try {
      final success = await SupabaseService.updateAlarmRule(rule.ruleId, rule.toJson());
      if (success) {
        final index = _alarmRules.indexWhere((r) => r.ruleId == rule.ruleId);
        if (index >= 0) {
          _alarmRules[index] = rule;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update rule: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Toggle alarm rule active state
  Future<void> toggleAlarmRuleActive(int ruleId, bool isActive) async {
    try {
      await SupabaseService.updateAlarmRule(ruleId, {'is_active': isActive});
      
      // Update local state
      final index = _alarmRules.indexWhere((r) => r.ruleId == ruleId);
      if (index >= 0) {
        final updatedRule = AlarmRuleModel(
          ruleId: _alarmRules[index].ruleId,
          alarmId: _alarmRules[index].alarmId,
          ruleName: _alarmRules[index].ruleName,
          deviceId: _alarmRules[index].deviceId,
          conditionType: _alarmRules[index].conditionType,
          thresholdValue: _alarmRules[index].thresholdValue,
          comparisonOperator: _alarmRules[index].comparisonOperator,
          statusValue: _alarmRules[index].statusValue,
          timeRestrictionStart: _alarmRules[index].timeRestrictionStart,
          timeRestrictionEnd: _alarmRules[index].timeRestrictionEnd,
          daysActive: _alarmRules[index].daysActive,
          isActive: isActive,
          createdAt: _alarmRules[index].createdAt,
          updatedAt: DateTime.now(),
        );
        
        _alarmRules[index] = updatedRule;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle rule: ${e.toString()}';
      notifyListeners();
    }
  }

  // Delete an alarm rule
  Future<bool> deleteAlarmRule(int ruleId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Call the Supabase service to delete the rule
      await SupabaseService.deleteAlarmRule(ruleId);
      
      // If we got here without exceptions, the delete was successful
      // Update local state
      _alarmRules.removeWhere((rule) => rule.ruleId == ruleId);
      
      _isLoading = false;
      notifyListeners();
      return true; // Always return a boolean value
    } catch (e) {
      _errorMessage = 'Error deleting alarm rule: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false; // Return false on error, not null
    }
  }

  // Load alarm events for a specific alarm
  Future<void> loadAlarmEvents(int alarmId, {int limit = 20}) async {
    try {
      final eventsJson = await SupabaseService.getAlarmEvents(alarmId, limit: limit);
      _alarmEvents = eventsJson.map((json) => AlarmEventModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading alarm events: ${e.toString()}');
    }
  }

  // Load alarm actions for a specific alarm
  Future<void> loadAlarmActions(int alarmId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final actionsJson = await SupabaseService.getAlarmActions(alarmId);
      _alarmActions = actionsJson.map((json) => AlarmActionModel.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load alarm actions: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Save a new alarm action
  Future<bool> saveAlarmAction(AlarmActionModel action) async {
    try {
      final actionId = await SupabaseService.createAlarmAction(action.toJson());
      if (actionId != null) {
        // Create a new action with the assigned ID
        final newAction = AlarmActionModel(
          actionId: actionId,
          alarmId: action.alarmId,
          ruleId: action.ruleId,
          actionType: action.actionType,
          actuatorId: action.actuatorId,
          targetState: action.targetState,
          notificationSeverity: action.notificationSeverity,
          notificationMessage: action.notificationMessage,
          notifyUserIds: action.notifyUserIds,
          externalWebhookUrl: action.externalWebhookUrl,
          isActive: action.isActive,
          createdAt: action.createdAt,
          updatedAt: action.updatedAt,
        );
        
        _alarmActions.add(newAction);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to save action: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update an existing alarm action
  Future<bool> updateAlarmAction(AlarmActionModel action) async {
    try {
      final success = await SupabaseService.updateAlarmAction(action.actionId, action.toJson());
      if (success) {
        final index = _alarmActions.indexWhere((a) => a.actionId == action.actionId);
        if (index >= 0) {
          _alarmActions[index] = action;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update action: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Toggle alarm action active state
  Future<void> toggleAlarmActionActive(int actionId, bool isActive) async {
    try {
      await SupabaseService.updateAlarmAction(actionId, {'is_active': isActive});
      
      // Update local state
      final index = _alarmActions.indexWhere((a) => a.actionId == actionId);
      if (index >= 0) {
        final updatedAction = AlarmActionModel(
          actionId: _alarmActions[index].actionId,
          alarmId: _alarmActions[index].alarmId,
          ruleId: _alarmActions[index].ruleId,
          actionType: _alarmActions[index].actionType,
          actuatorId: _alarmActions[index].actuatorId,
          targetState: _alarmActions[index].targetState,
          notificationSeverity: _alarmActions[index].notificationSeverity,
          notificationMessage: _alarmActions[index].notificationMessage,
          notifyUserIds: _alarmActions[index].notifyUserIds,
          externalWebhookUrl: _alarmActions[index].externalWebhookUrl,
          isActive: isActive,
          createdAt: _alarmActions[index].createdAt,
          updatedAt: DateTime.now(),
        );
        
        _alarmActions[index] = updatedAction;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle action: ${e.toString()}';
      notifyListeners();
    }
  }

  // Delete an alarm action
  Future<bool> deleteAlarmAction(int actionId) async {
    try {
      final success = await SupabaseService.deleteAlarmAction(actionId);
      if (success) {
        _alarmActions.removeWhere((action) => action.actionId == actionId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete action: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Toggle alarm system active state
  Future<bool> toggleAlarmActive(int alarmId, bool isActive) async {
    try {
      // Find the alarm in the list
      final index = _alarmSystems.indexWhere((alarm) => alarm.alarmId == alarmId);
      if (index == -1) return false;
      
      // Update the alarm locally first for immediate UI response
      _alarmSystems[index] = _alarmSystems[index].copyWith(isActive: isActive);
      
      // If this is the current alarm being viewed, update it too
      if (_currentAlarmSystem?.alarmId == alarmId) {
        _currentAlarmSystem = _currentAlarmSystem!.copyWith(isActive: isActive);
      }
      
      notifyListeners();
      
      // Make the API call to update on the server
      final response = await SupabaseService.updateAlarmSystem(alarmId, {
        'is_active': isActive
      });
      
      return response != null;
    } catch (e) {
      _errorMessage = 'Failed to toggle alarm: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
    // Delete alarm system
  Future<bool> deleteAlarmSystem(int alarmId) async {
    try {
      await SupabaseService.deleteAlarmSystem(alarmId);

      // Update local state
      _alarmSystems.removeWhere((a) => a.alarmId == alarmId);
      if (_currentAlarmSystem?.alarmId == alarmId) {
        _currentAlarmSystem = null;
      }

      // Update security stats
      _securityStats['active_alarms'] = activeAlarms;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete alarm system: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Acknowledge alarm event
  Future<void> acknowledgeAlarmEvent(int eventId) async {
    try {
      await SupabaseService.acknowledgeAlarmEvent(eventId);

      // Update local state
      final index = _alarmEvents.indexWhere((e) => e.eventId == eventId);
      if (index >= 0) {
        final event = _alarmEvents[index];
        _alarmEvents[index] = AlarmEventModel(
          eventId: event.eventId,
          alarmId: event.alarmId,
          ruleId: event.ruleId,
          triggerValue: event.triggerValue,
          triggerStatus: event.triggerStatus,
          triggeredByDeviceId: event.triggeredByDeviceId,
          triggeredAt: event.triggeredAt,
          acknowledged: true,
          acknowledgedAt: DateTime.now(),
          acknowledgedByUserId: SupabaseService.getCurrentUserId(),
          notes: event.notes,
        );

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to acknowledge alarm event: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get departments for dropdown selection
  Future<List<DepartmentModel>> getDepartments() async {
    try {
      final jsonList = await SupabaseService.getDepartments();
      return jsonList.map((json) => DepartmentModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load departments: ${e.toString()}';
      notifyListeners();
      throw e;
    }
  }

  // Get classrooms for dropdown selection
  Future<List<ClassroomModel>> getClassrooms({int? departmentId}) async {
    try {
      final jsonList = await SupabaseService.getClassrooms(departmentId: departmentId);
      return jsonList.map((json) => ClassroomModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load classrooms: ${e.toString()}';
      notifyListeners();
      throw e;
    }
  }

  // New method to get alarm by ID
  Future<AlarmSystemModel?> getAlarmById(int alarmId) async {
    try {
      // First check if it's already loaded
      for (var alarm in _alarmSystems) {
        if (alarm.alarmId == alarmId) {
          return alarm;
        }
      }

      // If not found locally, load from database
      final alarmJson = await SupabaseService.getAlarmById(alarmId);
      if (alarmJson != null) {
        return AlarmSystemModel.fromJson(alarmJson);
      }

      return null;
    } catch (e) {
      _errorMessage = 'Failed to load alarm: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}