import 'package:flutter/material.dart';
import 'package:smart_school/core/models/alert_model.dart';
import 'package:smart_school/services/supabase_service.dart';

class AlertsProvider extends ChangeNotifier {
  List<AlertModel> _alerts = [];
  List<AlertModel> _recentAlerts = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<AlertModel> get alerts => _alerts;
  List<AlertModel> get recentAlerts => _recentAlerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Initialize the provider
  AlertsProvider() {
    loadRecentAlerts();
  }
  
  // Load all alerts with optional filters
  Future<void> loadAlerts({
    int limit = 50, 
    String? severity,
    bool? resolved,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final alertsJson = await SupabaseService.getAlerts(
        limit: limit,
        severity: severity,
        resolved: resolved,
      );
      
      _alerts = alertsJson.map((json) {
        // Create alert data structure for model
        final Map<String, dynamic> alertData = {
          ...json,
        };
        
        // Handle devices data - it will be a nested object, not a column
        if (json['devices'] != null) {
          alertData['device_name'] = json['devices']['name'];
          alertData['device_location'] = json['devices']['location'];
        }
        
        return AlertModel.fromJson(alertData);
      }).toList();

      if (showLoading) {
        _isLoading = false;
      }
      
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Failed to load alerts: $e');
      _errorMessage = 'Failed to load alerts: ${e.toString()}';
      
      if (showLoading) {
        _isLoading = false;
      }
      
      notifyListeners();
    }
  }
  
  // Load recent alerts for dashboard
  Future<void> loadRecentAlerts({int limit = 5, bool showLoading = false}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final alertsJson = await SupabaseService.getRecentAlerts(limit: limit);
      
      _recentAlerts = alertsJson.map((json) {
        final Map<String, dynamic> alertData = {
          ...json,
        };
        
        // Handle devices data correctly
        if (json['devices'] != null) {
          alertData['device_name'] = json['devices']['name'];
          alertData['device_location'] = json['devices']['location'];
        }
        
        return AlertModel.fromJson(alertData);
      }).toList();

      if (showLoading) {
        _isLoading = false;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading recent alerts: $e');
      if (showLoading) {
        _isLoading = false;
      }
    }
  }
  
  // Mark an alert as resolved
  Future<bool> resolveAlert(int alertId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await SupabaseService.resolveAlert(alertId);
      
      if (success) {
        // Update the alert in the local lists
        _updateAlertResolvedStatus(alertId);
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to resolve alert: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to update local state
  void _updateAlertResolvedStatus(int alertId) {
    // Update in main alerts list
    for (int i = 0; i < _alerts.length; i++) {
      if (_alerts[i].alertId == alertId) {
        _alerts[i] = AlertModel(
          alertId: _alerts[i].alertId,
          deviceId: _alerts[i].deviceId,
          alertType: _alerts[i].alertType,
          severity: _alerts[i].severity,
          message: _alerts[i].message,
          timestamp: _alerts[i].timestamp,
          resolved: true,
          resolvedAt: DateTime.now(),
          resolvedById: SupabaseService.getCurrentUserId(),
        );
        break;
      }
    }
    
    // Update in recent alerts list
    for (int i = 0; i < _recentAlerts.length; i++) {
      if (_recentAlerts[i].alertId == alertId) {
        _recentAlerts[i] = AlertModel(
          alertId: _recentAlerts[i].alertId,
          deviceId: _recentAlerts[i].deviceId,
          alertType: _recentAlerts[i].alertType,
          severity: _recentAlerts[i].severity,
          message: _recentAlerts[i].message,
          timestamp: _recentAlerts[i].timestamp,
          resolved: true,
          resolvedAt: DateTime.now(),
          resolvedById: SupabaseService.getCurrentUserId(),
        );
        break;
      }
    }
  }
}