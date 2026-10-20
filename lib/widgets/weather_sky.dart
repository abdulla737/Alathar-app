import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/weather.dart';

/// Animated sky behind the prayer card: falling rain, drifting clouds, a
/// glowing sun, or a crescent with twinkling stars. Loops seamlessly every
/// 40 seconds. Holds still when the phone asks for reduced motion.
class WeatherSky extends StatefulWidget {
  final WeatherKind kind;
  final bool isDay;
  const WeatherSky({super.key, required this.kind, required this.isDay});

  @override
  State<WeatherSky> createState() => _WeatherSkyState();
}

class _WeatherSkyState extends State<WeatherSky> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SkyPainter(_c, widget.kind, widget.isDay),
        size: Size.infinite,
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final Animation<double> t;
  final WeatherKind kind;
  final bool isDay;
  _SkyPainter(this.t, this.kind, this.isDay) : super(repaint: t);

  // Fixed "random" layout so drops, stars and clouds stay put between frames.
  static final _rnd = math.Random(7);
  static final _drops = List.generate(
      55, (_) => (_rnd.nextDouble(), _rnd.nextDouble(), 40 + _rnd.nextInt(30), 10 + _rnd.nextDouble() * 8));
  static final _stars = List.generate(
      28, (_) => (_rnd.nextDouble(), _rnd.nextDouble() * 0.6, 8 + _rnd.nextInt(10), _rnd.nextDouble(), 0.8 + _rnd.nextDouble() * 1.1));

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value; // 0..1 over 40 s
    switch (kind) {
      case WeatherKind.rain:
        _cloud(canvas, size, y: 18, w: 110, cycles: 1, phase: 0.2, v: v, alpha: 0.20);
        _cloud(canvas, size, y: 42, w: 80, cycles: 1, phase: 0.75, v: v, alpha: 0.14);
        _rain(canvas, size, v);
      case WeatherKind.cloudy:
        _cloud(canvas, size, y: 16, w: 120, cycles: 1, phase: 0.0, v: v, alpha: 0.22);
        _cloud(canvas, size, y: 60, w: 150, cycles: 1, phase: 0.45, v: v, alpha: 0.16);
        _cloud(canvas, size, y: 120, w: 90, cycles: 2, phase: 0.7, v: v, alpha: 0.12);
        if (!isDay) _twinkle(canvas, size, v, dim: 0.35);
      case WeatherKind.clear:
        if (isDay) {
          _sun(canvas, size, v);
        } else {
          _twinkle(canvas, size, v);
          _moon(canvas, size);
        }
    }
  }

  void _rain(Canvas canvas, Size size, double v) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final (x0, y0, cycles, len) in _drops) {
      final p = (y0 + v * cycles) % 1.0;
      final y = p * (size.height + 40) - 20;
      final x = x0 * (size.width + 40) - p * 18;
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + len), paint);
    }
  }

  void _cloud(Canvas canvas, Size size,
      {required double y,
      required double w,
      required int cycles,
      required double phase,
      required double v,
      required double alpha}) {
    final span = size.width + w * 2;
    final x = ((phase + v * cycles) % 1.0) * span - w;
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    final h = w * 0.32;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y + h * 0.4, w, h), Radius.circular(h)))
      ..addOval(Rect.fromCircle(center: Offset(x + w * 0.35, y + h * 0.45), radius: h * 0.62))
      ..addOval(Rect.fromCircle(center: Offset(x + w * 0.62, y + h * 0.35), radius: h * 0.78));
    canvas.drawPath(path, paint);
  }

  void _sun(Canvas canvas, Size size, double v) {
    final c = Offset(size.width * 0.08, -size.height * 0.02);
    final pulse = 0.5 + 0.5 * math.sin(v * 2 * math.pi * 10);
    const gold = Color(0xFFFFD666);
    canvas.drawCircle(c, 92 + pulse * 10, Paint()..color = gold.withValues(alpha: 0.07));
    canvas.drawCircle(c, 70 + pulse * 6, Paint()..color = gold.withValues(alpha: 0.16));
    canvas.drawCircle(c, 50, Paint()..color = gold.withValues(alpha: 0.85));
  }

  void _twinkle(Canvas canvas, Size size, double v, {double dim = 1}) {
    for (final (x, y, cycles, phase, r) in _stars) {
      final a = (0.25 + 0.75 * (0.5 + 0.5 * math.sin((v * cycles + phase) * 2 * math.pi))) * dim;
      canvas.drawCircle(Offset(x * size.width, y * size.height), r,
          Paint()..color = Colors.white.withValues(alpha: a));
    }
  }

  void _moon(Canvas canvas, Size size) {
    // Crescent: a full disc with a second disc cut out of it.
    final c = Offset(size.width * 0.1, size.height * 0.2);
    final moon = Path()..addOval(Rect.fromCircle(center: c, radius: 18));
    final cut = Path()..addOval(Rect.fromCircle(center: c + const Offset(8, -5), radius: 16));
    canvas.drawPath(Path.combine(PathOperation.difference, moon, cut),
        Paint()..color = const Color(0xFFF6E7B8));
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.kind != kind || old.isDay != isDay;
}
