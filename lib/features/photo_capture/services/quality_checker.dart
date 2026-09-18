import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Метрики качества фото для guided capture.
class QualityMetrics {
  final double score;
  final String lighting;
  final double sharpness;
  final double faceRatio;
  final double yaw;
  final double pitch;

  QualityMetrics({
    required this.score,
    required this.lighting,
    required this.sharpness,
    required this.faceRatio,
    required this.yaw,
    required this.pitch,
  });

  bool get isGoodQuality =>
      score >= 0.7 &&
      lighting == 'good' &&
      sharpness >= 0.5 &&  // ← ИЗМЕНЕНО: было 0.7, стало 0.5
      faceRatio >= 0.3 &&
      yaw.abs() <= 15 &&
      pitch.abs() <= 15;

  Map<String, dynamic> toJson() => {
        'score': score,
        'lighting': lighting,
        'sharpness': sharpness,
        'face_ratio': faceRatio,
        'yaw': yaw,
        'pitch': pitch,
      };
}

/// Анализ качества фото в реальном времени.
class QualityChecker {
  static QualityMetrics analyze(
    img.Image image,
    Face face,
  ) {
    final imageWidth = image.width;
    final imageHeight = image.height;

    final avgBrightness = _calculateAverageBrightness(image);
    final lighting = _classifyLighting(avgBrightness);
    final sharpness = _calculateSharpness(image);

    final faceBox = face.boundingBox;
    final faceArea = faceBox.width * faceBox.height;
    final imageArea = imageWidth * imageHeight;
    final faceRatio = faceArea / imageArea;

    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;

    final score = _calculateOverallScore(
      lighting: lighting,
      sharpness: sharpness,
      faceRatio: faceRatio,
      yaw: yaw,
      pitch: pitch,
    );

    return QualityMetrics(
      score: score,
      lighting: lighting,
      sharpness: sharpness,
      faceRatio: faceRatio,
      yaw: yaw,
      pitch: pitch,
    );
  }

  static double _calculateAverageBrightness(img.Image image) {
    final grayscale = img.grayscale(image);
    int sum = 0;
    int count = 0;

    for (int y = 0; y < grayscale.height; y += 2) {
      for (int x = 0; x < grayscale.width; x += 2) {
        final pixel = grayscale.getPixel(x, y);
        sum += pixel.r.toInt();
        count++;
      }
    }

    return count > 0 ? sum / count : 128.0;
  }

  static String _classifyLighting(double brightness) {
    if (brightness < 80) return 'dim';
    if (brightness > 220) return 'overexposed';
    return 'good';
  }

  static double _calculateSharpness(img.Image image) {
    final grayscale = img.grayscale(image);
    final width = grayscale.width;
    final height = grayscale.height;

    double gradientSum = 0;
    int count = 0;

    for (int y = 0; y < height - 1; y += 8) {
      for (int x = 0; x < width - 1; x += 8) {
        final p1 = grayscale.getPixel(x, y).r.toInt();
        final p2 = grayscale.getPixel(x + 1, y).r.toInt();
        gradientSum += (p2 - p1).abs();
        count++;
      }
    }

    if (count == 0) return 0.5;

    final avgGradient = gradientSum / count;
    // ИСПРАВЛЕНО: нормализация 0–20 → 0.0–1.0 (было 0–50)
    return (avgGradient / 20).clamp(0.0, 1.0);
  }

  static double _calculateOverallScore({
    required String lighting,
    required double sharpness,
    required double faceRatio,
    required double yaw,
    required double pitch,
  }) {
    double score = 0.0;

    if (lighting == 'good') score += 0.3;
    else if (lighting == 'dim') score += 0.1;
    else if (lighting == 'overexposed') score += 0.15;

    score += sharpness * 0.25;

    if (faceRatio >= 0.3 && faceRatio <= 0.7) score += 0.2;
    else if (faceRatio >= 0.2) score += 0.1;

    final anglePenalty = (yaw.abs() + pitch.abs()) / 30;
    score += (1 - anglePenalty).clamp(0.0, 1.0) * 0.25;

    return score.clamp(0.0, 1.0);
  }
}