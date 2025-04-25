import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/alerts/providers/alerts_provider.dart';
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

  Future<void> loadDashboardData([BuildContext? context]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load existing data...
      await loadDepartments();
      await calculateQuickStats();
      
      // Load alerts data only if context is provided
      if (context != null) {
        try {
          final alertsProvider = Provider.of<AlertsProvider>(
            context, 
            listen: false
          );
          await alertsProvider.loadRecentAlerts();
          _recentAlerts = alertsProvider.recentAlerts;
        } catch (e) {
          print('Could not load alerts: $e');
          // Continue execution even if alerts loading fails
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      _isLoading = false;
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

  Future<void> calculateQuickStats() async {
    try {
      // Get all recent sensor readings across classrooms
      final sensorReadingsJson = await SupabaseService.getRecentSensorReadings(limit: 100);
      final List<SensorReadingModel> readings = sensorReadingsJson
          .map((json) => SensorReadingModel.fromJson(json))
          .toList();

      // Calculate temperature average
      final temperatureReadings = readings.where((reading) => 
          reading.sensorType.toLowerCase() == 'temperature').toList();
      double avgTemperature = 0;
      if (temperatureReadings.isNotEmpty) {
        avgTemperature = temperatureReadings.map((r) => r.value).reduce((a, b) => a + b) / 
            temperatureReadings.length;
      }

      // Calculate humidity average
      final humidityReadings = readings.where((reading) => 
          reading.sensorType.toLowerCase() == 'humidity').toList();
      double avgHumidity = 0;
      if (humidityReadings.isNotEmpty) {
        avgHumidity = humidityReadings.map((r) => r.value).reduce((a, b) => a + b) / 
            humidityReadings.length;
      }

      // Calculate air quality (gas) average - replacing occupancy rate
      final gasReadings = readings.where((reading) => 
          reading.sensorType.toLowerCase() == 'gas').toList();
      double avgAirQuality = 0;
      if (gasReadings.isNotEmpty) {
        avgAirQuality = gasReadings.map((r) => r.value).reduce((a, b) => a + b) / 
            gasReadings.length;
      }

      // Count unresolved alerts
      int alertCount = 0;
      if (_recentAlerts.isNotEmpty) {
        // If 'resolved' property exists in your AlertModel
        if (_recentAlerts[0].toString().contains('resolved')) {
          alertCount = _recentAlerts.where((alert) => alert.resolved == false).length;
        } else {
          // If the property doesn't exist, count all alerts
          alertCount = _recentAlerts.length;
        }
      }

      // Update quick stats
      _quickStats = {
        'average_temperature': double.parse(avgTemperature.toStringAsFixed(1)),
        'average_humidity': double.parse(avgHumidity.toStringAsFixed(1)),
        'air_quality': double.parse(avgAirQuality.toStringAsFixed(1)),
        'alert_count': alertCount.toDouble(),
      };

    } catch (e) {
      _errorMessage = 'Failed to calculate stats: ${e.toString()}';
      // Initialize with default values if calculation fails
      _quickStats = {
        'average_temperature': 0,
        'average_humidity': 0,
        'air_quality': 0,
        'alert_count': 0,
      };
      print('Error in calculateQuickStats: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}