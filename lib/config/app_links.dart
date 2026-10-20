/// Links used when sharing a hadith ("download the app").
///
/// TODO before release: put your real store links here.
/// - Android: https://play.google.com/store/apps/details?id=<your applicationId>
///   (applicationId is in android/app/build.gradle)
/// - iPhone:  https://apps.apple.com/app/id<your App Store id>
///
/// `shareUrl` is the one link printed on the share image and added to the
/// message. Best is a single page that sends Android users to Google Play and
/// iPhone users to the App Store (for example a small page on your website).
/// While it is empty, sharing still works — just without a link.
class AppLinks {
  static const android = '';
  static const ios = '';

  /// The link shown on shared cards. Falls back to the Android link.
  static const shareUrl = '';

  static String get forSharing =>
      shareUrl.isNotEmpty ? shareUrl : (android.isNotEmpty ? android : ios);
}
