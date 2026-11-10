import 'package:flutter/material.dart';

import '../data/gallery_repository.dart';
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
  List<AlbumPhoto> _favorites = [];
  List<AlbumPhoto> _displayedFavorites = [];
  bool _loading = true;
  String _searchQuery = '';

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
        _displayedFavorites = favorites;
        _loading = false;
        _searchQuery = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: _FavoritesSearchDelegate(
        onResult: (query) {
          setState(() {
            _searchQuery = query;
            final q = query.toLowerCase();
            _displayedFavorites = _favorites
                .where(
                  (p) =>
                      p.title.toLowerCase().contains(q) ||
                      p.date.toLowerCase().contains(q),
                )
                .toList();
          });
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
            _displayedFavorites = _favorites;
          });
        },
      ),
    );
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.refresh,
                color: AppColors.primaryContainer,
              ),
              title: const Text('تحديث المفضلة'),
              onTap: () {
                Navigator.pop(context);
                _load();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: AppColors.primaryContainer,
              ),
              title: const Text('عن المفضلة'),
              onTap: () {
                Navigator.pop(context);
                showAppToast(
                  context,
                  '${_displayedFavorites.length} صورة مفضلة',
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AlbumsScreen()),
        );
        break;
      case 2:
        break;
      case 3:
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
                  : '${_displayedFavorites.length} صورة محفوظة',
              leading: HeaderBackButton(
                onTap: () => Navigator.of(context).pop(),
              ),
              onSearch: _openSearch,
              onMore: _showMoreSheet,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                      ),
                    )
                  : _displayedFavorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد نتائج',
                            style: AppTextStyles.headlineSmall(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'جرّب كلمة بحث أخرى'
                                : 'لا توجد صور مفضلة',
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
                                  'FAVORITES // ${_displayedFavorites.length}',
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
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final photo = _displayedFavorites[index];
                              return PhotoTile(
                                photoId: photo.id,
                                favorite: true,
                                borderRadius: BorderRadius.circular(2),
                                onTap: () {
                                  _openViewer(index);
                                },
                              );
                            }, childCount: _displayedFavorites.length),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

class _FavoritesSearchDelegate extends SearchDelegate<String> {
  final ValueChanged<String> onResult;
  final VoidCallback onClear;

  _FavoritesSearchDelegate({required this.onResult, required this.onClear});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onClear();
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onResult(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('ابحث في الصور المفضلة'));
  }
}
