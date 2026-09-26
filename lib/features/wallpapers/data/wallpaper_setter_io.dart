import 'dart:io';

import 'package:flutter/services.dart';

import '../../../core/constants/app_info.dart';
import '../domain/wallpaper.dart';
import '../domain/wallpaper_setter.dart';
import 'wallpaper_files_io.dart';

class PlatformWallpaperSetter implements WallpaperSetter {
  PlatformWallpaperSetter({WallpaperFiles? files}) : _files = files ?? WallpaperFiles();

  final WallpaperFiles _files;
  static const _channel = MethodChannel(WallpaperChannel.name);

  @override
  Future<SetWallpaperResult> setStaticWallpaper(
    Wallpaper wallpaper, {
    required bool highQuality,
    WallpaperTarget target = WallpaperTarget.both,
    void Function(double progress)? onProgress,
  }) {
    return _apply(wallpaper, kind: 'static', highQuality: highQuality, target: target, onProgress: onProgress);
  }

  @override
  Future<SetWallpaperResult> setLiveWallpaper(
    Wallpaper wallpaper, {
    required bool highQuality,
    void Function(double progress)? onProgress,
  }) {
    return _apply(wallpaper, kind: 'motion', highQuality: highQuality, onProgress: onProgress);
  }

  @override
  Future<SetWallpaperResult> setVideoWallpaper(
    Wallpaper wallpaper, {
    void Function(double progress)? onProgress,
  }) {
    return _apply(wallpaper, kind: 'video', highQuality: true, onProgress: onProgress);
  }

  Future<SetWallpaperResult> _apply(
    Wallpaper wallpaper, {
    required String kind,
    required bool highQuality,
    WallpaperTarget target = WallpaperTarget.both,
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      return const SetWallpaperResult(
        SetWallpaperStatus.unsupported,
        'Setting a wallpaper is available on Android.',
      );
    }
    try {
      final file = await _files.materialize(
        wallpaper,
        highQuality: highQuality,
        video: kind == 'video',
        onProgress: onProgress,
      );
      final method = kind == 'static' ? 'setWallpaper' : 'setLiveWallpaper';
      final status = await _channel.invokeMethod<String>(method, {
        'path': file.path,
        'kind': kind,
        'target': target.name,
      });
      switch (status) {
        case 'ok':
          return SetWallpaperResult(
            SetWallpaperStatus.applied,
            kind == 'static' ? 'Wallpaper updated.' : 'Live wallpaper updated.',
          );
        case 'picker':
          return const SetWallpaperResult(
            SetWallpaperStatus.needsPicker,
            'Choose Lumina in the next screen so the wallpaper keeps moving.',
          );
        default:
          return const SetWallpaperResult(SetWallpaperStatus.failed, 'Could not set the wallpaper.');
      }
    } catch (_) {
      return const SetWallpaperResult(SetWallpaperStatus.failed, 'Could not set the wallpaper.');
    }
  }
}
