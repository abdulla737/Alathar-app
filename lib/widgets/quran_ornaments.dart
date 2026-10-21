import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colours for the surah title banner and the verse medallions.
class OrnamentPalette {
  final Color band; // arabesque panels
  final Color line; // outlines
  final Color light; // centre panel
  final Color text; // title and verse number
  const OrnamentPalette(this.band, this.line, this.light, this.text);

  static const all = [
    OrnamentPalette(Color(0xFF1E4A3D), Color(0xFFB88A2E), Color(0xFFE4EFE7), Color(0xFF1E4A3D)), // green
    OrnamentPalette(Color(0xFFC9A97A), Color(0xFF8C6A3A), Color(0xFFFBF0DA), Color(0xFF6E4B12)), // sand
    OrnamentPalette(Color(0xFF7A2E2A), Color(0xFF4E1C19), Color(0xFFEADCD5), Color(0xFF5A201C)), // maroon
    OrnamentPalette(Color(0xFF24489A), Color(0xFF162E66), Color(0xFFDCE8FB), Color(0xFF1A3570)), // blue
    OrnamentPalette(Color(0xFF9C8AD6), Color(0xFF6B58A8), Color(0xFFFCE3EE), Color(0xFF4E3D8A)), // lavender
  ];

  static OrnamentPalette of(int index) => all[index.clamp(0, all.length - 1)];
}

/// Builds a [Path] from SVG path data using absolute M, L, H, V, C and Z,
/// scaled by [s] and moved by [dx], [dy].
Path svgPath(String d, {double s = 1, double dx = 0, double dy = 0}) {
  final path = Path();
  final tokens = RegExp(r'[MLHVCZ]|-?\d*\.?\d+').allMatches(d).map((m) => m[0]!).toList();
  var i = 0;
  var cmd = 'M';
  var x = 0.0, y = 0.0;
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final t = tokens[i];
    if (RegExp(r'^[MLHVCZ]$').hasMatch(t)) {
      cmd = t;
      i++;
      if (cmd == 'Z') {
        path.close();
        continue;
      }
    }
    switch (cmd) {
      case 'M':
        x = n();
        y = n();
        path.moveTo(dx + x * s, dy + y * s);
        cmd = 'L';
      case 'L':
        x = n();
        y = n();
        path.lineTo(dx + x * s, dy + y * s);
      case 'H':
        x = n();
        path.lineTo(dx + x * s, dy + y * s);
      case 'V':
        y = n();
        path.lineTo(dx + x * s, dy + y * s);
      case 'C':
        final x1 = n(), y1 = n(), x2 = n(), y2 = n();
        x = n();
        y = n();
        path.cubicTo(dx + x1 * s, dy + y1 * s, dx + x2 * s, dy + y2 * s, dx + x * s, dy + y * s);
      default:
        i++;
    }
  }
  return path;
}

// ------------------------------------------------------------ Surah banner

/// «سُورَةُ الكَهْفِ» in an arabesque banner (two scrollwork panels and a
/// pointed centre panel), as at the start of each surah in the mushaf.
class SurahBanner extends StatelessWidget {
  final String title;
  final OrnamentPalette palette;
  final double fontSize;
  const SurahBanner({super.key, required this.title, required this.palette, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 600 / 76,
      child: CustomPaint(
        painter: _BannerPainter(palette),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: fontSize,
                      height: 1.5,
                      color: palette.text)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  final OrnamentPalette p;
  _BannerPainter(this.p);

  static const _centre =
      'M150 38 C166 38 172 12 196 10 H404 C428 12 434 38 450 38 C434 38 428 64 404 66 H196 C172 64 166 38 150 38 Z';
  static const _centreInner =
      'M160 38 C174 38 179 17 199 15 H401 C421 17 426 38 440 38 C426 38 421 59 401 61 H199 C179 59 174 38 160 38 Z';
  static const _scrolls = [
    'M75 34 C60 34 52 22 40 22 C28 22 24 32 30 37 C35 41 41 36 38 31',
    'M75 34 C60 34 52 46 40 46 C28 46 24 36 30 31 C35 27 41 32 38 37',
    'M75 34 C90 34 98 22 110 22 C122 22 126 32 120 37 C115 41 109 36 112 31',
    'M75 34 C90 34 98 46 110 46 C122 46 126 36 120 31 C115 27 109 32 112 37',
    'M18 34 C14 26 8 26 6 30 M18 34 C14 42 8 42 6 38',
    'M132 34 C136 26 142 26 144 30 M132 34 C136 42 142 42 144 38',
    'M52 14 C58 8 66 10 66 16 M98 14 C92 8 84 10 84 16 M52 54 C58 60 66 58 66 52 M98 54 C92 60 84 58 84 52',
  ];
  static const _leaves =
      'M75 22 L78 30 L75 34 L72 30 Z M75 46 L78 38 L75 34 L72 38 Z M63 34 L71 31 L75 34 L71 37 Z '
      'M87 34 L79 31 L75 34 L79 37 Z M18 34 L24 31 L28 34 L24 37 Z M132 34 L126 31 L122 34 L126 37 Z';

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 600;
    final outer = RRect.fromRectAndRadius(
        Rect.fromLTWH(2 * s, 2 * s, 596 * s, 72 * s), Radius.circular(6 * s));
    canvas.drawRRect(outer, Paint()..color = p.band);
    canvas.drawRRect(
        outer,
        Paint()
          ..color = p.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * s);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(7 * s, 7 * s, 586 * s, 62 * s), Radius.circular(4 * s)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * s);

    // Arabesque panels on both ends.
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * s
      ..strokeCap = StrokeCap.round;
    for (final ox in const [8.0, 442.0]) {
      final dx = ox * s, dy = 4 * s;
      for (final d in _scrolls) {
        canvas.drawPath(svgPath(d, s: s, dx: dx, dy: dy), white);
      }
      canvas.drawPath(svgPath(_leaves, s: s, dx: dx, dy: dy), Paint()..color = Colors.white);
      canvas.drawCircle(Offset(dx + 75 * s, dy + 34 * s), 6 * s, Paint()..color = Colors.white);
      canvas.drawCircle(
          Offset(dx + 75 * s, dy + 34 * s), 2.6 * s, Paint()..color = const Color(0xFFE3557B));
    }

    // Pointed centre panel for the title.
    canvas.drawPath(svgPath(_centre, s: s), Paint()..color = p.light);
    canvas.drawPath(
        svgPath(_centre, s: s),
        Paint()
          ..color = p.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * s);
    canvas.drawPath(
        svgPath(_centreInner, s: s),
        Paint()
          ..color = p.line.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * s);
  }

  @override
  bool shouldRepaint(_BannerPainter old) => old.p != p;
}

// ---------------------------------------------------------- Verse medallion

/// The verse number in a scalloped medallion, placed after each verse.
class AyahMedallion extends StatelessWidget {
  final String number;
  final double size;
  final OrnamentPalette palette;
  final bool saved; // bookmarked verses get a gold centre
  const AyahMedallion(
      {super.key,
      required this.number,
      required this.size,
      required this.palette,
      this.saved = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedallionPainter(palette, saved),
        child: Center(
          child: Text(number,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontSize: size * (number.length > 2 ? 0.30 : 0.36),
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: palette.text)),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  final OrnamentPalette p;
  final bool saved;
  _MedallionPainter(this.p, this.saved);

  static const _shape =
      'M20 1 C24 5 27 5 30 4 C31 9 34 11 39 12 C36 16 36 24 39 28 C34 29 31 31 30 36 '
      'C27 35 24 35 20 39 C16 35 13 35 10 36 C9 31 6 29 1 28 C4 24 4 16 1 12 '
      'C6 11 9 9 10 4 C13 5 16 5 20 1 Z';

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final shape = svgPath(_shape, s: s);
    canvas.drawPath(shape, Paint()..color = p.band);
    canvas.drawPath(
        shape,
        Paint()
          ..color = p.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * s);
    final c = Offset(20 * s, 20 * s);
    // Dotted white ring.
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s
      ..strokeCap = StrokeCap.round;
    const dots = 18;
    for (var k = 0; k < dots; k++) {
      final a = k * 2 * math.pi / dots;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 12.5 * s), a, 2 * math.pi / dots * 0.55,
          false, ring);
    }
    canvas.drawCircle(c, 10 * s, Paint()..color = saved ? const Color(0xFFF2D27A) : p.light);
    canvas.drawCircle(
        c,
        10 * s,
        Paint()
          ..color = p.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * s);
  }

  @override
  bool shouldRepaint(_MedallionPainter old) => old.p != p || old.saved != saved;
}
