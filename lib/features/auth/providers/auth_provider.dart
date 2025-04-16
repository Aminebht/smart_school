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
    _initializeUser();
    
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

  Future<void> _initializeUser() async {
    final currentUser = SupabaseService.getCurrentUser();
    if (currentUser != null) {
      await _getUserProfile();
    }
  }

  Future<void> _getUserProfile() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        
        _user = UserModel.fromJson({
          'id': user.id,
          'email': user.email ?? '',
          'name': response['name'] ?? '',
          'role': response['role'] ?? 'teacher',
          'avatar_url': response['avatar_url'],
          'is_active': response['is_active'] ?? true,
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
} 