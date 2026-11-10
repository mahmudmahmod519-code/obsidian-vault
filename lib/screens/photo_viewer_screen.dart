import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/gallery_repository.dart';
import '../models/viewer_photo.dart';
import '../theme.dart';
import '../widgets/db_image.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<ViewerPhoto> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pageController;
  late final List<ViewerPhoto> _photos;
  late int _currentIndex;

  final TransformationController _transformController =
      TransformationController();
  double _zoom = 1.0;
  Offset _doubleTapPosition = Offset.zero;

  bool _chromeVisible = true;
  bool _exifOpen = false;

  bool _isDragging = false;
  double _dragOffset = 0;

  String _toastMessage = '';
  bool _toastVisible = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.photos);
    _currentIndex = _photos.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _zoom).abs() > 0.05) {
      setState(() => _zoom = scale);
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  ViewerPhoto get _currentPhoto => _photos[_currentIndex];

  void _goTo(int index) {
    if (_photos.isEmpty) return;
    final target = (index + _photos.length) % _photos.length;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _toggleZoom() {
    if (_zoom > 1.01) {
      _transformController.value = Matrix4.identity();
      return;
    }

    const targetScale = 2.2;
    final size = MediaQuery.of(context).size;
    final focal = _doubleTapPosition == Offset.zero
        ? Offset(size.width / 2, size.height / 2)
        : _doubleTapPosition;

    final x = -focal.dx * (targetScale - 1);
    final y = -focal.dy * (targetScale - 1);

    _transformController.value = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setEntry(0, 3, x)
      ..setEntry(1, 3, y);

    _showToast('Magnified ${targetScale.toStringAsFixed(1)}x');
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  Future<void> _toggleFavorite() async {
    final index = _currentIndex;
    final photo = _photos[index];
    final next = !photo.isFavorite;

    try {
      await GalleryRepository.instance.setFavorite(photo.photoId, next);
    } catch (_) {
      if (mounted) _showToast('Could not update favorite');
      return;
    }

    if (!mounted) return;
    setState(() {
      _photos[index] = photo.copyWith(isFavorite: next);
    });

    _showToast(next ? 'Marked as Favorite' : 'Removed from Favorites');
  }

  Future<void> _shareCurrent() async {
    final photo = _photos[_currentIndex];
    final bytes = await GalleryRepository.instance.loadImage(photo.photoId);
    if (bytes == null || bytes.isEmpty) {
      if (mounted) _showToast('لا يمكن مشاركة الصورة');
      return;
    }
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/obsidian_${photo.photoId}.jpg');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'صورة من Obsidian Vault',
        subject: 'Obsidian Vault',
      ),
    );
    if (!mounted) return;
    _showToast('تمت مشاركة الصورة');
  }

  Future<void> _deleteCurrent() async {
    final photo = _photos[_currentIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف هذه الصورة؟ لا يمكن التراجع عن هذا الإجراء.',
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

    await GalleryRepository.instance.deletePhoto(photo.photoId);
    _photos.removeAt(_currentIndex);
    if (_photos.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _currentIndex = _currentIndex.clamp(0, _photos.length - 1);
    _pageController.jumpToPage(_currentIndex);
    setState(() {});
    _showToast('تم حذف الصورة');
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
                Icons.info_outline,
                color: AppColors.primaryContainer,
              ),
              title: const Text('معلومات الصورة'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _exifOpen = true);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.refresh,
                color: AppColors.primaryContainer,
              ),
              title: const Text('تحديث العرض'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _transformController.value = Matrix4.identity();
                  _zoom = 1.0;
                });
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showTuneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('تعديل الألوان'),
        content: const Text(
          'هذه النسخة مخصصة للاستخدام الشخصي. أدوات تعديل الألوان والفلاتر ستكون متاحة في التحديث القادم.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onVerticalDragStart: _zoom > 1.01
                    ? null
                    : (_) => setState(() => _isDragging = true),
                onVerticalDragUpdate: _zoom > 1.01
                    ? null
                    : (details) {
                        setState(() {
                          _dragOffset = (_dragOffset + details.delta.dy).clamp(
                            0.0,
                            300.0,
                          );
                        });
                      },
                onVerticalDragCancel: _zoom > 1.01
                    ? null
                    : () => setState(() {
                        _isDragging = false;
                        _dragOffset = 0;
                      }),
                onVerticalDragEnd: _zoom > 1.01
                    ? null
                    : (_) {
                        setState(() => _isDragging = false);
                        if (_dragOffset > 120) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _dragOffset = 0);
                        }
                      },
                child: AnimatedSlide(
                  offset: Offset(0, _dragOffset / screenHeight),
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: 1 - (_dragOffset / 3000).clamp(0.0, 0.1),
                    duration: _isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _zoom > 1.01
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                          _transformController.value = Matrix4.identity();
                          _zoom = 1.0;
                        });
                      },
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: _toggleChrome,
                          onDoubleTapDown: (details) {
                            _doubleTapPosition = details.localPosition;
                          },
                          onDoubleTap: _toggleZoom,
                          child: InteractiveViewer(
                            transformationController: index == _currentIndex
                                ? _transformController
                                : null,
                            panEnabled: index == _currentIndex && _zoom > 1.01,
                            minScale: 1,
                            maxScale: 4,
                            child: Center(child: _buildImage(_photos[index])),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (_chromeVisible) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _edgeButton(
                    Icons.chevron_left,
                    () => _goTo(_currentIndex - 1),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _edgeButton(
                    Icons.chevron_right,
                    () => _goTo(_currentIndex + 1),
                  ),
                ),
              ),
            ],
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: AnimatedOpacity(
                  opacity: _chromeVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const Spacer(),
                      _buildBottomChrome(),
                    ],
                  ),
                ),
              ),
            ),
            _buildExifSheet(),
            _buildToast(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ViewerPhoto photo) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.05),
                blurRadius: 80,
                spreadRadius: 40,
              ),
            ],
          ),
        ),
        DbImage(photoId: photo.photoId, fit: BoxFit.contain, cacheWidth: 1800),
      ],
    );
  }

  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding: EdgeInsets.only(
            top: topInset + 8,
            bottom: 24,
            left: 12,
            right: 12,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xE6000000),
                Color(0x80000000),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _chromeCircleButton(
                    Icons.arrow_back,
                    () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow.withValues(
                        alpha: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 14,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AES-256',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontFamilyFallback: const ['NotoSansArabic'],
                            fontSize: 11,
                            letterSpacing: 0.08,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${(_currentIndex + 1).toString().padLeft(2, '0')} / ${_photos.length.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontFamilyFallback: const ['NotoSansArabic'],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _currentPhoto.timestamp,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontFamilyFallback: const ['NotoSansArabic'],
                        fontSize: 10,
                        letterSpacing: 0.08,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _toggleZoom,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow.withValues(
                          alpha: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _zoom > 1.01 ? Icons.zoom_out : Icons.zoom_in,
                            size: 15,
                            color: AppColors.primaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_zoom.toStringAsFixed(1)}x',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontFamilyFallback: const ['NotoSansArabic'],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _chromeCircleButton(Icons.more_vert, _showMoreSheet),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chromeCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.onSurface),
      ),
    );
  }

  Widget _edgeButton(IconData icon, VoidCallback onTap) {
    return Opacity(
      opacity: 0.6,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.secondary),
        ),
      ),
    );
  }

  Widget _buildBottomChrome() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        bottom: bottomInset + 16,
        top: 24,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE6000000), Color(0x80000000), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _exifOpen = true),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_camera,
                        size: 15,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _currentPhoto.exif,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontFamilyFallback: const ['NotoSansArabic'],
                            fontSize: 11,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_photos.length, (index) {
                final isActive = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryContainer
                        : AppColors.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.85),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dockButton(
                        _currentPhoto.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        _currentPhoto.isFavorite
                            ? AppColors.primaryContainer
                            : AppColors.secondary,
                        _toggleFavorite,
                      ),
                      _dockButton(
                        Icons.tune,
                        AppColors.secondary,
                        _showTuneDialog,
                      ),
                      _dockButton(
                        Icons.share,
                        AppColors.secondary,
                        _shareCurrent,
                      ),
                      _dockButton(
                        Icons.delete,
                        AppColors.secondary,
                        _deleteCurrent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dockButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  Widget _buildExifSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        ignoring: !_exifOpen,
        child: AnimatedSlide(
          offset: _exifOpen ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.95),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _exifOpen = false),
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.dataset,
                            size: 18,
                            color: AppColors.primaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Digital Provenance & Metadata',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontFamilyFallback: const ['NotoSansArabic'],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _exifOpen = false),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _exifCard(
                              'Shutter • Aperture',
                              _currentPhoto.shutterAperture,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _exifCard(
                              'Focal Length • ISO',
                              _currentPhoto.focalIso,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _exifCard(
                              'Lens Glass',
                              _currentPhoto.lens,
                              mono: false,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _exifCard(
                              'Resolution',
                              _currentPhoto.resolution,
                              mono: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SHA-256 VAULT HASH',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontFamilyFallback: const [
                                      'NotoSansArabic',
                                    ],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.08,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                                const Icon(
                                  Icons.verified_user,
                                  size: 14,
                                  color: AppColors.primaryContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              _currentPhoto.hash,
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontFamilyFallback: const ['NotoSansArabic'],
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _exifCard(String label, String value, {bool mono = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontFamilyFallback: const ['NotoSansArabic'],
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: mono
                ? TextStyle(
                    fontFamily: 'SpaceMono',
                    fontFamilyFallback: const ['NotoSansArabic'],
                    fontSize: 14,
                    color: AppColors.primary,
                  )
                : TextStyle(
                    fontFamily: 'NotoSans',
                    fontFamilyFallback: const ['NotoSansArabic'],
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToast() {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topInset + 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            opacity: _toastVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _toastMessage.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontFamilyFallback: const ['NotoSansArabic'],
                          fontSize: 11,
                          letterSpacing: 0.08,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
