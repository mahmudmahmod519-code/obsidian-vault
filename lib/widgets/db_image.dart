import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/gallery_repository.dart';
import '../theme.dart';

/// مخزن مؤقت للصور المحملة من SQLite لتجنب إعادة التحميل
final Map<int, Uint8List> _imageCache = <int, Uint8List>{};

/// يعرض صورة محفوظة داخل SQLite كـ BLOB مع تخزين مؤقت.
class DbImage extends StatefulWidget {
  final int? photoId;
  final BoxFit fit;
  final int? cacheWidth;
  final double? width;
  final double? height;

  const DbImage({
    super.key,
    required this.photoId,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.width,
    this.height,
  });

  @override
  State<DbImage> createState() => _DbImageState();
}

class _DbImageState extends State<DbImage> {
  Future<Uint8List?>? _future;
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoId != widget.photoId) {
      _cachedBytes = null;
      _load();
    }
  }

  void _load() {
    final photoId = widget.photoId;
    if (photoId == null) {
      _future = Future<Uint8List?>.value(null);
      return;
    }

    // استخدم الصورة المخزنة مؤقتاً إذا كانت موجودة
    final cached = _imageCache[photoId];
    if (cached != null) {
      _cachedBytes = cached;
      _future = Future<Uint8List?>.value(cached);
      return;
    }

    _future = GalleryRepository.instance.loadImage(photoId).then((bytes) {
      if (bytes != null && bytes.isNotEmpty) {
        _imageCache[photoId] = bytes;
      }
      return bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    // إذا كانت الصورة مخزنة مؤقتاً، عرضها فوراً دون FutureBuilder
    if (_cachedBytes != null) {
      return Image.memory(
        _cachedBytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        cacheWidth: widget.cacheWidth,
        gaplessPlayback: true,
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: AppColors.surfaceContainerLow,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryContainer),
              ),
            ),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Container(
            color: AppColors.surfaceContainerLow,
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 22,
              color: AppColors.outline,
            ),
          );
        }

        _cachedBytes = bytes;
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          cacheWidth: widget.cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surfaceContainerLow,
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 22,
              color: AppColors.outline,
            ),
          ),
        );
      },
    );
  }
}
