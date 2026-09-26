enum DownloadStatus { saved, alreadySaved, failed, permissionDenied, network, storage }

class DownloadResult {
  const DownloadResult(this.status, this.message);

  final DownloadStatus status;
  final String message;

  bool get ok => status == DownloadStatus.saved || status == DownloadStatus.alreadySaved;
}
