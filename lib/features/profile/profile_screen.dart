import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import 'models/profile_summary.dart';
import 'models/profile_tab.dart';
import 'widgets/beauty_profile_section.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_overflow_sheet.dart';
import 'widgets/profile_summary_card.dart';
import 'widgets/profile_tabs.dart';
import 'widgets/skin_journal_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _userId;

  List<Map<String, dynamic>> _photos  = [];
  Map<String, dynamic>       _profile = {};
  ProfileSummary?            _summary;

  bool _loadingPhotos  = false;
  bool _loadingProfile = false;
  bool _loadingSummary = false;

  /// Локальный UI-state вкладки — намеренно НЕ на Riverpod: весь
  /// остальной ProfileScreen уже StatefulWidget с сетевой логикой (как и
  /// раньше), добавлять смешанную Riverpod/State-архитектуру ради одного
  /// enum'а увеличивает риск регресса без функциональной пользы (тот же
  /// прецедент — ChatController тоже не на Riverpod, см. AURA_mobile.md).
  ProfileTab _activeTab = ProfileTab.beauty;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _loadPhotos();
    _loadProfile();
    _loadSummary();
  }

  Future<void> _loadLocal() async {
    final name = await AppStorage.getUserName();
    final id   = await AppStorage.getOrCreateUserId();
    if (mounted) setState(() { _name = name; _userId = id; });
  }

  Future<void> _loadPhotos() async {
    setState(() => _loadingPhotos = true);
    try {
      final photos = await ApiClient.getPhotos();
      if (mounted) setState(() => _photos = photos);
    } catch (e) {
      debugPrint('loadPhotos error: $e');
    } finally {
      if (mounted) setState(() => _loadingPhotos = false);
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final profile = await ApiClient.getBeautyProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      debugPrint('loadProfile error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  /// CONTRACT_profile_summary_v1.md §4 / BRIEF_mobile_profile_summary.md.
  ///
  /// ⚠ Находка при интеграции, не входившая в бриф дословно: до этой
  /// правки `_loadProfile()` дополнительно дёргал `GET /app/profile/status`
  /// и показывал его поле `completion` в `ProfileHeader`. Этот новый
  /// эндпоинт отдаёт СВОЙ `completion_percent` — детерминированный агрегат
  /// по тем же 7 `profile_*` секциям (§5 контракта). Показывать на одном
  /// экране два потенциально РАЗНЫХ процента заполнения одного и того же
  /// профиля — очевидный UX-баг, поэтому вызов `/app/profile/status`
  /// удалён, а `ProfileHeader` переведён на `completion_percent` отсюда
  /// как более новый и явно детерминированный источник. Не проверено:
  /// действительно ли `/app/profile/status` считает то же самое или
  /// что-то шире (например, включает legal-секции) — если у эндпоинта
  /// есть другие потребители/поля кроме `completion`, это решение стоит
  /// подтвердить с оркестратором отдельно (см. отчёт сессии).
  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final json = await ApiClient.getProfileSummary();
      if (mounted) setState(() => _summary = ProfileSummary.fromJson(json));
    } catch (e) {
      debugPrint('loadProfileSummary error: $e');
      // Сетевая ошибка — не показываем банер ошибки поверх карточки (тот
      // же принцип, что и для backend-статуса failed): просто остаёмся
      // без данных, UI покажет skeleton-placeholder как при pending.
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    final l         = context.l10n;
    final c         = context.aura;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bg,
        title: Text(l.profileDeletePhoto,
            style: TextStyle(color: c.textDark, fontFamily: 'CormorantGaramond')),
        content: Text(l.profileDeletePhotoConfirm,
            style: TextStyle(color: c.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.profileDeleteCancel,
                style: TextStyle(color: c.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.profileDeleteConfirm,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.deletePhoto(photoId);
      await _loadPhotos();
    } catch (e) {
      debugPrint('deletePhoto error: $e');
    }
  }

  Future<void> _logout() async {
    await AppStorage.clearUser();
    if (mounted) context.go('/login');
  }

  String get _shortId => _userId != null && _userId!.length > 8
      ? '${_userId!.substring(0, 8)}…'
      : (_userId ?? '—');

  void _openOverflowMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileOverflowSheet(
        shortId:   _shortId,
        onSignOut: _logout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c          = context.aura;
    final l          = context.l10n;
    // CONTRACT_profile_summary_v1.md §5 — completion_percent ВСЕГДА
    // присутствует в ответе (синхронный расчёт), 0 до первой загрузки —
    // тот же fallback-паттерн, что был у прежнего '0%'.
    final completion = '${_summary?.completionPercent ?? 0}%';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor:  c.bg,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon:      Icon(Icons.arrow_back_ios_new_rounded, color: c.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l.profileTitle,
          style: TextStyle(
            fontFamily:    'CormorantGaramond',
            color:         c.textDark,
            fontSize:      20,
            fontWeight:    FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l.profileMoreOptions,
            icon:    Icon(Icons.more_horiz_rounded, color: c.textDark),
            onPressed: _openOverflowMenu,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color:     c.accent,
          onRefresh: () async {
            await _loadPhotos();
            await _loadProfile();
            await _loadSummary();
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ProfileHeader(name: _name, completion: completion, photos: _photos),
              const SizedBox(height: 20),
              ProfileSummaryCard(summary: _summary, loading: _loadingSummary),
              const SizedBox(height: 24),
              ProfileTabs(
                active:    _activeTab,
                onChanged: (tab) => setState(() => _activeTab = tab),
              ),
              const SizedBox(height: 20),
              if (_activeTab == ProfileTab.beauty)
                BeautyProfileSection(profile: _profile, loading: _loadingProfile)
              else
                SkinJournalSection(
                  photos:   _photos,
                  loading:  _loadingPhotos,
                  onDelete: _deletePhoto,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
