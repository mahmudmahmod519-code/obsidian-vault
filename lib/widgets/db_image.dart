import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/gallery_repository.dart';
import '../theme.dart';

/// يعرض صورة محفوظة داخل SQLite كـ BLOB.
class DbImage extends StatefulWidget {
  final int? photoId;
  final BoxFit fit;
  final int? cacheWidth;

  const DbImage({
    super.key,
    required this.photoId,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  @override
  State<DbImage> createState() => _DbImageState();
}

class _DbImageState extends State<DbImage> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoId != widget.photoId) {
      _load();
    }
  }

  void _load() {
    final photoId = widget.photoId;
    _future = photoId == null
        ? Future<Uint8List?>.value(null)
        : GalleryRepository.instance.loadImage(photoId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PhotoPlaceholder(icon: Icons.image_outlined);
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return const _PhotoPlaceholder(icon: Icons.broken_image_outlined);
        }

        return Image.memory(
          bytes,
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              const _PhotoPlaceholder(icon: Icons.broken_image_outlined),
        );
      },
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final IconData icon;

  const _PhotoPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: AppColors.outline),
    );
  }
}
