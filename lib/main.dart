import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/models/camera_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/department/screens/department_list_screen.dart';
import 'features/department/screens/department_detail_screen.dart';
import 'features/classroom/screens/classroom_detail_screen.dart';
import 'features/camera/screens/camera_view_screen.dart';
import 'features/security/screens/security_dashboard_screen.dart';
import 'features/security/screens/security_events_screen.dart';
import 'features/security/providers/security_provider.dart';
import 'features/security/screens/alarm_systems_screen.dart';
import 'features/security/screens/alarm_edit_screen.dart';
import 'features/security/screens/alarm_events_screen.dart';
import 'features/security/screens/alarm_rules_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Create and initialize auth provider first
  final authProvider = AuthProvider();
  await authProvider.initializeAuth();
  
  runApp(SmartSchoolApp(authProvider: authProvider));
}

class SmartSchoolApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const SmartSchoolApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        // Add other providers here
      ],
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            background: AppColors.background,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
          AppRoutes.dashboard: (context) => const DashboardScreen(),
          AppRoutes.department: (context) => const DepartmentListScreen(),
          AppRoutes.security: (context) => const SecurityDashboardScreen(),
          AppRoutes.securityEvents: (context) => const SecurityEventsScreen(),
          AppRoutes.alarmSystems: (context) => const AlarmSystemsScreen(),
          // Add other routes as they are developed
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.department && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => DepartmentDetailScreen(
                departmentId: settings.arguments as String,
              ),
            );
          }
          if (settings.name == AppRoutes.classroom && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => ClassroomDetailScreen(
                classroomId: settings.arguments as String,
              ),
            );
          }
          if (settings.name == AppRoutes.camera && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => CameraViewScreen(
                camera: settings.arguments as CameraModel,
              ),
            );
          }
          if (settings.name == AppRoutes.alarmEdit) {
            if (settings.arguments != null) {
              return MaterialPageRoute(
                builder: (context) => AlarmEditScreen(
                  alarmId: settings.arguments as int,
                ),
              );
            } else {
              return MaterialPageRoute(
                builder: (context) => const AlarmEditScreen(),
              );
            }
          }
          if (settings.name == AppRoutes.alarmSystems && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => AlarmSystemsScreen(
              ),
            );
          }
         
          if (settings.name == AppRoutes.alarmEvents && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => AlarmEventsScreen(
                alarmId: settings.arguments as int,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
