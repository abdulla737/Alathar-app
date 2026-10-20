import 'package:flutter/material.dart';

import '../data/prayer_places.dart';
import '../data/prayer_store.dart';
import '../data/prayer_times.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// "Fajr", "Dhuhr" … in the app language. Dhuhr is "Jumuah" on Fridays.
String prayerName(BuildContext context, Prayer p, [DateTime? day]) {
  if (p == Prayer.dhuhr && (day ?? DateTime.now()).weekday == DateTime.friday) {
    return context.tr('prayer_jumuah');
  }
  return context.tr('prayer_${p.name}');
}

/// Clock time in the phone's style (12/24 h) and the app language.
String formatPrayerTime(BuildContext context, DateTime t) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(t),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 01:12:45
String formatCountdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  return '${_two(d.inHours)}:${_two(d.inMinutes % 60)}:${_two(d.inSeconds % 60)}';
}

/// Name of the place for display ("Dubai", or "My location").
String placeLabel(BuildContext context) {
  final s = PrayerStore.instance;
  return s.placeName?.v ?? context.tr('prayer_my_location');
}

String methodLabel(BuildContext context, PrayerMethod m) => context.tr('m_${m.name}');

/// Asks for the phone's location and shows what to do if that fails.
Future<bool> useMyLocation(BuildContext context) async {
  final result = await PrayerStore.instance.useMyLocation();
  if (result == LocateResult.ok || !context.mounted) return result == LocateResult.ok;
  final key = switch (result) {
    LocateResult.serviceOff => 'prayer_err_service',
    LocateResult.denied => 'prayer_err_denied',
    LocateResult.deniedForever => 'prayer_err_forever',
    _ => 'prayer_err_failed',
  };
  final action = switch (result) {
    LocateResult.serviceOff => PrayerStore.openLocationSettings,
    LocateResult.deniedForever => PrayerStore.openAppSettings,
    _ => null,
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(context.tr(key)),
    duration: const Duration(seconds: 6),
    action: action == null
        ? null
        : SnackBarAction(label: context.tr('prayer_open_settings'), onPressed: action),
  ));
  return false;
}

/// Bottom sheet: "Use my location" on top, then a searchable city list.
Future<void> showPrayerLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.ground,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _LocationSheet(),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = PrayerStore.instance;
    final q = _query.trim().toLowerCase();
    final cities = prayerCities
        .where((c) =>
            q.isEmpty ||
            c.name.ar.contains(q) ||
            c.name.en.toLowerCase().contains(q) ||
            (c.name.ur ?? '').contains(q))
        .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: store.locating
                        ? null
                        : () async {
                            final ok = await useMyLocation(context);
                            if (ok && context.mounted) Navigator.of(context).maybePop();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: store.locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.my_location, size: 20),
                    label: Text(
                        context.tr(store.locating ? 'prayer_locating' : 'prayer_use_gps'),
                        style: AppText.ui(size: 15, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: context.tr('prayer_search_city'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: cities.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, i) {
                  final c = cities[i];
                  final selected = store.source == 'city' && store.cityId == c.id;
                  return ListTile(
                    title: Text(c.name.v, style: AppText.ui(size: 15, weight: FontWeight.w500)),
                    subtitle: S.isArabic
                        ? null
                        : Text(c.name.ar,
                            style: AppText.arabic(size: 13, color: AppColors.muted, height: 1.3)),
                    trailing: selected ? const Icon(Icons.check, color: AppColors.green) : null,
                    onTap: () {
                      store.setCity(c);
                      Navigator.of(context).maybePop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
