import 'package:flutter/material.dart';

import '../data/content_store.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'hadith_detail_screen.dart';

/// Hadith the user saved, newest first. Stored on the phone (UserStore).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = UserStore.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        title: Text(context.tr('saved_title'),
            style: AppText.ui(size: 18, weight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final items = [
            for (final id in store.favoriteIds)
              if (ContentStore.instance.find(id) case final h?) h,
          ];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IconTile(
                      size: 64,
                      radius: 20,
                      child: Icon(Icons.bookmark_border,
                          size: 30, color: AppColors.green),
                    ),
                    const SizedBox(height: 16),
                    Text(context.tr('saved_empty'),
                        textAlign: TextAlign.center,
                        style: AppText.ui(
                            size: 15, color: AppColors.muted, height: 1.6)),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final h = items[i];
              return AppCard(
                radius: 18,
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 6, 14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HadithDetailScreen(hadith: h),
                )),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(h.arabic,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.arabic(size: 19, height: 1.7)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Pill(h.grade.v),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(h.reference.v,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.ui(
                                        size: 12, color: AppColors.muted)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('remove'),
                      onPressed: () => store.removeFavorite(h.id),
                      icon: const Icon(Icons.bookmark, color: AppColors.green),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
