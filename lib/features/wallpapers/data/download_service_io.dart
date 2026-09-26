import 'dart:io';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/local/local_store.dart';
import '../domain/download_result.dart';
import '../domain/wallpaper.dart';
import 'wallpaper_files_io.dart';

class DownloadService {
  DownloadService({required LocalStore store, WallpaperFiles? files})
      : _store = store,
        _files = files ?? WallpaperFiles();

  final LocalStore _store;
  final WallpaperFiles _files;

  Future<DownloadResult> download(
    Wallpaper wallpaper, {
    required bool highQuality,
    void Function(double progress)? onProgress,
  }) async {
    if (_store.isDownloaded(wallpaper.id)) {
      return const DownloadResult(DownloadStatus.alreadySaved, 'Already saved on this device.');
    }
    final blocked = await _permissionGate(wallpaper.playsVideo);
    if (blocked != null) return blocked;
    try {
      final video = wallpaper.playsVideo;
      final file = await _files.materialize(
        wallpaper,
        highQuality: highQuality,
        video: video,
        onProgress: onProgress,
      );
      final name = 'lumen_${wallpaper.id}';
      final dynamic result = video
          ? await ImageGallerySaverPlus.saveFile(file.path, name: name)
          : await ImageGallerySaverPlus.saveImage(
              await file.readAsBytes(),
              quality: 100,
              name: name,
            );
      final saved = result is Map && (result['isSuccess'] == true || result['filePath'] != null);
      if (!saved) {
        return const DownloadResult(DownloadStatus.permissionDenied, 'Could not save the wallpaper. Allow storage access and try again.');
      }
      await _store.addDownload(wallpaper.id);
      return const DownloadResult(DownloadStatus.saved, 'Saved to your gallery.');
    } on SocketException {
      return const DownloadResult(DownloadStatus.network, 'No connection. The wallpaper was not saved.');
    } on FileSystemException catch (error) {
      return _fromFileError(error);
    } catch (_) {
      return const DownloadResult(DownloadStatus.failed, 'Could not save the wallpaper.');
    }
  }

  Future<DownloadResult?> _permissionGate(bool video) async {
    if (!Platform.isAndroid) return null;
    final permission = video ? Permission.videos : Permission.photos;
    var status = await permission.status;
    if (!status.isGranted && !status.isLimited) {
      status = await permission.request();
    }
    if (status.isGranted || status.isLimited) return null;
    if (status.isPermanentlyDenied) {
      return const DownloadResult(
        DownloadStatus.permissionDenied,
        'Storage access is blocked. Enable it in system settings to save wallpapers.',
      );
    }
    return const DownloadResult(
      DownloadStatus.permissionDenied,
      'Storage access is needed to save wallpapers.',
    );
  }

  DownloadResult _fromFileError(FileSystemException error) {
    final message = error.message.toLowerCase();
    final code = error.osError?.errorCode;
    if (code == 28 || message.contains('no space') || message.contains('not enough space')) {
      return const DownloadResult(DownloadStatus.storage, 'Not enough storage to save this wallpaper.');
    }
    if (message.contains('failed') || message.contains('socket') || message.contains('network')) {
      return const DownloadResult(DownloadStatus.network, 'The file could not be downloaded. Check your connection.');
    }
    return const DownloadResult(DownloadStatus.failed, 'Could not save the wallpaper.');
  }
}
