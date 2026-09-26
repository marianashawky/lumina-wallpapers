import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/navigation.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/layout.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/wallpaper_image.dart';
import '../../../shared/widgets/wallpaper_masonry.dart';
import '../../categories/domain/wallpaper_category.dart';
import '../../wallpapers/domain/wallpaper.dart';
import '../../wallpapers/domain/wallpaper_repository.dart';
import '../../wallpapers/presentation/motion_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onFavorites});

  final VoidCallback onFavorites;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeFeed? _feed;
  var _failed = false;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _feed = AppScope.of(context).repository.cachedHome;
    if (_feed == null) _load();
  }

  Future<void> _load() async {
    try {
      final feed = await AppScope.of(context).repository.loadHome();
      if (mounted) setState(() => _feed = feed);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.page(width);
    return ShimmerScope(
      child: SafeArea(
        child: _failed
            ? ErrorState(message: 'Home could not be loaded.', onRetry: _load)
            : _feed == null
                ? const Center(child: CircularProgressIndicator())
                : _HomeBody(feed: _feed!, padding: padding, onFavorites: widget.onFavorites),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.feed, required this.padding, required this.onFavorites});

  final HomeFeed feed;
  final double padding;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    final categories = AppScope.of(context).repository.cachedCategories ?? const <WallpaperCategory>[];
    WallpaperCategory? categoryById(String id) {
      for (final category in categories) {
        if (category.id == id) return category;
      }
      return null;
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.xl),
      children: [
        Row(
          children: [
            const AppLogo(),
            const SizedBox(width: 12),
            Text(AppInfo.name, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            IconButton(
              tooltip: 'Search',
              onPressed: () => openSearch(context),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Favorites',
              onPressed: onFavorites,
              icon: const Icon(Icons.favorite_border),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Featured'),
        ListenableBuilder(
          listenable: AppScope.of(context).settings,
          builder: (context, _) => _Hero(wallpaper: feed.hero),
        ),
        SectionHeader(
          title: 'Live Wallpapers',
          onSeeAll: () {
            final category = categoryById('live');
            if (category != null) openCategory(context, category);
          },
        ),
        WallpaperCarousel(wallpapers: feed.live, heroPrefix: 'home-live', onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag)),
        SectionHeader(
          title: 'Anime',
          onSeeAll: () {
            final category = categoryById('anime');
            if (category != null) openCategory(context, category);
          },
        ),
        WallpaperCarousel(wallpapers: feed.anime, heroPrefix: 'home-anime', onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag)),
        SectionHeader(
          title: 'Nature',
          onSeeAll: () {
            final category = categoryById('nature');
            if (category != null) openCategory(context, category);
          },
        ),
        WallpaperCarousel(wallpapers: feed.nature, heroPrefix: 'home-nature', onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag)),
        SectionHeader(
          title: 'Cars',
          onSeeAll: () {
            final category = categoryById('cars');
            if (category != null) openCategory(context, category);
          },
        ),
        WallpaperCarousel(wallpapers: feed.cars, heroPrefix: 'home-cars', onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag)),
        const SectionHeader(title: 'More categories'),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ActionChip(
                label: Text(category.name),
                onPressed: () => openCategory(context, category),
              );
            },
          ),
        ),
        const SectionHeader(title: 'Trending'),
        WallpaperMasonry(
          wallpapers: feed.trending,
          heroPrefix: 'home-trending',
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag),
        ),
        const SectionHeader(title: 'Recently Added'),
        WallpaperMasonry(
          wallpapers: feed.recent,
          heroPrefix: 'home-recent',
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    final height = AppLayout.heroHeight(MediaQuery.sizeOf(context).width);
    final autoplay = AppScope.of(context).settings.autoplayPreviews && wallpaper.playsMotion;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (autoplay)
              MotionPreview(wallpaper: wallpaper, autoplay: true, showControls: false)
            else
              WallpaperImage(wallpaper: wallpaper, thumbnail: false),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xCC07080B)],
                  stops: [0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    wallpaper.typeLabel().toUpperCase(),
                    style: const TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    wallpaper.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => openWallpaper(context, wallpaper, heroTag: 'home-hero-${wallpaper.id}'),
                    child: const Text('Explore'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
