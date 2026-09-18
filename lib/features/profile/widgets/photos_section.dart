import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import 'profile_tiles.dart';

class PhotosSection extends StatelessWidget {
  const PhotosSection({
    super.key,
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
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(c, l.profileMyPhotos),
        const SizedBox(height: 12),
        if (loading)
          Center(child: CircularProgressIndicator(color: c.accent))
        else if (photos.isEmpty)
          _emptyState(c, l)
        else
          _grid(c),
      ],
    );
  }

  Widget _emptyState(AuraColorScheme c, AppLocalizations l) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color:        c.aiBubble,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(Icons.add_photo_alternate_outlined, color: c.textSub, size: 36),
        const SizedBox(height: 8),
        Text(
          l.profileAddPhotosHint,
          style: TextStyle(
            color:      c.textSub,
            fontSize:   13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.profileAddPhotosDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:    c.textSub.withOpacity(0.7),
            fontSize: 11,
            height:   1.5,
          ),
        ),
      ],
    ),
  );

  Widget _grid(AuraColorScheme c) => GridView.builder(
    shrinkWrap:  true,
    physics:     const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount:   3,
      crossAxisSpacing: 8,
      mainAxisSpacing:  8,
    ),
    itemCount: photos.length,
    itemBuilder: (_, i) => _PhotoCell(
      photo:    photos[i],
      scheme:   c,
      onDelete: onDelete,
    ),
  );
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({
    required this.photo,
    required this.scheme,
    required this.onDelete,
  });

  final Map<String, dynamic>     photo;
  final AuraColorScheme          scheme;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final c   = scheme;
    final url = photo['url'] as String;
    return GestureDetector(
      onLongPress: () => onDelete(photo['id'] as String),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
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
          ),
          if (photo['analyzed'] == true)
            Positioned(
              top: 4, right: 4,
              child: Container(
                padding:    const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: c.accent, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 10),
              ),
            ),
        ],
      ),
    );
  }
}
