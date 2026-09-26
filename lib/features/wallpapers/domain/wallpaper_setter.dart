import 'wallpaper.dart';

enum SetWallpaperStatus { applied, needsPicker, failed, unsupported }

enum WallpaperTarget { home, lock, both }

class SetWallpaperResult {
  const SetWallpaperResult(this.status, this.message);

  final SetWallpaperStatus status;
  final String message;

  bool get ok => status == SetWallpaperStatus.applied || status == SetWallpaperStatus.needsPicker;
}

abstract class WallpaperSetter {
  Future<SetWallpaperResult> setStaticWallpaper(
    Wallpaper wallpaper, {
    required bool highQuality,
    WallpaperTarget target = WallpaperTarget.both,
    void Function(double progress)? onProgress,
  });

  Future<SetWallpaperResult> setLiveWallpaper(
    Wallpaper wallpaper, {
    required bool highQuality,
    void Function(double progress)? onProgress,
  });

  Future<SetWallpaperResult> setVideoWallpaper(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
  });
}

extension WallpaperSetterDispatch on WallpaperSetter {
  Future<SetWallpaperResult> setWallpaper(
    Wallpaper wallpaper, {
    required bool highQuality,
    WallpaperTarget target = WallpaperTarget.both,
    void Function(double progress)? onProgress,
  }) {
    switch (wallpaper.type) {
      case WallpaperType.static:
        return setStaticWallpaper(wallpaper, highQuality: highQuality, target: target, onProgress: onProgress);
      case WallpaperType.live:
        return setLiveWallpaper(wallpaper, highQuality: highQuality, onProgress: onProgress);
      case WallpaperType.video:
        return setVideoWallpaper(wallpaper, onProgress: onProgress);
      case WallpaperType.animated:
        return Future.value(
          const SetWallpaperResult(
            SetWallpaperStatus.unsupported,
            'Animated wallpapers can be previewed here. System installation for this format is not available in this build.',
          ),
        );
    }
  }
}
