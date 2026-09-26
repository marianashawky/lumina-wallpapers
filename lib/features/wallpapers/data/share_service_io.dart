import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_info.dart';
import '../domain/wallpaper.dart';
import 'wallpaper_files_io.dart';

class ShareService {
  ShareService({WallpaperFiles? files}) : _files = files ?? WallpaperFiles();

  final WallpaperFiles _files;

  Future<void> share(Wallpaper wallpaper, {required bool highQuality}) async {
    final file = await _files.materialize(
      wallpaper,
      highQuality: highQuality,
      video: wallpaper.playsVideo,
    );
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${wallpaper.title} — ${AppInfo.name}',
      );
    } finally {
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
  }
}
