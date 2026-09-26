import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/ads/ad_banner_slot.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/local/local_store.dart';
import 'info_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final padding = AppSpacing.page(MediaQuery.sizeOf(context).width);
    return SafeArea(
      child: ListenableBuilder(
        listenable: deps.settings,
        builder: (context, _) {
          final settings = deps.settings;
          return ListView(
            padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, AppSpacing.xl),
            children: [
              Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              const _Label('Appearance'),
              SegmentedButton<AppThemePreference>(
                segments: const [
                  ButtonSegment(value: AppThemePreference.system, label: Text('System')),
                  ButtonSegment(value: AppThemePreference.dark, label: Text('Dark')),
                  ButtonSegment(value: AppThemePreference.light, label: Text('Light')),
                ],
                selected: {settings.theme},
                onSelectionChanged: (value) => settings.setTheme(value.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _Label('Downloads'),
              SegmentedButton<DownloadQuality>(
                segments: const [
                  ButtonSegment(value: DownloadQuality.standard, label: Text('Standard')),
                  ButtonSegment(value: DownloadQuality.high, label: Text('High')),
                ],
                selected: {settings.quality},
                onSelectionChanged: (value) => settings.setQuality(value.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-play previews'),
                subtitle: const Text('Play motion and video on the wallpaper screen'),
                value: settings.autoplayPreviews,
                onChanged: settings.setAutoplay,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                subtitle: const Text('Preference saved on this device'),
                value: settings.notifications,
                onChanged: settings.setNotifications,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Clear cache'),
                subtitle: const Text('Remove cached previews and temporary files'),
                onTap: () async {
                  await deps.cache.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('About'),
                onTap: () => _open(context, 'About', _about),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Privacy Policy'),
                onTap: () => _open(context, 'Privacy Policy', _privacy),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Terms'),
                onTap: () => _open(context, 'Terms', _terms),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('App version'),
                trailing: Text(AppInfo.version),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AdBannerSlot(),
            ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, String title, String body) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfoPage(title: title, body: body)));
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

const _about = '''
Lumina is a wallpaper studio for stills, motion, and video.

Collections load images from Unsplash and short videos from Pexels, so previews need a connection. Each wallpaper can show its source and license on the details screen.

On Android, still wallpapers can be applied to the home screen, the lock screen, or both. Motion wallpapers run in a live wallpaper service that slowly pans the image. Video wallpapers use that same service with a media player, then Android asks you to confirm Lumina as the live wallpaper.

Premium marks are prepared for a future subscription. Nothing in this version is locked. Advertising placements are prepared but turned off until a publisher AdMob account is connected.
''';

const _privacy = '''
Favorites, search history, download history, and settings stay on this device. Lumina does not ask you to create an account.

Saved wallpapers are written to your gallery after you allow storage access. That permission is requested when you save, not when the app opens.

Remote previews are requested from Unsplash and Pexels when you open them. Those services receive the network request needed to deliver the file.

The app includes the Google Mobile Ads SDK so advertising can be enabled later. In this build, banner, interstitial, rewarded, and app-open placements are switched off, so no ad is requested. When a publisher turns ads on, Google may process an advertising identifier and technical device data under Google's own policy. That is not the same as Lumina running its own account system.

There is no in-app analytics account in this build. To ask for deletion of on-device favorites or search history, clear the app data from Android settings or use Clear cache for preview files.
''';

const _terms = '''
Wallpapers are for personal use on your own devices. Catalog items keep the license shown on the details screen. Do not treat player, club, or character artwork as cleared unless that license says so.

Live and video installation depends on Android and the system wallpaper picker. If the picker is dismissed, the wallpaper is not changed.

Premium labels describe catalog items that a later version may offer with a subscription. This version does not charge for wallpapers.
''';
