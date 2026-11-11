import 'package:flutter/material.dart';

import '../data/gallery_repository.dart';
import '../models/album_photo.dart';
import '../models/viewer_photo.dart';
import '../theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_header.dart';
import '../widgets/photo_tile.dart';
import 'photo_viewer_screen.dart';
import 'settings_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<AlbumPhoto> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final favorites = await GalleryRepository.instance.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openViewer(int index) async {
    final photos = _favorites
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

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pop();
        break;
      case 1:
        break;
      case 2:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'المفضلة',
              subtitle: _loading
                  ? 'جارٍ التحميل...'
                  : '${_favorites.length} صورة محفوظة',
              leading: HeaderBackButton(
                onTap: () => Navigator.of(context).pop(),
              ),
              onSearch: null,
              onMore: null,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                      ),
                    )
                  : _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد صور مفضلة',
                            style: AppTextStyles.headlineSmall(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أضف الصور للمفضلة من القلب في كل صورة',
                            style: AppTextStyles.bodySmall(
                              AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 2,
                                  crossAxisSpacing: 2,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final photo = _favorites[index];
                              return PhotoTile(
                                photoId: photo.id,
                                favorite: true,
                                borderRadius: BorderRadius.circular(2),
                                onTap: () {
                                  _openViewer(index);
                                },
                              );
                            }, childCount: _favorites.length),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(selectedIndex: 1, onTap: _onNavTap),
    );
  }
}
