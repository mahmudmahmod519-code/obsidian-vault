import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/gallery_repository.dart';
import '../models/album_photo.dart';
import '../models/viewer_photo.dart';
import '../theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';
import '../widgets/photo_tile.dart';
import 'albums_screen.dart';
import 'favorites_screen.dart';
import 'photo_viewer_screen.dart';
import 'settings_screen.dart';

class HomeGalleryScreen extends StatefulWidget {
  const HomeGalleryScreen({super.key});

  @override
  State<HomeGalleryScreen> createState() => _HomeGalleryScreenState();
}

class _HomeGalleryScreenState extends State<HomeGalleryScreen> {
  List<AlbumPhoto> _photos = [];
  List<AlbumPhoto> _displayedPhotos = [];
  final Set<int> _selected = {};
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  String? _error;
  int _albumCount = 0;
  String _searchQuery = '';

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await GalleryRepository.instance.init();
      final photos = await GalleryRepository.instance.getPhotos();
      final albums = await GalleryRepository.instance.getAlbums();
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _displayedPhotos = photos;
        _albumCount = albums.length;
        _loading = false;
        _error = null;
        _selected.clear();
        _searchQuery = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل الصور من قاعدة البيانات';
      });
    }
  }

  List<AlbumPhoto> _filteredPhotos(String query) {
    if (query.isEmpty) return _photos;
    final q = query.toLowerCase();
    return _photos
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.date.toLowerCase().contains(q),
        )
        .toList();
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: _GallerySearchDelegate(
        onResult: (query) {
          setState(() {
            _searchQuery = query;
            _displayedPhotos = _filteredPhotos(query);
            _selected.clear();
          });
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
            _displayedPhotos = _photos;
            _selected.clear();
          });
        },
      ),
    );
  }

  Future<void> _shareSelected() async {
    if (_selected.isEmpty) return;
    final files = <XFile>[];
    final tempDir = await getTemporaryDirectory();
    for (final index in _selected.toList()) {
      final photo = _photos[index];
      final bytes = await GalleryRepository.instance.loadImage(photo.id);
      if (bytes == null || bytes.isEmpty) continue;
      final file = File('${tempDir.path}/obsidian_${photo.id}.jpg');
      await file.writeAsBytes(bytes);
      files.add(XFile(file.path));
    }
    if (files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: 'تم مشاركة ${files.length} صورة من Obsidian Vault',
        subject: 'Obsidian Vault',
      ),
    );
    if (!mounted) return;
    _clearSelection();
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text('تأكيد الحذف', style: AppTextStyles.headlineSmall()),
        content: Text(
          'هل أنت متأكد أنك تريد حذف $count صورة؟ لا يمكن التراجع عن هذا الإجراء.',
          style: AppTextStyles.bodySmall(AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ids = _selected.map((index) => _photos[index].id).toList();
    await GalleryRepository.instance.deletePhotos(ids);
    await _load();
    if (mounted) showAppToast(context, 'تم حذف $count صورة');
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
              title: const Text('تحديث المعرض'),
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
                showAppToast(context, 'Obsidian Vault - معرض خاص وأوفلاين');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelect(int index) {
    setState(() {
      if (!_selected.add(index)) {
        _selected.remove(index);
      }
    });
  }

  void _startSelection(int index) {
    setState(() => _selected.add(index));
  }

  void _clearSelection() => setState(_selected.clear);

  void _selectAll() {
    setState(() {
      if (_selected.length == _displayedPhotos.length) {
        _selected.clear();
      } else {
        _selected.addAll(List.generate(_displayedPhotos.length, (i) => i));
      }
    });
  }

  Future<void> _handleFavoriteSelection() async {
    if (_selected.isEmpty) return;
    final ids = _selected.map((index) => _photos[index].id).toList();
    await GalleryRepository.instance.setFavorites(ids, true);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    showAppToast(context, 'تمت إضافة ${ids.length} إلى المفضلة');
  }

  Future<void> _openViewer(int index) async {
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

  void _push(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        if (_selectionMode) {
          _clearSelection();
        } else if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        break;
      case 1:
        _push(const AlbumsScreen());
        break;
      case 2:
        _push(const FavoritesScreen());
        break;
      case 3:
        _push(const SettingsScreen());
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectionMode
                  ? _SelectionHeader(
                      key: const ValueKey('selection'),
                      count: _selected.length,
                      total: _displayedPhotos.length,
                      onClose: _clearSelection,
                      onSelectAll: _selectAll,
                    )
                  : AppHeader(
                      key: const ValueKey('normal'),
                      title: 'الصور',
                      subtitle: _loading
                          ? 'جارٍ تحميل الصور...'
                          : '${_displayedPhotos.length} صورة • $_albumCount ألبومات',
                      onSearch: _openSearch,
                      onMore: _showMoreSheet,
                    ),
            ),
            Expanded(child: _buildGallery()),
          ],
        ),
      ),
      bottomNavigationBar: _selectionMode
          ? _SelectionDock(
              onShare: _shareSelected,
              onFavorite: () {
                _handleFavoriteSelection();
              },
              onDelete: _deleteSelected,
            )
          : AppBottomNav(selectedIndex: 0, onTap: _onNavTap),
    );
  }

  Widget _buildGallery() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryContainer),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: AppTextStyles.bodyMedium(AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    if (_displayedPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('لا توجد نتائج', style: AppTextStyles.headlineSmall()),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'جرّب كلمة بحث أخرى'
                  : 'لا توجد صور في المعرض',
              style: AppTextStyles.bodySmall(AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final groups = <String, List<MapEntry<int, AlbumPhoto>>>{};
    for (final entry in _displayedPhotos.asMap().entries) {
      groups.putIfAbsent(entry.value.date, () => []).add(entry);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        for (final group in groups.entries) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: group.key, count: group.value.length),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final entry = group.value[i];
                return PhotoTile(
                  photoId: entry.value.id,
                  favorite: entry.value.isFavorite,
                  selected: _selected.contains(entry.key),
                  borderRadius: BorderRadius.circular(2),
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelect(entry.key);
                    } else {
                      _openViewer(entry.key);
                    }
                  },
                  onLongPress: () => _startSelection(entry.key),
                );
              }, childCount: group.value.length),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.headlineSmall()),
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
            '$count صور',
            style: AppTextStyles.labelMonoSmall(
              AppColors.outline,
            ).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  final int count;
  final int total;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;

  const _SelectionHeader({
    super.key,
    required this.count,
    required this.total,
    required this.onClose,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 22),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                'تم تحديد $count',
                style: AppTextStyles.headlineSmall(),
              ),
            ),
            TextButton(
              onPressed: onSelectAll,
              child: Text(
                count == total ? 'إلغاء الكل' : 'تحديد الكل',
                style: AppTextStyles.bodySmall(AppColors.primaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionDock extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _SelectionDock({
    required this.onShare,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _DockAction(
                icon: Icons.ios_share,
                label: 'مشاركة',
                onTap: onShare,
              ),
              _DockAction(
                icon: Icons.favorite_border,
                label: 'مفضلة',
                onTap: onFavorite,
              ),
              _DockAction(
                icon: Icons.delete_outline,
                label: 'حذف',
                color: AppColors.error,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GallerySearchDelegate extends SearchDelegate<String> {
  final ValueChanged<String> onResult;
  final VoidCallback onClear;

  _GallerySearchDelegate({required this.onResult, required this.onClear});

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
    return const Center(child: Text('ابحث عن عنوان الصورة أو التاريخ'));
  }
}

class _DockAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DockAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effective = color ?? AppColors.onSurface;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: effective),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMonoSmall(
                effective,
              ).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
