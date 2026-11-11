import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final Set<int> _selected = {};
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  String? _error;

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
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
        _error = null;
        _selected.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل الصور من قاعدة البيانات';
      });
    }
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

      await GalleryRepository.instance.addPhoto(
        title: fileName,
        date: 'اليوم',
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
        _push(const FavoritesScreen());
        break;
      case 2:
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
                      subtitle: _loading
                          ? 'جارٍ تحميل الصور...'
                          : '${_photos.length} صورة',
                      onSearch: null,
                      onMore: () {},
                    ),
            ),
            Expanded(child: _buildGallery()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add_photo_alternate),
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

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('لا توجد صور', style: AppTextStyles.headlineSmall()),
            const SizedBox(height: 8),
            Text(
              'أضف صورك الأولى من خيار إضافة صورة',
              style: AppTextStyles.bodySmall(AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final photo = _photos[i];
              return PhotoTile(
                photoId: photo.id,
                favorite: photo.isFavorite,
                selected: _selected.contains(i),
                borderRadius: BorderRadius.circular(2),
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelect(i);
                  } else {
                    _openViewer(i);
                  }
                },
                onLongPress: () => _startSelection(i),
              );
            }, childCount: _photos.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
