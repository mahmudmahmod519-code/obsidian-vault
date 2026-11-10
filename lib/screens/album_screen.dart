import 'package:flutter/material.dart';

import '../data/gallery_repository.dart';
import '../models/album.dart';
import '../models/album_photo.dart';
import '../models/viewer_photo.dart';
import '../theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';
import '../widgets/db_image.dart';
import '../widgets/photo_tile.dart';
import 'photo_viewer_screen.dart';

class AlbumScreen extends StatefulWidget {
  final Album album;

  const AlbumScreen({super.key, required this.album});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<AlbumPhoto> _photos = [];
  Set<int> _favoriteIds = {};
  bool _loading = true;
  bool _favoritesOnly = false;
  int _crossAxisCount = 3;

  Album get album => widget.album;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await GalleryRepository.instance.getPhotosForAlbum(
        album.id,
      );
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _favoriteIds = photos
            .where((photo) => photo.isFavorite)
            .map((photo) => photo.id)
            .toSet();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<AlbumPhoto> get _visiblePhotos {
    if (!_favoritesOnly) return _photos;
    return _photos.where((photo) => _favoriteIds.contains(photo.id)).toList();
  }

  Future<void> _openViewer(int index) async {
    if (_photos.isEmpty) return;
    final photos = _photos
        .asMap()
        .entries
        .map((e) => ViewerPhoto.fromAlbumPhoto(e.value, index: e.key))
        .toList();
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) =>
            PhotoViewerScreen(photos: photos, initialIndex: index),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _toggleFavorite(AlbumPhoto photo) async {
    final next = !_favoriteIds.contains(photo.id);
    await GalleryRepository.instance.setFavorite(photo.id, next);
    if (!mounted) return;
    setState(() {
      if (next) {
        _favoriteIds.add(photo.id);
      } else {
        _favoriteIds.remove(photo.id);
      }
    });
    showAppToast(context, next ? 'أضيفت إلى المفضلة' : 'أزيلت من المفضلة');
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePhotos;
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: album.name,
              subtitle: '${album.photoCount} صورة • ${album.dateLabel}',
              leading: HeaderBackButton(
                onTap: () => Navigator.of(context).pop(),
              ),
              onSearch: () => showAppToast(context, 'البحث داخل الألبوم'),
              onMore: () => showAppToast(context, 'خيارات الألبوم'),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildCover()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'الكل',
                            active: !_favoritesOnly,
                            onTap: () => setState(() => _favoritesOnly = false),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'المفضلة',
                            active: _favoritesOnly,
                            onTap: () => setState(() => _favoritesOnly = true),
                          ),
                          const Spacer(),
                          _ViewToggle(
                            crossAxisCount: _crossAxisCount,
                            onChanged: (count) =>
                                setState(() => _crossAxisCount = count),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyAlbumFavorites(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _crossAxisCount,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final photo = visible[i];
                          final photoIndex = _photos.indexWhere(
                            (item) => item.id == photo.id,
                          );
                          return PhotoTile(
                            photoId: photo.id,
                            favorite: _favoriteIds.contains(photo.id),
                            borderRadius: BorderRadius.circular(2),
                            onTap: () {
                              _openViewer(photoIndex < 0 ? 0 : photoIndex);
                            },
                            onLongPress: () {
                              _toggleFavorite(photo);
                            },
                          );
                        }, childCount: visible.length),
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildEndMarker()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 214,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DbImage(
                photoId: album.coverPhotoId,
                fit: BoxFit.cover,
                cacheWidth: 1200,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.2, 0.55, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        album.isLocked
                            ? Icons.lock
                            : Icons.photo_album_outlined,
                        size: 12,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        album.isLocked ? 'ألبوم مقفل' : 'ألبوم خاص',
                        style: AppTextStyles.labelMonoSmall(
                          AppColors.primaryContainer,
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headlineLarge(),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${album.photoCount} صورة • ${album.dateLabel}',
                            style: AppTextStyles.labelMonoSmall(
                              AppColors.onSurfaceVariant,
                            ).copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        _openViewer(0);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.onPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndMarker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 34),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.outline,
                ),
                const SizedBox(height: 4),
                Text(
                  'نهاية الألبوم • ${album.photoCount} صورة',
                  style: AppTextStyles.labelMonoSmall(
                    AppColors.outline,
                  ).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? AppColors.primaryContainer
                : AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall(
            active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final int crossAxisCount;
  final ValueChanged<int> onChanged;

  const _ViewToggle({required this.crossAxisCount, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIcon(
            icon: Icons.grid_view,
            active: crossAxisCount == 2,
            onTap: () => onChanged(2),
          ),
          _ToggleIcon(
            icon: Icons.apps,
            active: crossAxisCount == 3,
            onTap: () => onChanged(3),
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 30,
        height: 28,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyAlbumFavorites extends StatelessWidget {
  const _EmptyAlbumFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 34,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(height: 10),
          Text(
            'لا توجد صور مفضلة في هذا الألبوم',
            style: AppTextStyles.bodyMedium(AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
