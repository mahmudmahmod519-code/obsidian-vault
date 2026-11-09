import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/album_photo.dart';
import '../models/viewer_photo.dart';
import '../theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';
import '../widgets/photo_tile.dart';
import 'albums_screen.dart';
import 'photo_viewer_screen.dart';
import 'settings_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<AlbumPhoto> _favorites =
      demoPhotos.where((p) => p.isFavorite).toList();

  void _openViewer(int index) {
    final photos = _favorites
        .asMap()
        .entries
        .map((e) => ViewerPhoto.fromAlbumPhoto(e.value, index: e.key))
        .toList();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) =>
            PhotoViewerScreen(photos: photos, initialIndex: index),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pop();
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AlbumsScreen()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
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
              subtitle: '${_favorites.length} صورة محفوظة',
              leading: HeaderBackButton(
                onTap: () => Navigator.of(context).pop(),
              ),
              onSearch: () => showAppToast(context, 'البحث في المفضلة'),
              onMore: () => showAppToast(context, 'خيارات المفضلة'),
            ),
            Expanded(
              child: _favorites.isEmpty
                  ? const _EmptyFavorites()
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'المفضلة',
                                  style: AppTextStyles.headlineSmall(),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'FAVORITES // ${_favorites.length}',
                                  style: AppTextStyles.labelMonoSmall(
                                    AppColors.outline,
                                  ).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final photo = _favorites[index];
                                return PhotoTile(
                                  imageUrl: photo.imageUrl,
                                  favorite: true,
                                  borderRadius: BorderRadius.circular(2),
                                  onTap: () => _openViewer(index),
                                );
                              },
                              childCount: _favorites.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(selectedIndex: 2, onTap: _onNavTap),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 30,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Text('لا توجد صور مفضلة', style: AppTextStyles.headlineSmall()),
          const SizedBox(height: 4),
          Text(
            'اضغط على القلب في أي صورة لإضافتها هنا',
            style: AppTextStyles.bodySmall(AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
