import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import 'photos_section.dart';

const _kJournalPreviewCap = 6;

/// Вкладка "Skin Journal": превью последних фото (капс — 6, 2 ряда по 3,
/// см. концепт Profile2.JPG) + "See All", открывающий полный список без
/// ограничения через уже существующий PhotosSection.
///
/// ⚠ Это по-прежнему НЕ полноценный журнал результатов анализа кожи
/// (`beauty.user_skin_scans` — severity_flag/escalation, см.
/// ProjectFull.md §Safety) — та фича клиническая и в мобильном
/// приложении вообще не реализована. "Skin Journal" здесь — витрина
/// поверх уже существующих загруженных фото (`beauty.user_photos`), не
/// новая сущность и не новый эндпоинт.
class SkinJournalSection extends StatelessWidget {
  const SkinJournalSection({
    super.key,
    required this.photos,
    required this.loading,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> photos;
  final bool                       loading;
  final void Function(String id)   onDelete;

  void _openFullGallery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FullGallerySheet(
        photos: photos,
        loading: loading,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final preview = photos.take(_kJournalPreviewCap).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.profileTabJournal,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  color:      c.textDark,
                  fontSize:   18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // "See All" показываем, только если реально есть что
              // показывать сверх превью — иначе ссылка вела бы в никуда.
              if (photos.length > _kJournalPreviewCap)
                GestureDetector(
                  onTap: () => _openFullGallery(context),
                  child: Text(
                    l.profileSeeAll,
                    style: TextStyle(
                        color: c.accent, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            Center(child: CircularProgressIndicator(color: c.accent))
          else if (preview.isEmpty)
            _emptyState(c, l)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   3,
                crossAxisSpacing: 8,
                mainAxisSpacing:  8,
              ),
              itemCount: preview.length,
              itemBuilder: (_, i) => _JournalPhotoCell(
                photo:    preview[i],
                scheme:   c,
                l10n:     l,
                onDelete: onDelete,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(AuraColorScheme c, AppLocalizations l) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration:
        BoxDecoration(color: c.aiBubble, borderRadius: BorderRadius.circular(12)),
    child: Column(
      children: [
        Icon(Icons.add_photo_alternate_outlined, color: c.textSub, size: 36),
        const SizedBox(height: 8),
        Text(l.profileAddPhotosHint,
            style: TextStyle(
                color: c.textSub, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

/// Плитка превью с оверлеем даты снизу — компактный вариант специально
/// для вкладки Skin Journal. Отличие от `_PhotoCell` в photos_section.dart
/// — именно оверлей даты; полный грид ("See All") использует
/// немодифицированный `PhotosSection` без этого оверлея.
class _JournalPhotoCell extends StatelessWidget {
  const _JournalPhotoCell({
    required this.photo,
    required this.scheme,
    required this.l10n,
    required this.onDelete,
  });

  final Map<String, dynamic>     photo;
  final AuraColorScheme          scheme;
  final AppLocalizations         l10n;
  final void Function(String id) onDelete;

  /// `beauty.user_photos.uploaded_at` (см. ProjectFull.md) — реальное
  /// поле, не выдумка. Формат "Jul 20" переиспользует l.monthShortLabels,
  /// уже добавленный ранее для календаря.
  String? _dateLabel() {
    final raw = photo['uploaded_at'];
    if (raw == null) return null;
    final date = DateTime.tryParse(raw.toString());
    if (date == null) return null;
    return '${l10n.monthShortLabels[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final c = scheme;
    final url = photo['url'] as String;
    final dateLabel = _dateLabel();

    return GestureDetector(
      onLongPress: () => onDelete(photo['id'] as String),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: c.aiBubble,
                child: Icon(Icons.broken_image_outlined, color: c.textSub),
              ),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      color: c.aiBubble,
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.accent),
                      ),
                    ),
            ),
            if (dateLabel != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (photo['analyzed'] == true)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration:
                      BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Полный, некапнутый список фото — открывается по "See All".
/// Переиспользует существующий PhotosSection без изменений (та же
/// "MY PHOTOS"-шапка, та же логика удаления по долгому тапу).
class _FullGallerySheet extends StatelessWidget {
  const _FullGallerySheet({
    required this.photos,
    required this.loading,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> photos;
  final bool                       loading;
  final void Function(String id)   onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: c.hint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            PhotosSection(photos: photos, loading: loading, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}
