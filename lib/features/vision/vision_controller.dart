import 'dart:async';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// VisionController manages the camera lifecycle and detection logic
/// for the Smart Patrol System.
///
/// This controller follows SOLID principles:
/// - Single Responsibility: Manages only camera and detection state
/// - Open/Closed: Can be extended without modifying core logic
/// - Dependency Inversion: Depends on abstractions (ChangeNotifier)
class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  // Camera controller instance
  CameraController? controller;

  // State tracking
  bool isInitialized = false;
  String? errorMessage;

  // Detection results (for Phase 5)
  List<DetectionResult> currentDetections = [];
  Timer? _mockDetectionTimer;

  // UX Enhancement: Flashlight and Overlay toggles (Phase 6)
  bool isFlashlightOn = false;
  bool isOverlayVisible = true;

  VisionController() {
    // Register observer to monitor app lifecycle status
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  /// Initialize the rear camera with medium resolution
  /// ResolutionPreset.medium balances AI accuracy with performance
  Future<void> initCamera() async {
    try {
      final status = await Permission.camera.request();

      if (!status.isGranted) {
        errorMessage = "Camera permission denied. Please enable it in settings.";
        notifyListeners();
        return;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device.";
        notifyListeners();
        return;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Failed to initialize camera: $e";
    }

    notifyListeners();
  }

  /// Capture photo from camera stream
  /// This ensures full frame capture with proper resolution
  Future<XFile?> takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) {
      return null;
    }

    try {
      // Pause camera stream briefly to ensure clean capture
      await controller!.pausePreview();

      // Small delay to ensure camera is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the picture
      final image = await controller!.takePicture();

      // Resume camera stream
      await controller!.resumePreview();

      return image;
    } catch (e) {
      errorMessage = "Failed to capture photo: $e";
      notifyListeners();
      return null;
    }
  }

  /// Handle app lifecycle state changes
  ///
  /// This is CRITICAL for preventing memory leaks and battery drain
  /// - AppLifecycleState.inactive: Release camera when app goes to background
  /// - AppLifecycleState.resumed: Re-initialize camera when app returns to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // If controller doesn't exist or isn't ready, ignore
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Release camera resource when app is not visible
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize when user returns to app
      initCamera();
    }
  }

  /// Toggle flashlight (torch) on/off
  /// UX Enhancement from Phase 6
  Future<void> toggleFlashlight() async {
    if (controller == null || !controller!.value.isInitialized) return;

    isFlashlightOn = !isFlashlightOn;

    try {
      await controller!.setFlashMode(
        isFlashlightOn ? FlashMode.torch : FlashMode.off,
      );

      notifyListeners();
    } catch (e) {
      errorMessage = "Failed to toggle flashlight: $e";
      notifyListeners();
    }

    notifyListeners();
  }

  /// Toggle overlay visibility
  /// UX Enhancement from Phase 6
  void toggleOverlay() {
    isOverlayVisible = !isOverlayVisible;
    notifyListeners();
  }

  /// Start mock detection simulation
  /// Phase 5: Simulates AI detection by moving bounding box every 3 seconds
  void startMockDetection() {
    _mockDetectionTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _generateMockDetection(),
    );
  }

  /// Generate a mock detection result at random position
  /// This simulates YOLO output before actual AI integration in Module 7
  void _generateMockDetection() {
    final random = Random();

    // Generate random normalized coordinates (0.0 - 1.0)
    // Keep within 10%-90% range to avoid edge clipping
    final x = random.nextDouble() * 0.8 + 0.1;
    final y = random.nextDouble() * 0.8 + 0.1;
    final width = 0.2 + random.nextDouble() * 0.2; // 20%-40% of screen width
    final height = 0.1 + random.nextDouble() * 0.1; // 10%-20% of screen height

    // Create detection result
    currentDetections = [
      DetectionResult(
        box: Rect.fromLTWH(x, y, width, height),
        label: _getRandomDamageType(),
        score: 0.85 + random.nextDouble() * 0.14, // 85%-99% confidence
      ),
    ];

    notifyListeners();
  }

  /// Get a random damage type from RDD-2022 dataset
  String _getRandomDamageType() {
      final types = ['D00', 'D10', 'D20', 'D40'];
      final labels = {
        'D00': 'Longitudinal Crack',
        'D10': 'Transverse Crack',
        'D20': 'Alligator Crack',
        'D40': 'Pothole',
      };
      final type = types[Random().nextInt(types.length)];
      return ' [$type] ${labels[type]!}';
    }

  img.Image _histogramEqualization(img.Image src) {
    // Pastikan grayscale
    final gray = img.grayscale(src);

    List<int> hist = List.filled(256, 0);

    // 🔹 Hitung histogram
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final p = gray.getPixel(x, y);
        hist[p.r.toInt()]++;
      }
    }

    // 🔹 Hitung CDF
    List<int> cdf = List.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + hist[i];
    }

    int totalPixels = gray.width * gray.height;

    // Cari CDF minimum (non-zero)
    int cdfMin = cdf.firstWhere((v) => v > 0);

    final output = img.Image.from(gray);

    // 🔹 Mapping pixel baru
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final p = gray.getPixel(x, y);

        int newVal = ((cdf[p.r.toInt()] - cdfMin) * 255 /
                (totalPixels - cdfMin))
            .clamp(0, 255)
            .toInt();

        output.setPixelRgb(x, y, newVal, newVal, newVal);
      }
    }

    return output;
  }

  img.Image applyFilter(img.Image original, String filter) {
    img.Image result = img.Image.from(original);

    switch (filter) {
      case "Low Pass":
        result = img.convolution(
          result,
          filter: [
            1, 1, 1,
            1, 1, 1,
            1, 1, 1,
          ],
          div: 9,
        );
        break;

      case "Gaussian":
        result = img.convolution(
          result,
          filter: [
            1, 2, 1,
            2, 4, 2,
            1, 2, 1,
          ],
          div: 16,
        );
        break;

     case "High Pass":
      result = img.convolution(
        result,
        filter: [
          -1, -1, -1,
          -1,  8, -1,
          -1, -1, -1,
        ],
      );
      break;

    case "Mean":
      result = img.convolution(
        result,
        filter: [
          1, 1, 1,
          1, 1, 1,
          1, 1, 1,
        ],
        div: 9,
      );
      break;
    
    case "Histogram Equalization":
      _histogramEqualization(result);
      break;
    
    case "Band Pass":
      // Low pass first, then subtract to isolate mid frequencies
      final lowPass = img.convolution(
        img.Image.from(original),
        filter: [
          1, 2, 1,
          2, 4, 2,
          1, 2, 1,
        ],
        div: 16,
      );
      final highPass = img.convolution(
        img.Image.from(original),
        filter: [
          -1, -1, -1,
          -1,  8, -1,
          -1, -1, -1,
        ],
      );
      final band = img.Image(width: original.width, height: original.height);
      for (int y = 0; y < original.height; y++) {
        for (int x = 0; x < original.width; x++) {
          final pL = lowPass.getPixel(x, y);
          final pH = highPass.getPixel(x, y);
          band.setPixelRgb(
            x, y,
            (pL.r.toInt() - pH.r.toInt()).clamp(0, 255),
            (pL.g.toInt() - pH.g.toInt()).clamp(0, 255),
            (pL.b.toInt() - pH.b.toInt()).clamp(0, 255),
          );
        }
      }
      result = band;
      break;

    case "Sharpening":
      result = img.convolution(
        result,
        filter: [
          0, -1,  0,
          -1,  5, -1,
          0, -1,  0,
        ],
      );
      break;
    }

    return result;
  }

  /// Clean up resources
  ///
  /// This is MANDATORY to prevent memory leaks
  /// - Remove observer to stop listening to lifecycle events
  /// - Dispose camera controller to release hardware
  /// - Cancel mock detection timer
  @override
  void dispose() {
    // Remove observer to prevent memory leak
    WidgetsBinding.instance.removeObserver(this);

    // Cancel mock detection timer
    _mockDetectionTimer?.cancel();

    // Release camera hardware
    controller?.dispose();

    super.dispose();
  }
}

/// Data Transfer Object (DTO) for detection results
///
/// This follows the Single Responsibility Principle:
/// - VisionController generates these objects
/// - DamagePainter only draws them
///
/// If you replace YOLO with another model, only change data population
/// in VisionController without touching UI or Painter code.
class DetectionResult {
  final Rect box; // Box coordinates (normalized 0.0-1.0)
  final String label; // Damage type (D40, D20, etc)
  final double score; // AI confidence percentage (0.0-1.0)

  DetectionResult({
    required this.box,
    required this.label,
    required this.score,
  });
}
