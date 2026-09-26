import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/ads/ad_banner_slot.dart';
import '../../../app/navigation.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/wallpaper_image.dart';
import '../../../shared/widgets/wallpaper_masonry.dart';
import '../../categories/domain/wallpaper_category.dart';
import '../../categories/presentation/category_style.dart';
import '../../wallpapers/domain/wallpaper.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final categories = repo.cachedCategories ?? const <WallpaperCategory>[];
    final feed = repo.cachedHome;
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.page(width);
    final trending = feed?.trending ?? const <Wallpaper>[];
    final recent = feed?.recent ?? const <Wallpaper>[];
    final recommended = <Wallpaper>[
      if (feed != null) feed.hero,
      ...?feed?.live.take(3),
      ...?feed?.anime.take(2),
    ];

    return ShimmerScope(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, AppSpacing.xl),
          children: [
            Text('Explore', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            _SearchTap(onTap: () => openSearch(context)),
            const SectionHeader(title: 'Categories'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width >= 900 ? 3 : 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryCard(category: category, onTap: () => openCategory(context, category));
              },
            ),
            const SectionHeader(title: 'Trending'),
            WallpaperCarousel(
              wallpapers: trending,
              heroPrefix: 'explore-trending',
              onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag),
            ),
            const SectionHeader(title: 'New'),
            WallpaperCarousel(
              wallpapers: recent,
              heroPrefix: 'explore-new',
              onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag),
            ),
            const SectionHeader(title: 'Recommended'),
            WallpaperCarousel(
              wallpapers: recommended,
              heroPrefix: 'explore-recommended',
              onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag),
            ),
            const AdBannerSlot(),
          ],
        ),
      ),
    );
  }
}

class _SearchTap extends StatelessWidget {
  const _SearchTap({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 10),
              Text('Search wallpapers, tags, categories', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final WallpaperCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _cover(category.coverUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xCC07080B)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(categoryIcon(category.id), color: Colors.white, size: 18),
                  const SizedBox(height: 6),
                  Text(category.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('${category.wallpaperCount}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    }
    return WallpaperImage(
      wallpaper: Wallpaper(
        id: url,
        title: '',
        imageUrl: url,
        thumbnailUrl: url,
        type: WallpaperType.static,
        source: MediaSource.network,
        categoryId: '',
        tags: const [],
        width: 1,
        height: 1,
        createdAt: DateTime.utc(2026),
      ),
    );
  }
}
