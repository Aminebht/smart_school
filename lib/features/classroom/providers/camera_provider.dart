import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/camera_model.dart';
import '../../../services/supabase_service.dart';

class CameraProvider extends ChangeNotifier {
  CameraModel? _camera;
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isFullscreen = false;
  String? _errorMessage;
  
  // Timer for tracking recording duration
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  
  // Getters
  CameraModel? get camera => _camera;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  bool get isFullscreen => _isFullscreen;
  String? get errorMessage => _errorMessage;
  
  String get recordingDuration {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
  
  // Load camera details
  Future<void> loadCamera(int cameraId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final cameras = await SupabaseService.getCameraDetails(cameraId);
      if (cameras.isNotEmpty) {
        _camera = CameraModel.fromJson(cameras.first);
      } else {
        _errorMessage = 'Camera not found';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load camera: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Toggle recording state
  void toggleRecording() {
    _isRecording = !_isRecording;
    
    if (_isRecording) {
      // Start recording
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;
        notifyListeners();
      });
      
      // In a real app, this would start recording on the server
    } else {
      // Stop recording
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      // In a real app, this would stop recording on the server
    }
    
    notifyListeners();
  }
  
  // Take a snapshot of the current view
  void takeSnapshot() {
    // In a real app, this would capture a snapshot on the server
    // and potentially save it or notify the user
  }
  
  // Toggle fullscreen mode
  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }
  
  // Camera control methods
  void zoomIn() {
    // In a real app, this would send a command to the camera to zoom in
  }
  
  void zoomOut() {
    // In a real app, this would send a command to the camera to zoom out
  }
  
  void panLeft() {
    // In a real app, this would send a command to the camera to pan left
  }
  
  void panRight() {
    // In a real app, this would send a command to the camera to pan right
  }
} 