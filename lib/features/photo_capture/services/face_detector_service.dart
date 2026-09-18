import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Singleton-обёртка над Google ML Kit Face Detection.
/// Работает полностью offline — приватность сохранена.
class FaceDetectorService {
  FaceDetectorService._();
  static final FaceDetectorService instance = FaceDetectorService._();

  late final FaceDetector _detector;
  bool _initialized = false;

  /// Инициализация детектора. Вызывать один раз при старте приложения.
  void init() {
    if (_initialized) return;

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableTracking: false,
        minFaceSize: 0.15,
      ),
    );

    _initialized = true;
  }

  /// Детекция лиц на InputImage.
  Future<List<Face>> detectFaces(InputImage image) async {
    if (!_initialized) init();
    return await _detector.processImage(image);
  }

  /// Освобождение ресурсов.
  Future<void> dispose() async {
    if (_initialized) {
      await _detector.close();
      _initialized = false;
    }
  }
}