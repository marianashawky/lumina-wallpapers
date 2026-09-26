import '../config/app_config.dart';

/// Placement switches stay off until a real AdMob account is connected.
/// Development unit IDs are Google's public test IDs. Production IDs come from
/// compile-time defines and are empty in this repository.
class AdConfig {
  const AdConfig({
    required this.isTestMode,
    required this.bannerEnabled,
    required this.interstitialEnabled,
    required this.rewardedEnabled,
    required this.appOpenEnabled,
    required this.androidAppId,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.rewardedAdUnitId,
  });

  final bool isTestMode;
  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool rewardedEnabled;
  final bool appOpenEnabled;
  final String androidAppId;
  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String rewardedAdUnitId;

  bool get anyPlacementEnabled => bannerEnabled || interstitialEnabled || rewardedEnabled || appOpenEnabled;

  static const _testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const _prodBanner = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _prodInterstitial = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const _prodRewarded = String.fromEnvironment('ADMOB_REWARDED_ID');

  static AdConfig get current {
    final test = !AppConfig.isProduction;
    return AdConfig(
      isTestMode: test,
      bannerEnabled: false,
      interstitialEnabled: false,
      rewardedEnabled: false,
      appOpenEnabled: false,
      androidAppId: test ? _testAppId : '',
      bannerAdUnitId: test ? _testBanner : _prodBanner,
      interstitialAdUnitId: test ? _testInterstitial : _prodInterstitial,
      rewardedAdUnitId: test ? _testRewarded : _prodRewarded,
    );
  }
}
