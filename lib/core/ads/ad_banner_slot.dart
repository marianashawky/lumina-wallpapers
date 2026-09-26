import 'package:flutter/widgets.dart';

import '../../app/app_scope.dart';

/// Reserved banner position. Renders nothing while ads are disabled.
class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScope.of(context).ads.buildBanner();
  }
}
