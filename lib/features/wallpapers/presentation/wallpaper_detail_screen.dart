import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../app/navigation.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/favorite_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/wallpaper_image.dart';
import '../../../shared/widgets/wallpaper_masonry.dart';
import '../../categories/presentation/category_style.dart';
import '../domain/download_result.dart';
import '../domain/wallpaper.dart';
import '../domain/wallpaper_setter.dart';
import 'motion_preview.dart';
import 'video_preview.dart';

class WallpaperDetailScreen extends StatefulWidget {
  const WallpaperDetailScreen({super.key, required this.wallpaper, required this.heroTag});

  final Wallpaper wallpaper;
  final String heroTag;

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  List<Wallpaper> _related = const [];
  var _busy = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRelated();
    });
  }

  Future<void> _loadRelated() async {
    final items = await AppScope.of(context).repository.related(widget.wallpaper);
    if (mounted) setState(() => _related = items);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _download() async {
    if (_busy) return;
    final deps = AppScope.of(context);
    setState(() {
      _busy = true;
      _progress = 0;
    });
    final result = await deps.downloads.download(
      widget.wallpaper,
      highQuality: deps.settings.highQuality,
      onProgress: (value) {
        if (mounted && value >= 0) setState(() => _progress = value);
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
    });
    _toast(result.message);
    if (result.status == DownloadStatus.saved) {
      await deps.ads.maybeShowInterstitial();
    }
  }

  Future<void> _setWallpaper() async {
    if (_busy) return;
    final deps = AppScope.of(context);
    if (!deps.premium.canApply(widget.wallpaper)) {
      _toast('This wallpaper is marked premium.');
      return;
    }
    setState(() {
      _busy = true;
      _progress = 0;
    });
    final target = widget.wallpaper.type == WallpaperType.static ? await _chooseTarget() : WallpaperTarget.both;
    if (!mounted) return;
    if (target == null) {
      setState(() {
        _busy = false;
        _progress = null;
      });
      return;
    }
    final result = await deps.setter.setWallpaper(
      widget.wallpaper,
      highQuality: deps.settings.highQuality,
      target: target,
      onProgress: (value) {
        if (mounted && value >= 0) setState(() => _progress = value);
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
    });
    _toast(result.message);
  }

  Future<WallpaperTarget?> _chooseTarget() {
    return showModalBottomSheet<WallpaperTarget>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Home screen'),
                onTap: () => Navigator.pop(context, WallpaperTarget.home),
              ),
              ListTile(
                title: const Text('Lock screen'),
                onTap: () => Navigator.pop(context, WallpaperTarget.lock),
              ),
              ListTile(
                title: const Text('Home and lock screen'),
                onTap: () => Navigator.pop(context, WallpaperTarget.both),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _share() async {
    if (_busy) return;
    final deps = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await deps.share.share(widget.wallpaper, highQuality: deps.settings.highQuality);
      await deps.store.incrementShare();
    } catch (_) {
      if (mounted) _toast('Could not open the share sheet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = widget.wallpaper;
    final deps = AppScope.of(context);
    final category = deps.repository.cachedCategories?.where((item) => item.id == wallpaper.categoryId).firstOrNull;
    final autoplay = deps.settings.autoplayPreviews;
    final media = MediaQuery.of(context);
    final height = media.size.height;
    final bottomInset = media.padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _preview(wallpaper, autoplay),
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x66000000), Color(0x00000000), Color(0xE607080B)],
                            stops: [0, 0.45, 1],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Back',
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 720, maxHeight: height * 0.48),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + bottomInset),
                          child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(categoryIcon(wallpaper.categoryId), color: Colors.white70, size: 16),
                                  Text(
                                    category?.name ?? wallpaper.categoryId,
                                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                  ),
                                  if (wallpaper.isPremium) const _Pill(label: 'Premium'),
                                  _Pill(label: wallpaper.typeLabel()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                wallpaper.title,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                              ),
                              if (wallpaper.subtitle.isNotEmpty)
                                Text(wallpaper.subtitle, style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text(wallpaper.resolutionLabel, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                              if (wallpaper.creditLine != null)
                                Text(wallpaper.creditLine!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final tag in wallpaper.tags.take(6))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33111111),
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  FavoriteButton(wallpaperId: wallpaper.id),
                                  _Action(
                                    icon: Icons.download_rounded,
                                    label: 'Save',
                                    progress: _busy ? _progress : null,
                                    onTap: _download,
                                  ),
                                  _Action(icon: Icons.wallpaper_rounded, label: 'Set', onTap: _setWallpaper),
                                  _Action(icon: Icons.ios_share_rounded, label: 'Share', onTap: _share),
                                ],
                              ),
                            ],
                          ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_related.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'More like this'),
                      WallpaperCarousel(
                        wallpapers: _related,
                        heroPrefix: 'related',
                        onOpen: (wallpaper, heroTag) => openWallpaper(context, wallpaper, heroTag: heroTag),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _preview(Wallpaper wallpaper, bool autoplay) {
    if (wallpaper.playsVideo) {
      return VideoPreview(wallpaper: wallpaper, autoplay: autoplay);
    }
    if (wallpaper.playsMotion) {
      return MotionPreview(wallpaper: wallpaper, autoplay: autoplay);
    }
    return Hero(
      tag: widget.heroTag,
      child: WallpaperImage(wallpaper: wallpaper, thumbnail: false, fit: BoxFit.cover),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.progress});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              progress == null
                  ? Icon(icon, color: Colors.white)
                  : SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        value: progress == 0 ? null : progress,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
