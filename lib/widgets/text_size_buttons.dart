import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// The [A−] [A+] pair used to make reading text smaller or bigger (hadith
/// page, «الشرح» and athkar). A button is greyed out when its callback is
/// null (the size has reached its limit).
class TextSizeButtons extends StatelessWidget {
  final VoidCallback? onSmaller;
  final VoidCallback? onBigger;
  const TextSizeButtons({super.key, this.onSmaller, this.onBigger});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SizeButton(
            label: 'A−', small: true, tooltip: context.tr('font_smaller'), onPressed: onSmaller),
        const SizedBox(width: 6),
        _SizeButton(label: 'A+', tooltip: context.tr('font_bigger'), onPressed: onBigger),
      ],
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool small;
  final VoidCallback? onPressed;
  const _SizeButton(
      {required this.label, required this.tooltip, this.small = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 38),
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.green,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: enabled ? AppColors.green : AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            textDirection: TextDirection.ltr,
            style: AppText.ui(
                size: small ? 13 : 17,
                weight: FontWeight.w700,
                color: enabled ? AppColors.green : AppColors.muted)),
      ),
    );
  }
}
