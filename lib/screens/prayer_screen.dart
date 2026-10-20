import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/prayer_places.dart';
import '../data/prayer_store.dart';
import '../data/prayer_times.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prayer_widgets.dart';

/// «مواقيت الصلاة»: live clock, countdown, today's six times, the place
/// and the calculation settings.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final store = PrayerStore.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(context.tr('prayer_title'),
            style: AppText.ui(size: 16, weight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, AppSettings.instance]),
        builder: (context, _) {
          final now = DateTime.now();
          final today = store.dayOf(now);
          final next = store.next(now);
          final current = store.current(now);
          final loc = MaterialLocalizations.of(context);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              // Live clock + countdown
              AppCard(
                color: AppColors.night,
                borderWidth: 0,
                radius: 24,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  children: [
                    Text(loc.formatFullDate(now),
                        textAlign: TextAlign.center,
                        style: AppText.ui(size: 13, color: AppColors.onNightMuted)),
                    const SizedBox(height: 4),
                    Text('${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}',
                        textDirection: TextDirection.ltr,
                        style: AppText.ui(
                                size: 40, weight: FontWeight.w700, color: Colors.white, height: 1.15)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    if (next != null) ...[
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: '${prayerName(context, next.$1, next.$2)} ${context.tr('prayer_in')} '),
                          TextSpan(
                            text: formatCountdown(next.$2.difference(now)),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()]),
                          ),
                        ]),
                        textAlign: TextAlign.center,
                        style: AppText.ui(size: 15, color: AppColors.nightGold),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Place
              AppCard(
                radius: 18,
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                onTap: () => showPrayerLocationSheet(context),
                child: Row(
                  children: [
                    Icon(store.source == 'gps' ? Icons.my_location : Icons.place_outlined,
                        color: AppColors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          store.hasLocation ? placeLabel(context) : context.tr('prayer_set_body'),
                          style: AppText.ui(size: 15, weight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => showPrayerLocationSheet(context),
                      child: Text(context.tr('prayer_change'),
                          style: AppText.ui(size: 14, weight: FontWeight.w600, color: AppColors.green)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Today's times
              if (store.hasLocation && today == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(context.tr('prayer_unavailable'),
                      textAlign: TextAlign.center,
                      style: AppText.ui(size: 14, color: AppColors.muted)),
                ),
              if (today != null)
                AppCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final p in Prayer.values)
                        _TimeRow(
                          name: prayerName(context, p, now),
                          time: formatPrayerTime(context, today[p]),
                          isNext: next != null && next.$1 == p && _sameDay(next.$2, now),
                          isNow: current == p,
                          minor: p == Prayer.sunrise,
                          last: p == Prayer.isha,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),

              // Settings
              if (store.hasLocation) ...[
                _Label(context.tr('prayer_method')),
                _Dropdown(
                  value: store.methodKey,
                  items: {
                    'auto': context.tr('prayer_auto', {'m': methodLabel(context, store.autoMethod)}),
                    for (final m in PrayerMethod.values) m.name: methodLabel(context, m),
                  },
                  onChanged: store.setMethod,
                ),
                const SizedBox(height: 12),
                _Label(context.tr('prayer_asr_method')),
                _Dropdown(
                  value: store.asrKey,
                  items: {
                    'auto': context.tr('prayer_auto', {
                      'm': context.tr(hanafiForCountry(store.country) ? 'asr_hanafi' : 'asr_standard')
                    }),
                    'standard': context.tr('asr_standard'),
                    'hanafi': context.tr('asr_hanafi'),
                  },
                  onChanged: store.setAsr,
                ),
                const SizedBox(height: 14),
                Text(context.tr('prayer_note'),
                    style: AppText.ui(size: 12, color: AppColors.muted, height: 1.6)),
              ],
            ],
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TimeRow extends StatelessWidget {
  final String name;
  final String time;
  final bool isNext;
  final bool isNow;
  final bool minor;
  final bool last;
  const _TimeRow({
    required this.name,
    required this.time,
    required this.isNext,
    required this.isNow,
    required this.minor,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final color = isNext ? AppColors.green : (minor ? AppColors.muted : AppColors.ink);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: isNext ? AppColors.greenSoft : null,
        borderRadius: BorderRadius.circular(14),
        border: isNext || last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(name,
                    style: AppText.ui(
                        size: minor ? 14 : 16,
                        weight: isNext ? FontWeight.w700 : FontWeight.w500,
                        color: color)),
                if (isNow) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sandSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(context.tr('prayer_now'),
                        style: AppText.ui(size: 11, weight: FontWeight.w600, color: AppColors.goldDark)),
                  ),
                ],
              ],
            ),
          ),
          Text(time,
              style: AppText.ui(
                  size: minor ? 14 : 16,
                  weight: isNext ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
        child: Text(text, style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.muted)),
      );
}

class _Dropdown extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  const _Dropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.containsKey(value) ? value : items.keys.first,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: [
            for (final e in items.entries)
              DropdownMenuItem(
                value: e.key,
                child: Text(e.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.ui(size: 14, weight: FontWeight.w500)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
