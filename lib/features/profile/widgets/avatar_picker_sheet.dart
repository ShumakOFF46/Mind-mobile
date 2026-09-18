import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';

class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key, required this.photos});

  final List<Map<String, dynamic>> photos;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color:        c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(c),
          const SizedBox(height: 20),
          Text(
            l.profileChoosePhoto,
            style: TextStyle(
              fontFamily:    'CormorantGaramond',
              color:         c.textDark,
              fontSize:      15,
              fontWeight:    FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap:  true,
            physics:     const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   3,
              crossAxisSpacing: 8,
              mainAxisSpacing:  8,
            ),
            itemCount: photos.length,
            itemBuilder: (ctx, i) => _photoCell(ctx, c, photos[i]),
          ),
        ],
      ),
    );
  }

  Widget _dragHandle(AuraColorScheme c) => Container(
    width:  40,
    height: 4,
    decoration: BoxDecoration(
      color:        c.textSub.withOpacity(0.3),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _photoCell(
    BuildContext ctx,
    AuraColorScheme c,
    Map<String, dynamic> photo,
  ) {
    final url = photo['url'] as String;
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, url),
      child: ClipRRect(
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
    );
  }
}
