import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'services/face_detector_service.dart';
import 'services/quality_checker.dart';
import 'models/capture_result.dart';

/// Контроллер для guided capture экрана.
class CaptureController extends ChangeNotifier {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  QualityMetrics? _currentMetrics;
  bool _isGoodQuality = false;
  String? _errorMessage;

  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  QualityMetrics? get currentMetrics => _currentMetrics;
  bool get isGoodQuality => _isGoodQuality;
  String? get errorMessage => _errorMessage;

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No camera available';
        notifyListeners();
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isCameraInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      notifyListeners();
    }
  }

  /// Анализ одного кадра (вызывается вручную из UI).
  Future<void> analyzeCurrentFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Получаем кадр с камеры
      final picture = await _cameraController!.takePicture();
      final imageBytes = await picture.readAsBytes();

      // Декодируем изображение для анализа
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        _isProcessing = false;
        return;
      }

      // Создаём InputImage из файла (самый простой путь)
      final inputImage = InputImage.fromFilePath(picture.path);

      // Детекция лица
      final faces = await FaceDetectorService.instance.detectFaces(inputImage);

      if (faces.isEmpty) {
        _currentMetrics = null;
        _isGoodQuality = false;
        notifyListeners();
        _isProcessing = false;
        return;
      }

      // Берём первое (самое большое) лицо
      final face = faces.first;

      // Анализ качества (работает с img.Image)
      _currentMetrics = QualityChecker.analyze(decodedImage, face);
      _isGoodQuality = _currentMetrics!.isGoodQuality;
      notifyListeners();
    } catch (e) {
      debugPrint('Frame analysis error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<CaptureResult?> capturePhoto() async {
    if (_cameraController == null || !_isGoodQuality || _currentMetrics == null) {
      return null;
    }

    try {
      final picture = await _cameraController!.takePicture();
      final fileBytes = await picture.readAsBytes();

      return CaptureResult(
        fileBytes: fileBytes,
        mimeType: 'image/jpeg',
        qualityMetadata: _currentMetrics!.toJson(),
      );
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    FaceDetectorService.instance.dispose();
    super.dispose();
  }
}