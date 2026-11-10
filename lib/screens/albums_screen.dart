import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  List<Album> _displayedAlbums = [];
  bool _loading = true;
  String? _error;
  String _category = 'الكل';
  String _searchQuery = '';

  List<Album> get _filtered {
    var result = _category == 'الكل'
        ? _displayedAlbums
        : _displayedAlbums.where((a) => a.category == _category).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (a) =>
                a.name.toLowerCase().contains(q) ||
                a.category.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

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
        _displayedAlbums = albums;
        _loading = false;
        _error = null;
        _searchQuery = '';
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

  void _openSearch() {
    showSearch(
      context: context,
      delegate: _AlbumSearchDelegate(
        onResult: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
          });
        },
      ),
    );
  }

  Future<void> _createAlbum() async {
    final controller = TextEditingController();
    final categoryController = TextEditingController(text: 'الكل');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('إنشاء ألبوم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم الألبوم',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'التصنيف',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    await GalleryRepository.instance.createAlbum(
      name: result,
      category: categoryController.text.trim().isNotEmpty
          ? categoryController.text.trim()
          : 'الكل',
    );
    await _load();
    if (mounted) showAppToast(context, 'تم إنشاء الألبوم');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null || !mounted) return;

    try {
      final bytes = await picked.readAsBytes();
      final fileName = picked.name.split('/').last;
      final date = 'اليوم';
      final albumId = 'memories'; // الألبوم الافتراضي

      await GalleryRepository.instance.addPhoto(
        title: fileName,
        date: date,
        albumId: albumId,
        assetPath: picked.path,
        imageBytes: bytes,
        isFavorite: false,
      );

      await _load();
      if (mounted) showAppToast(context, 'تم إضافة الصورة: $fileName');
    } catch (e) {
      if (mounted) showAppToast(context, 'فشل إضافة الصورة');
    }
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
              title: const Text('تحديث الألبومات'),
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
              title: const Text('عن التطبيق'),
              onTap: () {
                Navigator.pop(context);
                showAppToast(context, 'Obsidian Vault - ألبومات خاصة');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
                  : '${_displayedAlbums.length} ألبوم • $_totalPhotos صورة',
              leading: HeaderBackButton(
                onTap: () => Navigator.of(context).pop(),
              ),
              onSearch: _openSearch,
              onMore: _showMoreSheet,
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
                            'لا توجد ألبومات',
                            style: AppTextStyles.headlineSmall(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'جرّب كلمة بحث أخرى'
                                : 'ابدأ بإنشاء ألبوم جديد',
                            style: AppTextStyles.bodySmall(
                              AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
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
        onPressed: () {
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
                      Icons.add_photo_alternate,
                      color: AppColors.primaryContainer,
                    ),
                    title: const Text('إضافة صورة من المعرض'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.add,
                      color: AppColors.primaryContainer,
                    ),
                    title: const Text('إنشاء ألبوم جديد'),
                    onTap: () {
                      Navigator.pop(context);
                      _createAlbum();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
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

class _AlbumSearchDelegate extends SearchDelegate<String> {
  final ValueChanged<String> onResult;
  final VoidCallback onClear;

  _AlbumSearchDelegate({required this.onResult, required this.onClear});

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
    return const Center(child: Text('ابحث عن اسم الألبوم أو التصنيف'));
  }
}
