import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../chat_controller.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../photo_capture/capture_screen.dart';
import '../../photo_capture/models/capture_result.dart';

class ChatInputBar extends StatelessWidget {
  final ChatController controller;
  const ChatInputBar({super.key, required this.controller});

  void _showPhotoSourceSheet(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        c.textSub.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // ── Обычная камера ──
            _PhotoSourceItem(
              icon:  Icons.camera_alt_outlined,
              label: l.takePhoto,
              color: c.accent,
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(context, ImageSource.camera);
              },
            ),
            Divider(height: 1, color: c.textSub.withValues(alpha: 0.15)),
            // ── Галерея ──
            _PhotoSourceItem(
              icon:  Icons.photo_library_outlined,
              label: l.chooseFromGallery,
              color: c.textDark,
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(context, ImageSource.gallery);
              },
            ),
            Divider(height: 1, color: c.textSub.withValues(alpha: 0.15)),
            // ── Образцовая съёмка (guided capture) ──
            _PhotoSourceItem(
              icon:  Icons.face_retouching_natural_outlined,
              label: l.guidedCapture,
              color: c.accent,
              onTap: () {
                Navigator.pop(context);
                _startGuidedCapture(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Запуск guided capture — открывает экран, получает результат,
  /// отправляет фото в чат с qualityMetadata.
  Future<void> _startGuidedCapture(BuildContext context) async {
    final l = context.l10n;
    try {
      // Открываем CaptureScreen, ждём результат
      final result = await Navigator.push<CaptureResult>(
        context,
        MaterialPageRoute(
          builder: (_) => const CaptureScreen(),
        ),
      );

      // Пользователь мог закрыть экран без съёмки
      if (result == null || !context.mounted) return;

      // Отправляем фото с qualityMetadata
      await controller.uploadAndSendPhoto(
        fileBytes:       Uint8List.fromList(result.fileBytes),
        mimeType:        result.mimeType,
        prompt:          l.photoUploadPrompt,
        qualityMetadata: result.qualityMetadata,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(l.photoUploadFailed),
        backgroundColor: Colors.redAccent,
        behavior:        SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    final l = context.l10n;
    try {
      final file = await ImagePicker().pickImage(
        source: source, imageQuality: 85, maxWidth: 1920, maxHeight: 1920,
      );
      if (file == null) return;
      final Uint8List bytes    = await file.readAsBytes();
      final String   mimeType = file.mimeType ?? 'image/jpeg';
      await controller.uploadAndSendPhoto(
        fileBytes: bytes,
        mimeType:  mimeType,
        prompt:    l.photoUploadPrompt,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(l.photoUploadFailed),
        backgroundColor: Colors.redAccent,
        behavior:        SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: controller.inputController,
          builder: (context, _) {
            final hasText = controller.inputController.text.trim().isNotEmpty;
            
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              color:   c.bg,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color:        c.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(
                      color:      c.textDark.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset:     const Offset(0, 2),
                    )],
                  ),
                  child: TextField(
                    controller:      controller.inputController,
                    style:           TextStyle(color: c.textDark, fontSize: 15),
                    enabled:         !controller.isStreaming,
                    minLines:        1,
                    maxLines:        5,
                    keyboardType:    TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: controller.isListening
                          ? l.inputListening
                          : l.inputHint,
                      hintStyle: TextStyle(
                        color:    controller.isListening ? c.accent : c.textSub,
                        fontSize: 15,
                      ),
                      border:         InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 12),
                      prefixIcon: _buildAttachButton(context, c),
                      prefixIconConstraints: const BoxConstraints(
                          minWidth: 44, minHeight: 44),
                      suffixIcon: hasText
                          ? _buildSendButton(c)
                          : _buildMicButton(c, l),
                      suffixIconConstraints: const BoxConstraints(
                          minWidth: 44, minHeight: 44),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttachButton(BuildContext context, AuraColorScheme c) {
    final busy = controller.isStreaming || controller.isUploadingPhoto;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: busy ? null : () => _showPhotoSourceSheet(context),
        child: SizedBox(
          width:  40,
          height: 40,
          child: Center(
            child: controller.isUploadingPhoto
                ? SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: c.accent),
                  )
                : Icon(Icons.attach_file_rounded, color: c.textSub, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(AuraColorScheme c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, right: 4),
      child: GestureDetector(
        onTap: controller.isStreaming
            ? null
            : () => controller.sendMessage(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(AuraColorScheme c, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: controller.speechAvailable
            ? () => controller.toggleListening(
                  () => controller.sendMessage())
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: controller.isListening ? c.accent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            controller.isListening
                ? Icons.mic_rounded
                : Icons.mic_none_rounded,
            color: controller.isListening ? Colors.white : c.textSub,
            size:  22,
          ),
        ),
      ),
    );
  }
}

class _PhotoSourceItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _PhotoSourceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(
            color: color, fontSize: 15, fontWeight: FontWeight.w400)),
      ]),
    ),
  );
}