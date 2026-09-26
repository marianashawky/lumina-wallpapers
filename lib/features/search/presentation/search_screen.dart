import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/ads/ad_banner_slot.dart';
import '../../../app/navigation.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/wallpaper_masonry.dart';
import '../../categories/domain/wallpaper_category.dart';
import '../../wallpapers/domain/wallpaper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  var _loading = false;
  var _query = '';
  List<Wallpaper> _wallpapers = const [];
  List<WallpaperCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
      _loading = value.trim().isNotEmpty;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    if (!mounted) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _wallpapers = const [];
          _categories = const [];
        });
      }
      return;
    }
    final repo = AppScope.of(context).repository;
    final wallpapers = await repo.search(trimmed);
    final categories = await repo.searchCategories(trimmed);
    if (!mounted || trimmed != _controller.text.trim()) return;
    setState(() {
      _loading = false;
      _wallpapers = wallpapers;
      _categories = categories;
    });
    await AppScope.of(context).searchHistory.remember(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.page(MediaQuery.sizeOf(context).width);
    return Scaffold(
      body: ShimmerScope(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, 8, padding, 8),
                child: Row(
                  children: [
                    IconButton(tooltip: 'Back', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: _onChanged,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Wallpapers, categories, tags',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              Expanded(child: _results(padding)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results(double padding) {
    if (_query.trim().isEmpty) {
      return ListenableBuilder(
        listenable: AppScope.of(context).searchHistory,
        builder: (context, _) {
          final recent = AppScope.of(context).searchHistory.recent;
          if (recent.isEmpty) {
            return const EmptyState(
              icon: Icons.search,
              title: 'Search Lumina',
              message: 'Find wallpapers by name, category, or tag.',
            );
          }
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: padding),
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Recent', style: TextStyle(fontWeight: FontWeight.w700))),
                  TextButton(onPressed: () => AppScope.of(context).searchHistory.clear(), child: const Text('Clear')),
                ],
              ),
              for (final term in recent)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(term),
                  onTap: () {
                    _controller.text = term;
                    _controller.selection = TextSelection.collapsed(offset: term.length);
                    _onChanged(term);
                  },
                ),
            ],
          );
        },
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_wallpapers.isEmpty && _categories.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No results',
        message: 'Try a shorter word, a category, or a tag like rain, anime, or stadiums.',
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(padding, 0, padding, AppSpacing.xl),
      children: [
        if (_categories.isNotEmpty) ...[
          const Text('Categories', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _categories)
                ActionChip(
                  label: Text(category.name),
                  onPressed: () => openCategory(context, category),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const AdBannerSlot(),
        if (_wallpapers.isNotEmpty)
          WallpaperMasonry(
            wallpapers: _wallpapers,
            heroPrefix: 'search',
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onOpen: (wallpaper, tag) => openWallpaper(context, wallpaper, heroTag: tag),
          ),
      ],
    );
  }
}
