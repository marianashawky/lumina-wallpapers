import '../domain/wallpaper.dart';
import '../domain/wallpaper_setter.dart';

class PlatformWallpaperSetter implements WallpaperSetter {
  @override
  Future<SetWallpaperResult> setStaticWallpaper(
    Wallpaper wallpaper, {
    required bool highQuality,
    WallpaperTarget target = WallpaperTarget.both,
    void Function(double progress)? onProgress,
  }) async {
    return _unsupported;
  }

  @override
  Future<SetWallpaperResult> setLiveWallpaper(
    Wallpaper wallpaper, {
    required bool highQuality,
    void Function(double progress)? onProgress,
  }) async {
    return _unsupported;
  }

  @override
  Future<SetWallpaperResult> setVideoWallpaper(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
  }) async {
    return _unsupported;
  }

  static const _unsupported = SetWallpaperResult(
    SetWallpaperStatus.unsupported,
    'Setting a wallpaper is available on Android.',
  );
}
