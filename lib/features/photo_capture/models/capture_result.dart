/// Результат guided capture — фото + метаданные качества.
class CaptureResult {
  final List<int> fileBytes;
  final String mimeType;
  final Map<String, dynamic> qualityMetadata;

  CaptureResult({
    required this.fileBytes,
    required this.mimeType,
    required this.qualityMetadata,
  });
}