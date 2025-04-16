import 'package:flutter/material.dart';

// App name and version
const String appName = 'Smart School';
const String appVersion = '0.1.0';

// Supabase configuration
const String supabaseUrl = 'https://wkvkynmbnqycxnkfdvip.supabase.co'; // Replace with your Supabase URL
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indrdmt5bm1ibnF5Y3hua2ZkdmlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMyMzE4OTUsImV4cCI6MjA1ODgwNzg5NX0.kj95zrdFOJaBRZoJ4SBRcv2TDfC5rQeNliaCubsM6Sk'; // Replace with your Supabase anon key

// Theme colors
class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);
  static const Color text = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

// Status indicators
enum DeviceStatus {
  normal,
  warning,
  critical,
}

// Routes
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String department = '/department';
  static const String classroom = '/classroom';
  static const String cameraView = '/camera';
  static const String security = '/security';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
} 