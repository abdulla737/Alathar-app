import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bar with a knob the user slides from right to left to confirm (like
/// "slide to unlock"). Once confirmed it shows [doneLabel]; tapping it then
/// calls [onUndo], if given.
class SlideToConfirm extends StatefulWidget {
  final String label;
  final String doneLabel;
  final bool confirmed;
  final VoidCallback onConfirm;
  final VoidCallback? onUndo;
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.doneLabel,
    required this.confirmed,
    required this.onConfirm,
    this.onUndo,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  static const _height = 58.0;
  static const _knob = 50.0;
  double _drag = 0; // 0..1, how far the knob has moved to the left
  late final AnimationController _back =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
        ..addListener(() => setState(() => _drag = _from * (1 - _back.value)));
  double _from = 0;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _release() {
    if (_drag > 0.8) {
      setState(() => _drag = 1);
      widget.onConfirm();
      // Reset quietly so the bar is ready again if the user undoes.
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _drag = 0);
      });
    } else {
      _from = _drag;
      _back.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.confirmed) {
      return Material(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(_height / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onUndo,
          child: SizedBox(
            height: _height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.sand, size: 24),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(widget.doneLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.ui(size: 15, weight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final travel = box.maxWidth - _knob - 8;
        // Physical right-to-left in every language.
        final right = 4 + _drag * travel;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(_height / 2),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
            ),
            child: Stack(
              children: [
                // Filled part behind the knob.
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: right + _knob + 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(_height / 2),
                    ),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: (1 - _drag * 1.6).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.keyboard_double_arrow_left,
                              color: AppColors.green, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.ui(
                                    size: 14, weight: FontWeight.w700, color: AppColors.green)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: right,
                  top: 4,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(() {
                      _back.stop();
                      _drag = (_drag - d.delta.dx / travel).clamp(0.0, 1.0);
                    }),
                    onHorizontalDragEnd: (_) => _release(),
                    child: Container(
                      width: _knob,
                      height: _knob,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.sand, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
