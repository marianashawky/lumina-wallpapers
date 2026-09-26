import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/ads/ad_banner_slot.dart';
import '../../../app/navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/wallpaper_masonry.dart';
import '../../categories/presentation/category_style.dart';
import '../domain/wallpaper.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _scroll = ScrollController();
  String? _tag;
  List<Wallpaper> _items = const [];
  var _hasMore = false;
  var _offset = 0;
  var _loading = false;
  var _failed = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final page = AppScope.of(context).repository.peekCategory(widget.categoryId);
    if (page != null) {
      _items = page.items;
      _hasMore = page.hasMore;
      _offset = page.nextOffset;
    } else {
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 480) {
      _load(reset: false);
    }
  }

  Future<void> _load({required bool reset}) async {
    setState(() {
      _loading = true;
      _failed = false;
      if (reset) {
        _items = const [];
        _offset = 0;
      }
    });
    try {
      final page = await AppScope.of(context).repository.loadCategory(
            widget.categoryId,
            tag: _tag,
            offset: reset ? 0 : _offset,
          );
      if (!mounted) return;
      setState(() {
        _items = reset ? page.items : [..._items, ...page.items];
        _hasMore = page.hasMore;
        _offset = page.nextOffset;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _items.isEmpty;
      });
    }
  }

  void _select(String? tag) {
    setState(() => _tag = tag);
    final page = AppScope.of(context).repository.peekCategory(widget.categoryId, tag: tag);
    if (page != null) {
      setState(() {
        _items = page.items;
        _hasMore = page.hasMore;
        _offset = page.nextOffset;
        _failed = false;
      });
      return;
    }
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final category = deps.repository.cachedCategories?.where((item) => item.id == widget.categoryId).firstOrNull;
    final title = category?.name ?? 'Wallpapers';
    final padding = AppSpacing.page(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ShimmerScope(
        child: Column(
          children: [
            if (category != null && category.filters.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  children: [
                    _FilterChip(label: 'All', selected: _tag == null, onTap: () => _select(null)),
                    for (final filter in category.filters)
                      _FilterChip(
                        label: filter.label,
                        selected: _tag == filter.tag,
                        onTap: () => _select(filter.tag),
                      ),
                  ],
                ),
              ),
            const AdBannerSlot(),
            Expanded(child: _body(padding, title)),
          ],
        ),
      ),
    );
  }

  Widget _body(double padding, String title) {
    if (_failed) {
      return ErrorState(message: 'The $title collection could not be loaded.', onRetry: () => _load(reset: true));
    }
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: categoryIcon(widget.categoryId),
        title: 'Nothing here yet',
        message: 'Try another filter. New wallpapers in this collection will show up here.',
      );
    }
    return WallpaperMasonry(
      controller: _scroll,
      wallpapers: _items,
      heroPrefix: 'category-${widget.categoryId}-${_tag ?? 'all'}',
      padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.xl),
      onOpen: (wallpaper, heroTag) => openWallpaper(context, wallpaper, heroTag: heroTag),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (dark ? AppColors.accent : AppColors.lightText)
                : (dark ? AppColors.chip : AppColors.lightChip),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? (dark ? AppColors.background : Colors.white) : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
