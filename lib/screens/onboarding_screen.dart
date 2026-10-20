import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _languages = [
    ('ar', 'العربية', true),
    ('en', 'English', false),
    ('ur', 'اردو', true),
  ];

  void _start(BuildContext context) {
    AppSettings.instance.completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = AppSettings.instance.language;

    return Scaffold(
      backgroundColor: AppColors.green,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PositionedDirectional(
            start: -65,
            top: -150,
            child: Opacity(
              opacity: 0.22,
              child: StarMotif(
                  size: 520, color: AppColors.sand, strokeWidth: 5, withInner: true),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('الأثر',
                              textDirection: TextDirection.rtl,
                              style: AppText.arabic(
                                  size: 84,
                                  weight: FontWeight.w700,
                                  color: AppColors.sand,
                                  height: 1.2)),
                          Text('Alathar',
                              style: AppText.ui(
                                  size: 22,
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('tagline'),
                            textAlign: TextAlign.center,
                            style: AppText.ui(
                                size: 16, color: const Color(0xFFD5E1DB), height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.ground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Feature(Icons.verified_user_outlined, context.tr('feat_source')),
                      const SizedBox(height: 12),
                      _Feature(Icons.notifications_none, context.tr('feat_reminders')),
                      const SizedBox(height: 12),
                      _Feature(Icons.wifi_off_outlined, context.tr('feat_offline')),
                      const SizedBox(height: 20),
                      Text(context.tr('choose_language'),
                          style: AppText.ui(
                              size: 13, weight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final (code, label, isArabicScript) in _languages) ...[
                            Expanded(
                              child: _LangButton(
                                label: label,
                                arabicScript: isArabicScript,
                                selected: current == code,
                                // Switches the whole app immediately (direction too).
                                onTap: () => AppSettings.instance.setLanguage(code),
                              ),
                            ),
                            if (code != _languages.last.$1) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: () => _start(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(context.tr('get_started'),
                              style: AppText.ui(
                                  size: 16,
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconTile(
          size: 32,
          radius: 10,
          child: Icon(icon, size: 18, color: AppColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppText.ui(size: 14))),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool arabicScript;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.arabicScript,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.ink;
    final weight = selected ? FontWeight.w700 : FontWeight.w500;
    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        radius: 14,
        padding: EdgeInsets.zero,
        borderColor: selected ? AppColors.green : AppColors.line,
        borderWidth: selected ? 2 : 1,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: arabicScript
                  ? AppText.arabic(size: 17, weight: weight, color: color, height: 1.2)
                  : AppText.ui(size: 15, weight: weight, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
