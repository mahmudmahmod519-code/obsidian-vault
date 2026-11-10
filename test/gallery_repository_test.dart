import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_vault/data/gallery_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String databasePath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databasePath = p.join(await getDatabasesPath(), 'obsidian_vault.db');
    final file = File(databasePath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  tearDownAll(() async {
    await GalleryRepository.instance.close();
    final file = File(databasePath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  test('imports asset images into SQLite and reads them back', () async {
    await GalleryRepository.instance.init();

    final photos = await GalleryRepository.instance.getPhotos();
    expect(photos.length, 62);
    expect(photos.first.id, greaterThan(0));

    final albums = await GalleryRepository.instance.getAlbums();
    expect(albums.length, 8);
    expect(albums.every((album) => album.photoCount > 0), isTrue);
    expect(albums.every((album) => album.coverPhotoId != null), isTrue);

    final favorites = await GalleryRepository.instance.getFavorites();
    expect(favorites, isNotEmpty);

    final image = await GalleryRepository.instance.loadImage(photos.first.id);
    expect(image, isNotNull);
    expect(image!.length, greaterThan(1000));

    final albumPhotos = await GalleryRepository.instance.getPhotosForAlbum(
      albums.first.id,
    );
    expect(albumPhotos, isNotEmpty);

    await GalleryRepository.instance.setFavorite(photos.first.id, true);
    final updated = await GalleryRepository.instance.getFavorites();
    expect(updated.any((photo) => photo.id == photos.first.id), isTrue);
  });
}
