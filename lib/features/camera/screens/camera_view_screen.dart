import 'package:flutter/material.dart';
import '../../../core/models/camera_model.dart';
import '../../../core/services/camera_service.dart';
import '../../../services/supabase_service.dart';

class CameraViewScreen extends StatefulWidget {
  final CameraModel camera;

  const CameraViewScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  bool _isFullScreen = false;
  bool _isRecording = false;
  bool _showControls = true;
  bool _motionDetectionEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Stream (takes up full screen)
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Center(
              child: widget.camera.streamUrl.isNotEmpty
                  ? Image.network(
                      widget.camera.streamUrl,
                      fit: _isFullScreen ? BoxFit.cover : BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorWidget();
                      },
                    )
                  : _buildErrorWidget(),
            ),
          ),

          // Top controls bar (AppBar replacement)
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.camera.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 8,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls bar
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  top: 8,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isFullScreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      label: _isFullScreen ? 'Exit Full' : 'Full Screen',
                      onPressed: () {
                        setState(() {
                          _isFullScreen = !_isFullScreen;
                        });
                      },
                    ),
                    _buildControlButton(
                      icon: Icons.camera_alt,
                      label: 'Snapshot',
                      onPressed: _takeSnapshot,
                    ),
                    _buildControlButton(
                      icon: _isRecording
                          ? Icons.stop_circle
                          : Icons.fiber_manual_record,
                      label: _isRecording ? 'Stop' : 'Record',
                      onPressed: _toggleRecording,
                      color: _isRecording ? Colors.red : null,
                    ),
                    _buildControlButton(
                      icon: _motionDetectionEnabled
                          ? Icons.motion_photos_on
                          : Icons.motion_photos_off,
                      label: 'Motion',
                      onPressed: _toggleMotionDetection,
                      color: _motionDetectionEnabled ? Colors.green : null,
                    ),
                  ],
                ),
              ),
            ),

            // Motion detection indicator (when motion is detected)
            if (_motionDetectionEnabled && widget.camera.hasMotion)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Motion Detected',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.videocam_off, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Camera feed unavailable',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Please check connection or try again later',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _takeSnapshot() {
    // Implementation for taking snapshots
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Snapshot taken and saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    
    // Show a snackbar to indicate recording status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording 
            ? 'Recording started' 
            : 'Recording stopped and saved'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleMotionDetection() {
    setState(() {
      _motionDetectionEnabled = !_motionDetectionEnabled;
    });
    
    // Show a snackbar to indicate motion detection status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_motionDetectionEnabled 
            ? 'Motion detection enabled' 
            : 'Motion detection disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}