import 'package:flutter/material.dart';

import '../data/gallery_repository.dart';
import '../models/album.dart';
import '../theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';
import '../widgets/db_image.dart';
import 'album_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List<Album> _albums = [];
  bool _loading = true;
  String? _error;
  String _category = 'الكل';

  List<Album> get _filtered => _category == 'الكل'
      ? _albums
      : _albums.where((a) => a.category == _category).toList();

  List<String> get _categories => [
    'الكل',
    ..._albums
        .map((album) => album.category)
        .where((category) => category != 'الكل')
        .toSet(),
  ];

  int get _totalPhotos =>
      _albums.fold(0, (sum, album) => sum + album.photoCount);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final albums = await GalleryRepository.instance.getAlbums();
      if (!mounted) return;
      setState(() {
        _albums = albums;
        _loading = false;
        _error = null;
        if (_category != 'الكل' && !_categories.contains(_category)) {
          _category = 'الكل';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل الألبومات';
      });
    }
  }

  Future<void> _openAlbum(Album album) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => AlbumScreen(album: album),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
        );
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
    final albums = _filtered;
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'الألبومات',
              subtitle: _loading
                  ? 'جارٍ التحميل...'
                  : '${_albums.length} ألبوم • $_totalPhotos صورة',
              leading: HeaderBackButton(
                onTap: () => Navigator.of(context).pop(),
              ),
              onSearch: () => showAppToast(context, 'البحث في الألبومات'),
              onMore: () => showAppToast(context, 'خيارات الألبومات'),
            ),
            const SizedBox(height: 2),
            _CategoryFilters(
              categories: _categories,
              selected: _category,
              onSelected: (category) => setState(() => _category = category),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'VAULT // ${albums.length} ALBUMS',
                    style: AppTextStyles.labelMonoSmall(
                      AppColors.outline,
                    ).copyWith(fontSize: 10),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.lock,
                    size: 11,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${albums.where((a) => a.isLocked).length} مقفلة',
                    style: AppTextStyles.labelMonoSmall(
                      AppColors.outline,
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: AppTextStyles.bodyMedium(
                          AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : albums.isEmpty
                  ? const _EmptyAlbums()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return _AlbumCard(
                          album: album,
                          onTap: () {
                            _openAlbum(album);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAppToast(context, 'إنشاء ألبوم جديد'),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 24),
      ),
      bottomNavigationBar: AppBottomNav(selectedIndex: 1, onTap: _onNavTap),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category == selected;
          return GestureDetector(
            onTap: () => onSelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
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
                category,
                style: AppTextStyles.bodySmall(
                  active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DbImage(
              photoId: album.coverPhotoId,
              fit: BoxFit.cover,
              cacheWidth: 900,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.35, 0.6, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (album.isFavorite)
                    _Badge(
                      icon: Icons.favorite,
                      color: AppColors.primaryContainer,
                    ),
                  if (album.isFavorite && album.isLocked)
                    const SizedBox(width: 6),
                  if (album.isLocked)
                    const _Badge(
                      icon: Icons.lock,
                      color: AppColors.primaryContainer,
                    ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineSmall(),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${album.photoCount} صورة',
                        style: AppTextStyles.labelMonoSmall(
                          AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 10),
                      ),
                      if (album.dateLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: AppTextStyles.labelMonoSmall(
                            AppColors.outline,
                          ).copyWith(fontSize: 10),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            album.dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMonoSmall(
                              AppColors.outline,
                            ).copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
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

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Badge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}

class _EmptyAlbums extends StatelessWidget {
  const _EmptyAlbums();

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
              Icons.photo_album_outlined,
              size: 30,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد ألبومات في هذا التصنيف',
            style: AppTextStyles.headlineSmall(),
          ),
        ],
      ),
    );
  }
}
