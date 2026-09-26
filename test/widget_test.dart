import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_wallpaper/core/ads/ad_config.dart';
import 'package:football_wallpaper/core/constants/app_info.dart';
import 'package:football_wallpaper/data/local/local_store.dart';
import 'package:football_wallpaper/features/favorites/presentation/favorites_controller.dart';
import 'package:football_wallpaper/features/wallpapers/data/mock_wallpaper_repository.dart';
import 'package:football_wallpaper/features/wallpapers/domain/download_result.dart';
import 'package:football_wallpaper/features/wallpapers/domain/wallpaper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog categories and live items stay consistent', () async {
    final repository = MockWallpaperRepository();
    final categories = await repository.loadCategories();
    expect(categories.map((category) => category.id), containsAll([
      CategoryIds.live,
      CategoryIds.anime,
      CategoryIds.nature,
      CategoryIds.cars,
      CategoryIds.gaming,
      CategoryIds.space,
      CategoryIds.abstract,
      CategoryIds.minimal,
      CategoryIds.technology,
      CategoryIds.dark,
    ]));

    final rain = await repository.search('rain');
    expect(rain, isNotEmpty);
    expect(rain.every((wallpaper) => wallpaper.matches('rain')), isTrue);

    final live = await repository.loadCategory(CategoryIds.live, limit: 100);
    expect(live.items, isNotEmpty);
    expect(live.items.every((wallpaper) => wallpaper.type != WallpaperType.static), isTrue);
    expect(live.items.every((wallpaper) => wallpaper.catalogSource != null), isTrue);
  });

  test('wallpaper credit and resolution are derived from the model', () {
    final wallpaper = Wallpaper(
      id: 'sample',
      title: 'Quiet Orbit',
      imageUrl: 'https://example.com/full.jpg',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      type: WallpaperType.live,
      source: MediaSource.network,
      categoryId: CategoryIds.nature,
      tags: const ['stars'],
      width: 1200,
      height: 1920,
      createdAt: DateTime.utc(2026, 1, 1),
      catalogSource: 'Unsplash',
      license: 'Unsplash License',
    );
    expect(wallpaper.resolutionLabel, '1200 × 1920');
    expect(wallpaper.creditLine, 'Unsplash · Unsplash License');
    expect(wallpaper.matches('orbit'), isTrue);
    expect(wallpaper.matches('football'), isFalse);
  });

  test('download results distinguish success from blocked saves', () {
    expect(const DownloadResult(DownloadStatus.saved, 'ok').ok, isTrue);
    expect(const DownloadResult(DownloadStatus.alreadySaved, 'ok').ok, isTrue);
    expect(const DownloadResult(DownloadStatus.permissionDenied, 'no').ok, isFalse);
    expect(const DownloadResult(DownloadStatus.network, 'no').ok, isFalse);
    expect(const DownloadResult(DownloadStatus.storage, 'no').ok, isFalse);
  });

  test('favorites persist in local storage', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final favorites = FavoritesController(store);
    await favorites.load();
    expect(favorites.ids, isEmpty);

    await favorites.toggle('motion_stars');
    expect(favorites.isFavorite('motion_stars'), isTrue);

    final restored = FavoritesController(store);
    await restored.load();
    expect(restored.isFavorite('motion_stars'), isTrue);

    await restored.toggle('motion_stars');
    expect(restored.isFavorite('motion_stars'), isFalse);
  });

  test('ad placements stay off until a publisher enables them', () {
    final config = AdConfig.current;
    expect(config.bannerEnabled, isFalse);
    expect(config.interstitialEnabled, isFalse);
    expect(config.rewardedEnabled, isFalse);
    expect(config.appOpenEnabled, isFalse);
    expect(config.anyPlacementEnabled, isFalse);
  });
}
