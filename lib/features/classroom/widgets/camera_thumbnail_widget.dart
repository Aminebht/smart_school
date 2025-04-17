import 'package:flutter/material.dart';
import 'package:smart_school/core/constants/app_constants.dart';
import '../../../core/models/camera_model.dart';
import '../../../core/services/camera_service.dart';
import '../../camera/screens/camera_view_screen.dart';

class CameraThumbnailWidget extends StatefulWidget {
  final int classroomId;
  final double height;
  final double width;

  const CameraThumbnailWidget({
    Key? key,
    required this.classroomId,
    this.height = 160,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<CameraThumbnailWidget> createState() => _CameraThumbnailWidgetState();
}

class _CameraThumbnailWidgetState extends State<CameraThumbnailWidget> {
  final CameraService _cameraService = CameraService();
  CameraModel? _camera;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCamera();
  }

  Future<void> _loadCamera() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final cameras = await _cameraService.getCamerasForClassroom(widget.classroomId);
      
      if (cameras.isNotEmpty) {
        setState(() {
          _camera = cameras.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _camera = null;
          _isLoading = false;
          _errorMessage = 'No camera found for this classroom';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load camera: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_camera == null) {
      return _buildNoCameraWidget();
    }

    return GestureDetector(
      onTap: () => _openFullscreenView(context),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: widget.height,
              width: widget.width,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _camera!.streamUrl.isNotEmpty
                    ? Image.network(
                        _camera!.streamUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildOfflineCamera();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : _buildOfflineCamera(),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _camera != null && _camera!.isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _camera != null && _camera!.isActive ? 'Live' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                _camera!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 20,
                shadows: const [
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: const Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildNoCameraWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty 
                  ? _errorMessage 
                  : 'No camera installed',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineCamera() {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.videocam_off, size: 40, color: Colors.black54),
            SizedBox(height: 8),
            Text(
              'Camera feed unavailable',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenView(BuildContext context) {
    if (_camera != null && _camera!.isActive) {
      Navigator.pushNamed(
        context,
        AppRoutes.camera,
        arguments: _camera,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_camera == null 
              ? 'No camera available' 
              : 'Camera is offline'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}