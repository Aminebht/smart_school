import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_model.dart';
import '../../../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Check if user is already authenticated
    
    // Listen for auth changes
    SupabaseService.authStateChanges().listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _getUserProfile();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _getUserProfile() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('user_id', user.id)
            .single();
        
        _user = UserModel.fromJson({
          'id': user.id,
          'email': user.email ?? '',
          'name': response['name'] ?? '',
          'role': response['role'] ?? 'teacher',
        });
        
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to get user profile';
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.signIn(email, password);
      await _getUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initializeAuth() async {
    try {
      print("Starting initializeAuth...");
      // Check for an existing session
      final session = SupabaseService.client.auth.currentSession;
      
      if (session != null) {
        print("Session found: ${session.user.id}");
        final userId = session.user.id;
        
        try {
          print("Fetching user data for user_id: $userId");
          // Get user data - trying with int conversion
          final int? userIdInt = int.tryParse(userId);
          print("Converted user_id to int: $userIdInt");
          
          if (userIdInt != null) {
            print("Using integer user_id: $userIdInt");
            final userData = await SupabaseService.client
                .from('users')
                .select()
                .eq('user_id', userIdInt)
                .single();
                
            print("User data fetched: ${userData.toString()}");
            
            // Make sure we handle null values safely
            _user = UserModel.fromJson({
              'id': userIdInt,
              'email': session.user.email ?? '',
              'name': userData['name'] ?? '',
              'role': userData['role'] ?? 'teacher',
            });
            
            print("User object created successfully");
          } else {
            // Fallback if we can't parse the ID
            print("Could not parse user ID to integer");
            _user = UserModel.fromJson({
              'id': 0,  // Default ID
              'email': session.user.email ?? '',
              'name': session.user.email?.split('@')[0] ?? 'User',
              'role': 'teacher',
            });
          }
        } catch (dbError) {
          print("Database error: $dbError");
          
          // Create minimal user from session
          _user = UserModel.fromJson({
              'id': 0,  // Default ID 
              'email': session.user.email ?? '',
              'name': session.user.email?.split('@')[0] ?? 'User',
              'role': 'teacher',
          });
        }
      } else {
        print("No session found");
        _user = null;
      }
    } catch (e) {
      print("Error in initializeAuth: $e");
      _errorMessage = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print("initializeAuth complete. User: ${_user != null ? 'logged in' : 'logged out'}");
    }
  }
}