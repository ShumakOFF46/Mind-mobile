import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/storage.dart';
import '../../../core/theme.dart';
import 'avatar_picker_sheet.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.completion,
    required this.photos,
  });

  final String?                    name;
  final String                     completion;
  final List<Map<String, dynamic>> photos;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    return Column(
      children: [
        const SizedBox(height: 8),
        _AvatarWithPicker(photos: photos),
        const SizedBox(height: 16),
        Text(
          name ?? '—',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            color:      c.textDark,
            fontSize:   28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.profileMember,
          style: TextStyle(color: c.accent, fontSize: 12, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        _ProfileProgress(completion: completion),
      ],
    );
  }
}

// ─── Avatar + picker button ────────────────────────────

class _AvatarWithPicker extends StatelessWidget {
  const _AvatarWithPicker({required this.photos});

  final List<Map<String, dynamic>> photos;

  Future<void> _pickAvatar(BuildContext context) async {
    final c = context.aura;
    final l = context.l10n;

    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(l.profileAddPhotosFirst),
        backgroundColor: c.textDark,
        behavior:        SnackBarBehavior.floating,
      ));
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context:         context,
      backgroundColor: Colors.transparent,
      builder:         (_) => AvatarPickerSheet(photos: photos),
    );
    if (selected == null) return;
    await AppStorage.saveAvatarPath(selected);
  }

  ImageProvider? _resolveImage(String? path) {
    if (path == null) return null;
    return path.startsWith('http')
        ? NetworkImage(path)
        : FileImage(File(path)) as ImageProvider;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return ValueListenableBuilder<String?>(
      valueListenable: AppStorage.avatarNotifier,
      builder: (_, avatarPath, _) {
        final image = _resolveImage(avatarPath);
        return SizedBox(
          width:  96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius:          48,
                backgroundColor: c.aiBubble,
                backgroundImage: image,
                child: image == null
                    ? Icon(Icons.person_outline, color: c.accent, size: 48)
                    : null,
              ),
              Positioned(
                top:   0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickAvatar(context),
                  child: Container(
                    width:  28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:        c.accent,
                      borderRadius: BorderRadius.circular(6),
                      border:       Border.all(color: c.bg, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Progress bar ──────────────────────────────────────

class _ProfileProgress extends StatelessWidget {
  const _ProfileProgress({required this.completion});

  final String completion;

  double _parse(String s) {
    final n = int.tryParse(s.replaceAll('%', '')) ?? 0;
    return n / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.profileCompletion,
                style: TextStyle(color: c.textSub, fontSize: 12)),
            Text(completion,
                style: TextStyle(
                    color: c.accent, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           _parse(completion),
            backgroundColor: c.userBubble,
            color:           c.accent,
            minHeight:       4,
          ),
        ),
      ],
    );
  }
}
