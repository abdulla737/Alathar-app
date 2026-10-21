import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/quran.dart';
import '../data/content_store.dart';
import '../data/content_sync.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'saved_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _reminderKeys = ['hadith', 'quran', 'morning', 'evening', 'friday', 'nudges'];

  static const _languages = {'ar': 'العربية', 'en': 'English', 'ur': 'اردو'};

  static const _translations = ['English', 'اردو', 'Français', 'Bahasa Indonesia'];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(context.tr('settings_title'), style: AppText.title()),
            const SizedBox(height: 14),

            Text(context.tr('my_data'), style: AppText.overline()),
            const SizedBox(height: 8),
            _Group(
              children: [
                ListenableBuilder(
                  listenable: UserStore.instance,
                  builder: (context, _) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.bookmark_border, color: AppColors.green),
                    title: Text(context.tr('saved_title'),
                        style: AppText.ui(size: 15, weight: FontWeight.w600)),
                    subtitle: Text(context.tr('stored_on_device'),
                        style: AppText.ui(size: 12, color: AppColors.muted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            context.tr('saved_count',
                                {'n': UserStore.instance.favoriteCount}),
                            style: AppText.ui(size: 13, color: AppColors.muted)),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavedScreen()),
                    ),
                  ),
                ),
                const _ContentUpdateRow(),
              ],
            ),
            const SizedBox(height: 18),

            Text(context.tr('reminders'), style: AppText.overline()),
            const SizedBox(height: 8),
            _Group(
              children: [
                for (final key in _reminderKeys)
                  SwitchListTile(
                    value: settings.reminders[key] ?? false,
                    onChanged: (_) => settings.toggleReminder(key),
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.green,
                    inactiveTrackColor: AppColors.switchOff,
                    inactiveThumbColor: Colors.white,
                    trackOutlineColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(context.tr('rem_$key'),
                        style: AppText.ui(size: 15, weight: FontWeight.w600)),
                    subtitle: Text(context.tr('rem_${key}_sub'),
                        style: AppText.ui(size: 12, color: AppColors.muted)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(context.tr('reminders_note'),
                  style: AppText.ui(size: 12, color: AppColors.muted, height: 1.5)),
            ),
            const SizedBox(height: 18),

            // «الورد اليومي»: daily goals; the Today cards measure progress
            // against these.
            Text(context.tr('wird_section'), style: AppText.overline()),
            const SizedBox(height: 8),
            _Group(
              children: [
                _StepperRow(
                  label: context.tr('wird_quran_pages'),
                  value: settings.quranPagesPerDay,
                  min: 1,
                  max: AppSettings.maxQuranPagesPerDay,
                  onChanged: settings.setQuranPagesPerDay,
                ),
                const _QuranRangeRows(),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(context.tr('wird_note'),
                  style: AppText.ui(size: 12, color: AppColors.muted, height: 1.5)),
            ),
            const SizedBox(height: 18),

            Text(context.tr('reading'), style: AppText.overline()),
            const SizedBox(height: 8),
            _Group(
              children: [
                _DropdownRow(
                  label: context.tr('app_language'),
                  value: settings.language,
                  items: _languages,
                  onChanged: settings.setLanguage,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(context.tr('arabic_size'),
                                style: AppText.ui(size: 15, weight: FontWeight.w600)),
                          ),
                          Text('بِسْمِ اللهِ',
                              textDirection: TextDirection.rtl,
                              style: AppText.arabic(
                                  size: settings.arabicSize,
                                  color: AppColors.green,
                                  height: 1.2)),
                        ],
                      ),
                      Slider(
                        value: settings.arabicSize,
                        min: AppSettings.minArabicSize,
                        max: AppSettings.maxArabicSize,
                        divisions: 13,
                        label: settings.arabicSize.round().toString(),
                        activeColor: AppColors.green,
                        inactiveColor: AppColors.greenSoft,
                        onChanged: (v) => settings.setArabicSize(v),
                      ),
                    ],
                  ),
                ),
                // Translation language only matters when the app isn't in Arabic.
                if (!S.isArabic)
                  _DropdownRow(
                    label: context.tr('translation'),
                    value: settings.translation,
                    items: {for (final t in _translations) t: t},
                    onChanged: settings.setTranslation,
                  ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(context.tr('sources'),
                      style: AppText.ui(size: 15, weight: FontWeight.w600)),
                  subtitle: Text(context.tr('sources_sub'),
                      style: AppText.ui(size: 12, color: AppColors.muted)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => _showCredits(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCredits(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('sources'),
                style: AppText.ui(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(context.tr('credits_body'),
                style: AppText.ui(size: 14, height: 1.8, color: AppColors.body)),
          ],
        ),
      ),
    );
  }
}

/// Shows the content version on the phone and checks Supabase for updates.
class _ContentUpdateRow extends StatefulWidget {
  const _ContentUpdateRow();

  @override
  State<_ContentUpdateRow> createState() => _ContentUpdateRowState();
}

class _ContentUpdateRowState extends State<_ContentUpdateRow> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await ContentSync.run();
    if (!mounted) return;
    setState(() => _checking = false);
    final key = switch (result) {
      SyncResult.updated => 'updated_to',
      SyncResult.upToDate => 'up_to_date',
      SyncResult.offline => 'update_failed',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.tr(key, {'n': ContentStore.instance.version}),
          style: AppText.ui(size: 14, color: Colors.white)),
      backgroundColor: AppColors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContentStore.instance,
      builder: (context, _) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.green),
        title: Text(context.tr('content_version', {'n': ContentStore.instance.version}),
            style: AppText.ui(size: 15, weight: FontWeight.w600)),
        subtitle: Text(
            context.tr('hadith_count', {'n': ContentStore.instance.allHadith.length}),
            style: AppText.ui(size: 12, color: AppColors.muted)),
        trailing: _checking
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green))
            : TextButton(
                onPressed: _check,
                child: Text(context.tr('check_updates'),
                    style: AppText.ui(
                        size: 13, weight: FontWeight.w600, color: AppColors.green)),
              ),
      ),
    );
  }
}

/// «أحاديث في اليوم   −  ٣  +»
class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _StepperRow(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap) => IconButton.outlined(
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            side: BorderSide(color: onTap == null ? AppColors.line : AppColors.green),
            foregroundColor: AppColors.green,
          ),
          icon: Icon(icon, size: 18),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.ui(size: 15, weight: FontWeight.w600)),
          ),
          button(Icons.remove, value > min ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 40,
            child: Text(S.isArabic ? arabicDigits(value) : '$value',
                textAlign: TextAlign.center,
                style: AppText.ui(size: 17, weight: FontWeight.w700, color: AppColors.green)),
          ),
          button(Icons.add, value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

/// «من سورة» / «إلى سورة» for the daily Qur'an reading.
class _QuranRangeRows extends StatelessWidget {
  const _QuranRangeRows();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final q = QuranData.instance;
    return FutureBuilder<void>(
      future: q.ensureLoaded(),
      builder: (context, _) {
        if (!q.isLoaded) return const SizedBox(height: 0);
        String label(Surah s) =>
            '${S.isArabic ? arabicDigits(s.number) : s.number}. ${S.isArabic ? s.name : s.translit}';
        Widget row(String title, int value, int min, ValueChanged<int> onChanged) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppText.ui(size: 15, weight: FontWeight.w600)),
                  ),
                  DropdownButton<int>(
                    value: value,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 420,
                    style: AppText.ui(size: 14),
                    items: [
                      for (final s in q.surahs)
                        if (s.number >= min)
                          DropdownMenuItem(value: s.number, child: Text(label(s))),
                    ],
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ],
              ),
            );
        return Column(
          children: [
            row(context.tr('wird_from_surah'), settings.quranFromSurah, 1,
                (v) => settings.setQuranRange(v, v > settings.quranToSurah ? v : settings.quranToSurah)),
            row(context.tr('wird_to_surah'), settings.quranToSurah, settings.quranFromSurah,
                (v) => settings.setQuranRange(settings.quranFromSurah, v)),
          ],
        );
      },
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items; // value -> display text
  final ValueChanged<String> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.ui(size: 15, weight: FontWeight.w600)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            style: AppText.ui(size: 14),
            items: [
              for (final e in items.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// White rounded group with dividers between rows.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }
}
