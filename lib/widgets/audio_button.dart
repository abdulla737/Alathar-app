import 'package:flutter/material.dart';

import '../config/audio_config.dart';
import '../data/audio_service.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Tells the user why audio couldn't play.
void showAudioError(BuildContext context, AudioError e) {
  final key = switch (e) {
    AudioError.offline => 'audio_offline',
    AudioError.noArabicVoice => 'audio_no_voice',
    AudioError.nothingToPlay => 'audio_none',
    AudioError.none => null,
  };
  if (key == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.tr(key))));
}

/// 🔊 / ■ button for a hadith, verse or athar. Hidden when there is
/// nothing to play (e.g. a verse without a Qur'an reference).
class HadithAudioButton extends StatelessWidget {
  final Hadith hadith;
  final Color color;
  final double size;
  const HadithAudioButton(
      {super.key, required this.hadith, this.color = AppColors.ink, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (!AudioConfig.enabled || !AudioService.canPlayHadith(hadith)) {
      return const SizedBox.shrink();
    }
    final audio = AudioService.instance;
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final playing = audio.isPlaying(AudioService.hadithKey(hadith));
        return IconButton(
          tooltip: context.tr(playing ? 'stop_audio' : 'listen'),
          onPressed: () async {
            final e = await audio.toggleHadith(hadith);
            if (context.mounted) showAudioError(context, e);
          },
          icon: Icon(playing ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
              color: color, size: size),
        );
      },
    );
  }
}
