import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/vision/preview_page.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import 'vision_controller.dart';
import 'damage_painter.dart';

/// VisionPage implements the layered stack architecture
/// for Smart Patrol System.
///
/// Architecture:
/// - Layer 1 (Bottom): CameraPreview - Live video feed from hardware
/// - Layer 2 (Top): CustomPaint - Digital overlay for detection boxes
///
/// This follows Separation of Concerns principle:
/// - VisionController: Manages camera lifecycle and detection logic
/// - VisionPage: Manages UI layout and user interactions
/// - DamagePainter: Manages drawing logic (Phase 4)
class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  // Initialize controller locally for this page
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();

    // Start mock detection (Phase 5)
    _visionController.startMockDetection();
  }

  @override
  void dispose() {
    // MANDATORY: Disconnect camera when navigating away
    // This prevents memory leaks and battery drain
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart-Patrol Vision"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _visionController.isFlashlightOn
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () {
                  _visionController.toggleFlashlight();
                },
              );
            },
          ),

          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _visionController.isOverlayVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  _visionController.toggleOverlay();
                },
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          // Show loading if camera is initializing
          if (!_visionController.isInitialized) {
            return _buildLoadingState();
          }

          // Continue to Stack structure
          return _buildVisionStack();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final image = await _visionController.takePhoto();

          if (image != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreviewPage(
                  imagePath: image.path,
                  controller: _visionController,
                ),
              ),
            );
          }
        },
        tooltip: 'Capture Photo',
        child: const Icon(Icons.camera),
      ),
    );
  }

  /// Build loading state with informative message
  /// Phase 6 UX Enhancement
  Widget _buildLoadingState() {
    final hasError = _visionController.errorMessage != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!hasError) ...[
            Lottie.asset(
              'assets/images/loadingCam.json',
              width: 180,
              repeat: true,
            ),
            const SizedBox(height: 16),
            const Text(
              "Menghubungkan ke Sensor Visual...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (hasError) ...[
            Lottie.asset(
              'assets/images/camera.json', 
              width: 150,
              repeat: true,
            ),
            const SizedBox(height: 16),
            const Text(
              "No Camera Access",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _visionController.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text("Open Settings"),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the layered stack architecture
  ///
  /// This is the core of Vision architecture:
  /// - Stack with fit: StackFit.expand fills entire screen
  /// - Layer 1: CameraPreview with AspectRatio to prevent distortion
  /// - Layer 2: CustomPaint for digital overlay
  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // LAYER 1: Hardware Preview
        // Use AspectRatio to prevent image distortion (PCD Connection)
        // Camera images often have different aspect ratios than screen
        // This ensures the image maintains correct proportions
        Center(
          child: Transform.scale(
            scale: 1 /
                (_visionController.controller!.value.aspectRatio *
                    MediaQuery.of(context).size.aspectRatio),
            child: Center(
              child: CameraPreview(_visionController.controller!),
            ),
          )
        ),

        // LAYER 2: Digital Overlay (Canvas)
        // This layer is transparent and sits exactly above camera
        // DamagePainter will draw detection boxes here (Phase 4)
        if (_visionController.isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(
                _visionController.currentDetections,
              ), // Phase 4: Will be updated with detections
            ),
          ),
      ],
    );
  }
}
