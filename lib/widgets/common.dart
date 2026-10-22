import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Eight-pointed star (two overlapping squares), used as the app motif
/// and as the Tawheed icon.
class StarMotif extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final bool withInner;

  const StarMotif({
    super.key,
    this.size = 24,
    this.color = AppColors.green,
    this.strokeWidth = 1.6,
    this.withInner = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _StarPainter(color, strokeWidth, withInner),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool withInner;
  _StarPainter(this.color, this.strokeWidth, this.withInner);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final c = Offset(size.width / 2, size.height / 2);

    void square(double side) {
      final rect = Rect.fromCenter(center: c, width: side, height: side);
      canvas.drawRect(rect, paint);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.pi / 4);
      canvas.translate(-c.dx, -c.dy);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }

    square(size.width * 0.5);
    if (withInner) {
      square(size.width * 0.33);
      canvas.drawCircle(c, size.width * 0.1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// White rounded card with a hairline border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.onLongPress,
    this.color = AppColors.surface,
    this.borderColor = AppColors.line,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderWidth == 0
          ? BorderSide.none
          : BorderSide(color: borderColor, width: borderWidth),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small pill label, e.g. the grade "Sahih".
class Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final FontWeight weight;

  const Pill(
    this.label, {
    super.key,
    this.background = AppColors.greenSoft,
    this.foreground = AppColors.green,
    this.weight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppText.ui(size: 12, weight: weight, color: foreground)),
    );
  }
}

/// Thin rounded progress bar.
class ProgressLine extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final Color color;
  final Color track;

  const ProgressLine({
    super.key,
    required this.value,
    this.height = 6,
    this.color = AppColors.green,
    this.track = AppColors.greenSoft,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: track,
      ),
    );
  }
}

/// Arabic text block (always right-to-left).
class ArabicText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign align;

  const ArabicText(this.text,
      {super.key, required this.style, this.align = TextAlign.right});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textDirection: TextDirection.rtl, textAlign: align, style: style);
  }
}

/// Rounded square holding an icon.
class IconTile extends StatelessWidget {
  final Widget child;
  final double size;
  final Color color;
  final double radius;

  const IconTile({
    super.key,
    required this.child,
    this.size = 48,
    this.color = AppColors.greenSoft,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// «إعادة تعيين علامة القراءة؟» for [name]; true when confirmed. Shows
/// «تمت إعادة التعيين» after [onReset] runs.
Future<void> confirmResetReading(BuildContext context, String name, VoidCallback onReset) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('reset_mark_q'), style: AppText.ui(size: 17, weight: FontWeight.w700)),
      content: Text(ctx.tr('reset_mark_body', {'name': name}),
          style: AppText.ui(size: 14, height: 1.6)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('book_cancel'), style: AppText.ui(size: 14, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('reset_btn'),
              style: AppText.ui(size: 14, weight: FontWeight.w700, color: AppColors.green)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  onReset();
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.tr('reset_done'))));
}
