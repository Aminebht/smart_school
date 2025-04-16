import 'package:flutter/material.dart';
import '../../../core/models/department_model.dart';
import '../../../core/models/sensor_reading_model.dart';
import '../../../core/models/alert_model.dart';
import '../../../services/supabase_service.dart';

class DashboardProvider extends ChangeNotifier {
  List<DepartmentModel> _departments = [];
  List<AlertModel> _recentAlerts = [];
  Map<String, double> _quickStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<DepartmentModel> get departments => _departments;
  List<AlertModel> get recentAlerts => _recentAlerts;
  Map<String, double> get quickStats => _quickStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardProvider() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load departments
      await loadDepartments();
      
      // Load recent alerts
      await loadRecentAlerts();
      
      // Calculate quick stats
      await calculateQuickStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadDepartments() async {
    try {
      final departmentsJson = await SupabaseService.getDepartments();
      _departments = departmentsJson.map((json) => DepartmentModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load departments: ${e.toString()}';
      throw e;
    }
  }

  Future<void> loadRecentAlerts() async {
    try {
      final alertsJson = await SupabaseService.getAlerts(limit: 5);
      _recentAlerts = alertsJson.map((json) => AlertModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load alerts: ${e.toString()}';
      throw e;
    }
  }

  Future<void> calculateQuickStats() async {
    try {
      // This would typically involve analyzing sensor data across classrooms
      // For now, we'll set placeholder values
      _quickStats = {
        'average_temperature': 24.5,
        'average_humidity': 45.8,
        'occupancy_rate': 65.0,
        'alert_count': _recentAlerts.length.toDouble(),
      };
    } catch (e) {
      _errorMessage = 'Failed to calculate stats: ${e.toString()}';
      throw e;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 