import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class AdService {
  AdService({AdConfig? config}) : config = config ?? AdConfig.current;

  final AdConfig config;
  InterstitialAd? _interstitial;
  BannerAd? _banner;
  int _actionsSinceAd = 0;

  Future<void> initialize() async {
    if (!config.anyPlacementEnabled) return;
    await MobileAds.instance.initialize();
    if (config.interstitialEnabled && config.interstitialAdUnitId.isNotEmpty) {
      _loadInterstitial();
    }
  }

  Widget buildBanner() {
    if (!config.bannerEnabled || config.bannerAdUnitId.isEmpty) {
      return const SizedBox.shrink();
    }
    _banner ??= BannerAd(
      adUnitId: config.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
    final ad = _banner;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(height: ad.size.height.toDouble(), child: AdWidget(ad: ad));
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: config.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => _interstitial = null,
      ),
    );
  }

  Future<void> maybeShowInterstitial() async {
    if (!config.interstitialEnabled || config.interstitialAdUnitId.isEmpty) return;
    _actionsSinceAd++;
    if (_actionsSinceAd < 3) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _actionsSinceAd = 0;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
    _interstitial = null;
  }

  Future<bool> showRewarded() {
    if (!config.rewardedEnabled || config.rewardedAdUnitId.isEmpty) {
      return Future.value(false);
    }
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: config.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              if (!completer.isCompleted) completer.complete(true);
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }
}
