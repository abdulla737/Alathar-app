import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Asks for the user's name (kept only on the phone). Empty clears it.
Future<void> showNameDialog(BuildContext context) async {
  final settings = AppSettings.instance;
  final controller = TextEditingController(text: settings.userName);
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('name_title'), style: AppText.ui(size: 17, weight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ctx.tr('name_body'), style: AppText.ui(size: 13, height: 1.5, color: AppColors.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
            style: AppText.ui(size: 16),
            decoration: InputDecoration(
              hintText: ctx.tr('name_hint'),
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(ctx.tr('book_cancel'), style: AppText.ui(size: 14, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: Text(ctx.tr('name_save'),
              style: AppText.ui(size: 14, weight: FontWeight.w700, color: AppColors.green)),
        ),
      ],
    ),
  );
  if (name != null) settings.setUserName(name);
}

/// «السلام عليكم عبدالله» — the greeting with the name when there is one.
String greetingText(BuildContext context) {
  final name = AppSettings.instance.userName;
  if (name.isEmpty) return context.tr('greeting');
  return context.tr('greeting_name', {'name': name});
}
