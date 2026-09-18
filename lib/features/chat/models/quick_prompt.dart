import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';

class QuickPrompt {
  final IconData icon;
  final String title;
  final String prompt;
  final Color iconColor;
  final bool isRequired;

  const QuickPrompt({
    required this.icon,
    required this.title,
    required this.prompt,
    required this.iconColor,
    this.isRequired = false,
  });
}

class QuickPromptsLibrary {
  static QuickPrompt getOnboarding(AppLocalizations l, AuraColorScheme c) =>
      QuickPrompt(
        icon: Icons.badge_outlined,
        title: l.promptOnboardingTitle,
        prompt: l.promptOnboarding,
        iconColor: c.accent,
        isRequired: true,
      );

  static List<QuickPrompt> getAll(AppLocalizations l, AuraColorScheme c) => [
    QuickPrompt(
      icon: Icons.face_outlined,
      title: l.promptSkincareTitle,
      prompt: l.promptSkincare,
      iconColor: const Color(0xFF7EFFC9),
    ),
    QuickPrompt(
      icon: Icons.brush_outlined,
      title: l.promptMakeupTitle,
      prompt: l.promptMakeup,
      iconColor: const Color(0xFFE8A0A0),
    ),
    QuickPrompt(
      icon: Icons.photo_camera_outlined,
      title: l.promptPhotoTitle,
      prompt: l.promptPhoto,
      iconColor: const Color(0xFFC9A8FF),
    ),
    QuickPrompt(
      icon: Icons.calendar_today_outlined,
      title: l.promptCalendarTitle,
      prompt: l.promptCalendar,
      iconColor: const Color(0xFF4FC3F7),
    ),
    QuickPrompt(
      icon: Icons.shopping_bag_outlined,
      title: l.promptProductsTitle,
      prompt: l.promptProducts,
      iconColor: const Color(0xFFFFB74D),
    ),
    QuickPrompt(
      icon: Icons.healing_outlined,
      title: l.promptProblemsTitle,
      prompt: l.promptProblems,
      iconColor: const Color(0xFFEF5350),
    ),
    QuickPrompt(
      icon: Icons.auto_awesome_outlined,
      title: l.promptAntiAgeTitle,
      prompt: l.promptAntiAge,
      iconColor: const Color(0xFFBA68C8),
    ),
    QuickPrompt(
      icon: Icons.lightbulb_outline,
      title: l.promptQuickTipTitle,
      prompt: l.promptQuickTip,
      iconColor: const Color(0xFFFFF176),
    ),
  ];

  static List<QuickPrompt> buildForState({
    required AppLocalizations l,
    required AuraColorScheme c,
    required bool isProfileComplete,
    int totalCount = 4,
  }) {
    final result = <QuickPrompt>[];
    if (!isProfileComplete) {
      result.add(getOnboarding(l, c));
    }
    final all = getAll(l, c);
    final shuffled = List<QuickPrompt>.from(all)..shuffle(Random());
    final needMore = totalCount - result.length;
    result.addAll(shuffled.take(needMore));
    return result;
  }
}