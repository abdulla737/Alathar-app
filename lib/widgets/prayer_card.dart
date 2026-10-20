import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/prayer_store.dart';
import '../data/prayer_times.dart';
import '../data/weather.dart';
import '../l10n/strings.dart';
import '../screens/prayer_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'prayer_widgets.dart';
import 'weather_sky.dart';

/// Today page: the next prayer with a live countdown. Tap → full page.
/// Without a location it invites the user to set one.
class PrayerCard extends StatefulWidget {
  const PrayerCard({super.key});

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
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

  void _openPage() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const PrayerScreen()));

  @override
  Widget build(BuildContext context) {
    final store = PrayerStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.instance, WeatherStore.instance]),
      builder: (context, _) {
        if (!store.hasLocation) return _setup(context, store);
        final now = DateTime.now();
        final next = store.next(now);
        if (next == null) {
          return _shell(
            onTap: _openPage,
            child: Text(context.tr('prayer_unavailable'),
                style: AppText.ui(size: 14, color: AppColors.onNightBody)),
          );
        }
        final (prayer, time) = next;
        final today = store.dayOf(now);
        return _shell(
          onTap: _openPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(context.tr('prayer_next'),
                        style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.nightGold)),
                  ),
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.onNightMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(placeLabel(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.ui(size: 12, color: AppColors.onNightMuted)),
                  ),
                  if (WeatherStore.instance.now case final w?) ...[
                    const SizedBox(width: 8),
                    _WeatherChip(weather: w),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prayerName(context, prayer, time),
                            style: AppText.ui(
                                size: 24, weight: FontWeight.w700, color: Colors.white, height: 1.2)),
                        Text(formatPrayerTime(context, time),
                            style: AppText.ui(size: 15, color: AppColors.onNightBody)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(context.tr('prayer_in'),
                          style: AppText.ui(size: 12, color: AppColors.onNightMuted)),
                      Text(formatCountdown(time.difference(now)),
                          textDirection: TextDirection.ltr,
                          style: AppText.ui(
                              size: 24, weight: FontWeight.w700, color: Colors.white, height: 1.2)
                              .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    ],
                  ),
                ],
              ),
              if (today != null) ...[
                const SizedBox(height: 12),
                // The five prayers; the next one highlighted.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final p in Prayer.values)
                      if (p != Prayer.sunrise)
                        Text(prayerName(context, p, now),
                            style: AppText.ui(
                                size: 12,
                                weight: p == prayer ? FontWeight.w700 : FontWeight.w500,
                                color: p == prayer ? AppColors.nightGold : AppColors.onNightMuted)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr('prayer_all'),
                        style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.nightGold)),
                    const SizedBox(width: 2),
                    Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                        size: 18, color: AppColors.nightGold),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Night-blue card with the live weather sky behind the text. A little
  /// darker in rain and at night.
  Widget _shell({required Widget child, VoidCallback? onTap}) {
    final w = WeatherStore.instance.now;
    var bg = AppColors.night;
    if (w != null && !w.isDay) {
      bg = Color.lerp(AppColors.night, Colors.black, 0.3)!;
    } else if (w?.kind == WeatherKind.rain) {
      bg = Color.lerp(AppColors.night, Colors.black, 0.18)!;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (w != null)
              Positioned.fill(child: WeatherSky(kind: w.kind, isDay: w.isDay)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _setup(BuildContext context, PrayerStore store) {
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.night, size: 20),
              const SizedBox(width: 8),
              Text(context.tr('prayer_set_title'),
                  style: AppText.ui(size: 15, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(context.tr('prayer_set_body'),
              style: AppText.ui(size: 13, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: store.locating ? null : () => useMyLocation(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.night,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: store.locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(context.tr(store.locating ? 'prayer_locating' : 'prayer_use_gps'),
                      style: AppText.ui(size: 14, weight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showPrayerLocationSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.night,
                    minimumSize: const Size(0, 46),
                    side: const BorderSide(color: AppColors.night),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(context.tr('prayer_choose_city'),
                      style: AppText.ui(size: 14, weight: FontWeight.w600, color: AppColors.night)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «ممطر · 24°» chip on the prayer card.
class _WeatherChip extends StatelessWidget {
  final WeatherNow weather;
  const _WeatherChip({required this.weather});

  @override
  Widget build(BuildContext context) {
    final (icon, key) = switch (weather.kind) {
      WeatherKind.rain => (Icons.water_drop_outlined, 'wx_rain'),
      WeatherKind.cloudy => (Icons.cloud_outlined, 'wx_cloudy'),
      WeatherKind.clear => (weather.isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined, 'wx_clear'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.onNightBody),
          const SizedBox(width: 4),
          Text('${context.tr(key)} · ${weather.temperature.round()}°',
              style: AppText.ui(size: 11, weight: FontWeight.w600, color: AppColors.onNightBody)),
        ],
      ),
    );
  }
}
