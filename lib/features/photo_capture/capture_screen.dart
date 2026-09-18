import 'dart:async';
import 'package:camera/camera.dart';  // ← ВОЗВРАЩАЕМ (для CameraPreview)
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/l10n/app_localizations.dart';
import 'capture_controller.dart';
import 'widgets/face_overlay.dart';
import 'widgets/quality_indicators.dart';
import 'widgets/quality_hint.dart';

/// Главный экран guided capture.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late CaptureController _controller;
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _controller = CaptureController();
    _controller.initializeCamera().then((_) {
      _startPeriodicAnalysis();
    });
    _controller.addListener(_onControllerChanged);
  }

  void _startPeriodicAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (_controller.isCameraInitialized) {
        _controller.analyzeCurrentFrame();
      }
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.aura;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.captureTitle,
          style: TextStyle(
            color: colors.textDark,
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(colors, l10n),
    );
  }

  Widget _buildBody(AuraColorScheme colors, AppLocalizations l10n) {
    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _controller.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textDark),
          ),
        ),
      );
    }

    if (!_controller.isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Camera preview — стандартный виджет из пакета camera
              CameraPreview(_controller.cameraController!),

              LayoutBuilder(
                builder: (context, constraints) {
                  return FaceOverlay(
                    isGoodQuality: _controller.isGoodQuality,
                    previewSize: Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        if (_controller.currentMetrics != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: QualityIndicators(metrics: _controller.currentMetrics!),
          ),

        if (_controller.currentMetrics != null)
          QualityHint(metrics: _controller.currentMetrics!)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              l10n.captureHintInitial,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.hint,
                fontFamily: 'CormorantGaramond',
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: _controller.isGoodQuality ? () => _onCapture() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              l10n.captureButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'CormorantGaramond',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onCapture() async {
    final result = await _controller.capturePhoto();
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
}