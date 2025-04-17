import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  VideoPlayerController? _videoController;
  bool _isFullScreen = false;
  bool _showControls = true;
  bool _isInitializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.camera.streamUrl.isEmpty) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
      });
      return;
    }

    final isVideoStream = widget.camera.streamUrl.contains('.m3u8') ||
        widget.camera.streamUrl.contains('stream') ||
        widget.camera.streamUrl.contains('.mp4');

    if (isVideoStream) {
      _videoController = VideoPlayerController.network(
        widget.camera.streamUrl,
      );

      _videoController!.initialize().then((_) {
        _videoController!.play();
        _videoController!.setLooping(true);
        setState(() {
          _isInitializing = false;
        });
      }).catchError((error) {
        print("Video initialization error: $error");
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      });
    } else {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Center(
              child: _isInitializing
                  ? const CircularProgressIndicator()
                  : _hasError
                      ? _buildErrorWidget()
                      : _buildVideoOrImageWidget(),
            ),
          ),
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoOrImageWidget() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return Image.network(
        widget.camera.streamUrl,
        fit: _isFullScreen ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }
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

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        Container(
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
            ],
          ),
        ),
        Spacer(),
        Container(
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
                icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                label: 'Fullscreen',
                onPressed: () {
                  setState(() {
                    _isFullScreen = !_isFullScreen;
                  });
                },
              ),
              if (_videoController != null)
                _buildControlButton(
                  icon: _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  label: _videoController!.value.isPlaying ? 'Pause' : 'Play',
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}