enum WallpaperType { static, live, video, animated }

enum MediaSource { asset, network }

class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.type,
    required this.source,
    required this.categoryId,
    required this.tags,
    required this.width,
    required this.height,
    required this.createdAt,
    this.previewUrl,
    this.subtitle = '',
    this.subject,
    this.isFeatured = false,
    this.isTrending = false,
    this.isPremium = false,
    this.downloads = 0,
    this.catalogSource,
    this.author,
    this.license,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? subject;
  final String imageUrl;
  final String thumbnailUrl;
  final String? previewUrl;
  final WallpaperType type;
  final MediaSource source;
  final String categoryId;
  final List<String> tags;
  final int width;
  final int height;
  final bool isFeatured;
  final bool isTrending;
  final bool isPremium;
  final DateTime createdAt;
  final int downloads;
  final String? catalogSource;
  final String? author;
  final String? license;

  String? get creditLine {
    final parts = [catalogSource, author, license].whereType<String>().where((part) => part.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  bool get playsMotion => type == WallpaperType.live || type == WallpaperType.animated;

  bool get playsVideo => type == WallpaperType.video && (previewUrl?.isNotEmpty ?? false);

  String get resolutionLabel => '$width × $height';

  String typeLabel() {
    switch (type) {
      case WallpaperType.static:
        return 'Still';
      case WallpaperType.live:
        return 'Motion';
      case WallpaperType.video:
        return 'Video';
      case WallpaperType.animated:
        return 'Animated';
    }
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (title.toLowerCase().contains(q)) return true;
    if (subtitle.toLowerCase().contains(q)) return true;
    if ((subject ?? '').toLowerCase().contains(q)) return true;
    if (categoryId.contains(q)) return true;
    return tags.any((tag) => tag.toLowerCase().contains(q));
  }
}
