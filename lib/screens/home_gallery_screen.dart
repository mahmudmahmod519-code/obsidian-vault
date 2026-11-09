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
import 'favorites_screen.dart';
import 'photo_viewer_screen.dart';
import 'settings_screen.dart';

class HomeGalleryScreen extends StatefulWidget {
  const HomeGalleryScreen({super.key});

  @override
  State<HomeGalleryScreen> createState() => _HomeGalleryScreenState();
}

class _HomeGalleryScreenState extends State<HomeGalleryScreen> {
  final List<AlbumPhoto> _photos = List.of(demoPhotos);
  final Set<int> _selected = {};
  final ScrollController _scrollController = ScrollController();

  bool get _selectionMode => _selected.isNotEmpty;

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
      if (_selected.length == _photos.length) {
        _selected.clear();
      } else {
        _selected.addAll(List.generate(_photos.length, (i) => i));
      }
    });
  }

  void _handleAction(String label) {
    if (_selected.isEmpty) return;
    showAppToast(context, '$label ${_selected.length} عنصر');
    _clearSelection();
  }

  void _openViewer(int index) {
    final photos = _photos
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
                      total: _photos.length,
                      onClose: _clearSelection,
                      onSelectAll: _selectAll,
                    )
                  : AppHeader(
                      key: const ValueKey('normal'),
                      title: 'الصور',
                      subtitle: '${_photos.length} صورة • ${demoAlbums.length} ألبومات',
                      onSearch: () => showAppToast(context, 'البحث قريبًا'),
                      onMore: () => showAppToast(context, 'خيارات إضافية'),
                    ),
            ),
            Expanded(child: _buildGallery()),
          ],
        ),
      ),
      bottomNavigationBar: _selectionMode
          ? _SelectionDock(
              onShare: () => _handleAction('تمت مشاركة'),
              onFavorite: () => _handleAction('تمت إضافة'),
              onDelete: () => _handleAction('تم حذف'),
            )
          : AppBottomNav(selectedIndex: 0, onTap: _onNavTap),
    );
  }

  Widget _buildGallery() {
    final groups = <String, List<MapEntry<int, AlbumPhoto>>>{};
    for (final entry in _photos.asMap().entries) {
      groups.putIfAbsent(entry.value.date, () => []).add(entry);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        for (final group in groups.entries) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: group.key,
              count: group.value.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final entry = group.value[i];
                  return PhotoTile(
                    imageUrl: entry.value.imageUrl,
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
                },
                childCount: group.value.length,
              ),
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
            style: AppTextStyles.labelMonoSmall(AppColors.outline)
                .copyWith(fontSize: 10),
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
              style: AppTextStyles.labelMonoSmall(effective)
                  .copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
