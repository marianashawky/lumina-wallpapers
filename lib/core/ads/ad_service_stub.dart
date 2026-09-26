import 'package:flutter/widgets.dart';

import 'ad_config.dart';

class AdService {
  AdService({AdConfig? config}) : config = config ?? AdConfig.current;

  final AdConfig config;

  Future<void> initialize() async {}

  Widget buildBanner() => const SizedBox.shrink();

  Future<void> maybeShowInterstitial() async {}

  Future<bool> showRewarded() async => false;
}
