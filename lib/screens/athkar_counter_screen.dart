import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/audio_config.dart';
import '../data/app_settings.dart';
import '../data/audio_service.dart';
import '../data/sample_data.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_button.dart';
import '../widgets/common.dart';
import '../widgets/text_size_buttons.dart';

/// Reads a list of athkar one by one with a tap counter.
/// Tap the circle to count; when a dhikr reaches its count, the screen
/// moves on to the next one automatically.
class AthkarCounterScreen extends StatefulWidget {
  final String title;
  final List<Dhikr> athkar;

  /// Called once when every dhikr in the list has reached its count.
  final VoidCallback? onFinished;

  /// Saves the counts under this key as you go; opening again with the
  /// same key resumes at the first dhikr not yet finished.
  final String? progressKey;

  const AthkarCounterScreen(
      {super.key,
      required this.title,
      required this.athkar,
      this.onFinished,
      this.progressKey});

  @override
  State<AthkarCounterScreen> createState() => _AthkarCounterScreenState();
}

class _AthkarCounterScreenState extends State<AthkarCounterScreen> {
  late final List<int> _counts = _savedCounts();
  // Resume at the first dhikr not finished yet.
  late int _index = () {
    final i = List.generate(widget.athkar.length, (i) => i)
        .indexWhere((i) => _counts[i] < widget.athkar[i].count);
    return i < 0 ? widget.athkar.length - 1 : i;
  }();
  late bool _reported = _completed == widget.athkar.length;

  List<int> _savedCounts() {
    final key = widget.progressKey;
    final saved = key == null ? null : UserStore.instance.athkarProgress(key);
    if (saved != null && saved.length == widget.athkar.length) return List.of(saved);
    return List.filled(widget.athkar.length, 0);
  }

  void _save() {
    final key = widget.progressKey;
    if (key != null) UserStore.instance.setAthkarProgress(key, _counts);
  }

  Dhikr get _current => widget.athkar[_index];
  int get _completed => List.generate(widget.athkar.length, (i) => i)
      .where((i) => _counts[i] >= widget.athkar[i].count)
      .length;
  bool get _currentDone => _counts[_index] >= _current.count;

  void _tap() {
    if (_currentDone) return;
    setState(() => _counts[_index]++);
    _save();
    if (_currentDone) {
      HapticFeedback.mediumImpact();
      if (!_reported && _completed == widget.athkar.length) {
        _reported = true;
        widget.onFinished?.call();
      }
      if (_index < widget.athkar.length - 1) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          AudioService.instance.stop();
          setState(() => _index++);
        });
      }
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _reset() {
    setState(() => _counts[_index] = 0);
    _save();
  }

  void _next() {
    if (_index < widget.athkar.length - 1) {
      AudioService.instance.stop();
      setState(() => _index++);
    }
  }

  /// 🔊 plays the dhikr (al-Husary for Qur'an, otherwise the recording or
  /// the phone's Arabic voice). When it finishes, it counts one repetition.
  Future<void> _listen() async {
    final e = await AudioService.instance.toggleDhikr(_current, onDone: () {
      if (mounted) _tap();
    });
    if (mounted) showAudioError(context, e);
  }

  @override
  void dispose() {
    AudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _current;
    final count = _counts[_index];
    final isLast = _index == widget.athkar.length - 1;
    final arabicUi = S.isArabic;
    final settings = AppSettings.instance;
    final z = settings.athkarScale; // A− / A+ zoom
    void zoom(double by) => setState(() => settings.setAthkarScale(z + by));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: close + session progress
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.tr('close'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(widget.title,
                                  style: AppText.ui(size: 13, weight: FontWeight.w600)),
                            ),
                            Text(
                                context.tr('of_n',
                                    {'a': _completed, 'b': widget.athkar.length}),
                                style: AppText.ui(size: 13, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ProgressLine(
                          value: _completed / widget.athkar.length,
                          track: AppColors.line,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text size: A− / A+
                  TextSizeButtons(
                    onSmaller: z > AppSettings.minAthkarScale ? () => zoom(-0.1) : null,
                    onBigger: z < AppSettings.maxAthkarScale ? () => zoom(0.1) : null,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                children: [
                  // Dhikr card
                  AppCard(
                    radius: 24,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ArabicText(d.arabic,
                            align: TextAlign.center,
                            style: AppText.arabic(
                                size: z *
                                    (d.arabic.length > 250
                                        ? 22
                                        : d.arabic.length > 40
                                            ? 26
                                            : 34),
                                height: 1.7)),
                        // Transliteration and translation only for non-Arabic users.
                        if (!arabicUi && d.transliteration.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(d.transliteration,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: AppText.ui(
                                  size: 14 * z,
                                  color: AppColors.muted,
                                  style: FontStyle.italic)),
                        ],
                        if (!arabicUi && d.translation.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(d.translation,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: AppText.ui(size: 16 * z, weight: FontWeight.w500)),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.sandSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                      text: context.tr('virtue'),
                                      style: AppText.ui(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: AppColors.brown)),
                                  TextSpan(
                                      text: d.virtue.v,
                                      style: AppText.ui(
                                          size: 13,
                                          height: 1.6,
                                          color: AppColors.brown)),
                                ]),
                              ),
                              const SizedBox(height: 6),
                              Text(d.source.v,
                                  style: AppText.ui(
                                      size: 12,
                                      weight: FontWeight.w600,
                                      color: AppColors.goldDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tap counter
                  Center(
                    child: Semantics(
                      button: true,
                      label: context.tr('count_label', {'a': count, 'b': d.count}),
                      child: GestureDetector(
                        onTap: _tap,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x1F1E4A3D),
                                  blurRadius: 30,
                                  offset: Offset(0, 10)),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _RingPainter(count / d.count),
                            child: Center(
                              child: _currentDone
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check,
                                            size: 48, color: AppColors.green),
                                        Text(context.tr('completed'),
                                            style: AppText.ui(
                                                size: 16,
                                                weight: FontWeight.w700,
                                                color: AppColors.green)),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$count',
                                            style: AppText.ui(
                                                size: 56,
                                                weight: FontWeight.w700,
                                                color: AppColors.green,
                                                height: 1.1)),
                                        const SizedBox(height: 4),
                                        Text(context.tr('of_tap', {'b': d.count}),
                                            style: AppText.ui(
                                                size: 14, color: AppColors.muted)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(context.tr('tap_hint'),
                      textAlign: TextAlign.center,
                      style: AppText.ui(size: 12, color: AppColors.muted)),
                ],
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(context.tr('reset'),
                          style: AppText.ui(size: 15, weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (AudioConfig.enabled) ...[
                  ListenableBuilder(
                    listenable: AudioService.instance,
                    builder: (context, _) {
                      final playing = AudioService.instance
                          .isPlaying(AudioService.dhikrKey(d));
                      return IconButton.outlined(
                    tooltip: context.tr(playing ? 'stop_audio' : 'play_audio'),
                    onPressed: _listen,
                    style: IconButton.styleFrom(
                      fixedSize: const Size(52, 52),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(
                        playing ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                        color: playing ? AppColors.green : AppColors.ink),
                  );
                    },
                  ),
                  const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            isLast ? () => Navigator.of(context).maybePop() : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(context.tr(isLast ? 'finish' : 'next_dhikr'),
                            style: AppText.ui(
                                size: 15,
                                weight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2 - 6;
    final track = Paint()
      ..color = AppColors.greenSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2,
          2 * math.pi * p, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

