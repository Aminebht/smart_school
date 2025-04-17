import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/camera_provider.dart';

class CameraViewScreen extends StatefulWidget {
  final int cameraId;

  const CameraViewScreen({
    super.key,
    required this.cameraId,
  });

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CameraProvider()..loadCamera(widget.cameraId),
      child: Consumer<CameraProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Camera Feed')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Camera Feed')),
              body: _buildErrorView(context, provider),
            );
          }

          final camera = provider.camera;
          if (camera == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Camera Feed')),
              body: const Center(
                child: Text('Camera not found'),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(camera.name),
              actions: [
                IconButton(
                  onPressed: () {
                    provider.toggleRecording();
                  },
                  icon: Icon(
                    provider.isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: provider.isRecording ? Colors.red : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    provider.takeSnapshot();
                  },
                  icon: const Icon(Icons.camera_alt),
                ),
              ],
            ),
            body: Column(
              children: [
                // Camera feed (takes most of the screen)
                Expanded(
                  flex: 3,
                  child: _buildCameraFeed(context, provider),
                ),
                
                // Controls at the bottom
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status info
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: camera.isActive ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            camera.isActive ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: camera.isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (provider.isRecording)
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Recording',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Camera controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            context, 
                            Icons.zoom_in, 
                            'Zoom In',
                            () => provider.zoomIn(),
                          ),
                          _buildControlButton(
                            context, 
                            Icons.zoom_out, 
                            'Zoom Out',
                            () => provider.zoomOut(),
                          ),
                          _buildControlButton(
                            context, 
                            Icons.rotate_left, 
                            'Pan Left',
                            () => provider.panLeft(),
                          ),
                          _buildControlButton(
                            context, 
                            Icons.rotate_right, 
                            'Pan Right',
                            () => provider.panRight(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraFeed(BuildContext context, CameraProvider provider) {
    final camera = provider.camera!;
    
    return GestureDetector(
      onTap: () {
        provider.toggleFullscreen();
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: camera.streamUrl.isEmpty
                ? _buildNoFeedPlaceholder()
                : Image.network(
                    camera.streamUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildNoFeedPlaceholder();
                    },
                  ),
            ),
            if (provider.isFullscreen)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () {
                    provider.toggleFullscreen();
                  },
                  icon: const Icon(
                    Icons.fullscreen_exit,
                    color: Colors.white,
                  ),
                ),
              ),
            if (provider.isRecording)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.recordingDuration,
                        style: const TextStyle(
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
      ),
    );
  }

  Widget _buildNoFeedPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.videocam_off,
          color: Colors.white,
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'No camera feed available',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'The camera might be offline or the stream URL is invalid',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: AppColors.primary,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, CameraProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: () => provider.loadCamera(widget.cameraId),
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }
} 