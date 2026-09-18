import 'package:flutter/material.dart';
import '../../../core/theme.dart';

Widget sectionTitle(AuraColorScheme c, String title) => Text(
  title,
  style: TextStyle(
    fontFamily:    'CormorantGaramond',
    color:         c.textSub,
    fontSize:      13,
    fontWeight:    FontWeight.w600,
    letterSpacing: 2,
  ),
);

Widget infoTile(AuraColorScheme c, String label, String value) => Container(
  margin:  const EdgeInsets.only(bottom: 8),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  decoration: BoxDecoration(
    color:        c.aiBubble,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Text(label, style: TextStyle(color: c.textSub, fontSize: 13)),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          style: TextStyle(
            color:      c.textDark,
            fontSize:   13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
          overflow:  TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
);

Widget profileTile(AuraColorScheme c, String label, String value) => Container(
  margin:  const EdgeInsets.only(bottom: 8),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  decoration: BoxDecoration(
    color:        c.aiBubble,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(
            color:         c.textSub,
            fontSize:      11,
            letterSpacing: 0.5,
          )),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
            color:      c.textDark,
            fontSize:   14,
            fontWeight: FontWeight.w400,
            height:     1.4,
          )),
    ],
  ),
);
