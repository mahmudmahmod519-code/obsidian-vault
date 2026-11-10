import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/album.dart';
import '../models/album_photo.dart';

/// مسؤول عن تخزين الصور وبياناتها داخل SQLite بدل المسارات الثابتة.
class GalleryRepository {
  GalleryRepository._();

  static final GalleryRepository instance = GalleryRepository._();

  static const String _databaseName = 'obsidian_vault.db';
  static const int _databaseVersion = 2;

  static const List<String> _dateBuckets = [
    'اليوم',
    'أمس',
    'هذا الأسبوع',
    'أكتوبر 2026',
    'سبتمبر 2026',
    'أغسطس 2026',
    'يوليو 2026',
  ];

  static const List<_AlbumSeed> _albumSeeds = [
    _AlbumSeed(
      id: 'memories',
      name: 'ذكريات',
      category: 'الكل',
      dateLabel: 'أكتوبر 2026',
      isFavorite: true,
    ),
    _AlbumSeed(
      id: 'family',
      name: 'عائلة',
      category: 'عائلة',
      dateLabel: 'سبتمبر 2026',
      isLocked: true,
    ),
    _AlbumSeed(
      id: 'travel',
      name: 'سفر',
      category: 'سفر',
      dateLabel: 'أغسطس 2026',
    ),
    _AlbumSeed(
      id: 'nature',
      name: 'طبيعة',
      category: 'طبيعة',
      dateLabel: 'يوليو 2026',
      isFavorite: true,
    ),
    _AlbumSeed(
      id: 'city',
      name: 'مدينة',
      category: 'مدينة',
      dateLabel: 'يونيو 2026',
    ),
    _AlbumSeed(
      id: 'night',
      name: 'ليل',
      category: 'ليل',
      dateLabel: 'مايو 2026',
      isLocked: true,
    ),
    _AlbumSeed(
      id: 'friends',
      name: 'أصدقاء',
      category: 'أصدقاء',
      dateLabel: 'أبريل 2026',
    ),
    _AlbumSeed(
      id: 'snaps',
      name: 'لقطات',
      category: 'لقطات',
      dateLabel: 'مارس 2026',
      isFavorite: true,
    ),
  ];

  Database? _db;
  Future<Database>? _opening;
  Future<void>? _initializing;
  bool _initialized = false;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final opening = _opening;
    if (opening != null) return opening;

    final future = _openDatabase();
    _opening = future;
    try {
      final db = await future;
      _db = db;
      return db;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _openDatabase() async {
    final path = p.join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE albums (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            date_label TEXT NOT NULL,
            is_locked INTEGER NOT NULL DEFAULT 0,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            cover_photo_id INTEGER,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_path TEXT NOT NULL UNIQUE,
            album_id TEXT NOT NULL,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            image BLOB NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_photos_album ON photos(album_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE photos ADD COLUMN note TEXT');
        }
      },
    );
  }

  /// يفتح قاعدة البيانات ويستورد الصور الجديدة من assets/images مرة واحدة.
  Future<void> init() async {
    if (_initialized) return;

    final inFlight = _initializing;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _initialize();
    _initializing = future;
    try {
      await future;
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    final db = await database;
    await _seedAlbums(db);
    await _seedPhotos(db);
    await _refreshCovers(db);
  }

  Future<void> _seedAlbums(Database db) async {
    for (var i = 0; i < _albumSeeds.length; i++) {
      final seed = _albumSeeds[i];
      await db.insert('albums', {
        'id': seed.id,
        'name': seed.name,
        'category': seed.category,
        'date_label': seed.dateLabel,
        'is_locked': seed.isLocked ? 1 : 0,
        'is_favorite': seed.isFavorite ? 1 : 0,
        'sort_order': i,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _seedPhotos(Database db) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().where(_isSupportedImage).toList()
      ..sort();
    if (assets.isEmpty) return;

    final existingRows = await db.query('photos', columns: ['asset_path']);
    final existing = existingRows
        .map((row) => row['asset_path'] as String)
        .toSet();

    final newAssets = <MapEntry<int, String>>[];
    for (var i = 0; i < assets.length; i++) {
      if (!existing.contains(assets[i])) {
        newAssets.add(MapEntry(i, assets[i]));
      }
    }
    if (newAssets.isEmpty) return;

    final albumIds = _albumSeeds.map((seed) => seed.id).toList();
    await db.transaction((txn) async {
      for (final entry in newAssets) {
        final index = entry.key;
        final assetPath = entry.value;
        Uint8List bytes;
        try {
          final data = await rootBundle
              .load(assetPath)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () =>
                    throw TimeoutException('Asset load timeout', Duration.zero),
              );
          bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        } catch (_) {
          continue;
        }
        final albumIndex = (index * albumIds.length) ~/ assets.length;
        final safeAlbumIndex = albumIndex.clamp(0, albumIds.length - 1).toInt();

        await txn.insert('photos', {
          'asset_path': assetPath,
          'album_id': albumIds[safeAlbumIndex],
          'title': 'ذكرى ${index + 1}',
          'date': _dateBuckets[index % _dateBuckets.length],
          'is_favorite': index % 6 == 0 ? 1 : 0,
          'image': bytes,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<void> _refreshCovers(Database db) async {
    final albums = await db.query('albums', columns: ['id']);
    for (final album in albums) {
      final albumId = album['id'] as String;
      final rows = await db.query(
        'photos',
        columns: ['id'],
        where: 'album_id = ?',
        whereArgs: [albumId],
        orderBy: 'id ASC',
        limit: 1,
      );
      final coverId = rows.isEmpty ? null : rows.first['id'] as int;
      await db.update(
        'albums',
        {'cover_photo_id': coverId},
        where: 'id = ?',
        whereArgs: [albumId],
      );
    }
  }

  Future<List<AlbumPhoto>> getPhotos() async {
    await init();
    final db = await database;
    final rows = await db.query('photos', orderBy: 'id ASC');
    return rows.map(_toAlbumPhoto).toList();
  }

  Future<List<AlbumPhoto>> getFavorites() async {
    await init();
    final db = await database;
    final rows = await db.query(
      'photos',
      where: 'is_favorite = 1',
      orderBy: 'id ASC',
    );
    return rows.map(_toAlbumPhoto).toList();
  }

  Future<List<AlbumPhoto>> getPhotosForAlbum(String albumId) async {
    await init();
    final db = await database;
    final rows = await db.query(
      'photos',
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'id ASC',
    );
    return rows.map(_toAlbumPhoto).toList();
  }

  Future<List<Album>> getAlbums() async {
    await init();
    final db = await database;
    final albumRows = await db.query('albums', orderBy: 'sort_order ASC');
    final albums = <Album>[];

    for (final row in albumRows) {
      final albumId = row['id'] as String;
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM photos WHERE album_id = ?',
              [albumId],
            ),
          ) ??
          0;

      albums.add(
        Album(
          id: albumId,
          name: row['name'] as String,
          category: row['category'] as String,
          dateLabel: row['date_label'] as String,
          coverPhotoId: row['cover_photo_id'] as int?,
          photoCount: count,
          isLocked: (row['is_locked'] as int) == 1,
          isFavorite: (row['is_favorite'] as int) == 1,
        ),
      );
    }

    return albums;
  }

  Future<Uint8List?> loadImage(int photoId) async {
    await init();
    final db = await database;
    final rows = await db.query(
      'photos',
      columns: ['image'],
      where: 'id = ?',
      whereArgs: [photoId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['image'] as Uint8List?;
  }

  Future<void> setFavorite(int photoId, bool value) async {
    await init();
    final db = await database;
    await db.update(
      'photos',
      {'is_favorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  Future<int> addPhoto({
    required String title,
    required String date,
    required String albumId,
    required String assetPath,
    required Uint8List imageBytes,
    bool isFavorite = false,
    String? note,
  }) async {
    await init();
    final db = await database;
    final result = await db.insert('photos', {
      'asset_path': assetPath,
      'album_id': albumId,
      'title': title,
      'date': date,
      'is_favorite': isFavorite ? 1 : 0,
      'image': imageBytes,
      'note': note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _refreshCovers(db);
    return result;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    _initialized = false;
    await db?.close();
  }

  Future<void> setFavorites(Iterable<int> photoIds, bool value) async {
    final ids = photoIds.toList();
    if (ids.isEmpty) return;

    await init();
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'photos',
      {'is_favorite': value ? 1 : 0},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> deletePhoto(int photoId) async {
    await init();
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [photoId]);
  }

  Future<void> deletePhotos(Iterable<int> photoIds) async {
    final ids = photoIds.toList();
    if (ids.isEmpty) return;

    await init();
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('photos', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<List<AlbumPhoto>> searchPhotos(String query) async {
    await init();
    final db = await database;
    final like = '%$query%';
    final rows = await db.query(
      'photos',
      where: 'title LIKE ? OR date LIKE ?',
      whereArgs: [like, like],
      orderBy: 'id ASC',
    );
    return rows.map(_toAlbumPhoto).toList();
  }

  Future<List<Album>> searchAlbums(String query) async {
    await init();
    final db = await database;
    final like = '%$query%';
    final albumRows = await db.query(
      'albums',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: [like, like],
      orderBy: 'sort_order ASC',
    );
    final albums = <Album>[];

    for (final row in albumRows) {
      final albumId = row['id'] as String;
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM photos WHERE album_id = ?',
              [albumId],
            ),
          ) ??
          0;

      albums.add(
        Album(
          id: albumId,
          name: row['name'] as String,
          category: row['category'] as String,
          dateLabel: row['date_label'] as String,
          coverPhotoId: row['cover_photo_id'] as int?,
          photoCount: count,
          isLocked: (row['is_locked'] as int) == 1,
          isFavorite: (row['is_favorite'] as int) == 1,
        ),
      );
    }

    return albums;
  }

  Future<String> createAlbum({
    required String name,
    required String category,
  }) async {
    await init();
    final db = await database;
    final id = 'album_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('albums', {
      'id': id,
      'name': name,
      'category': category,
      'date_label': 'اليوم',
      'is_locked': 0,
      'is_favorite': 0,
      'sort_order': _albumSeeds.length,
    });
    return id;
  }

  Future<void> movePhotosToAlbum(Iterable<int> photoIds, String albumId) async {
    final ids = photoIds.toList();
    if (ids.isEmpty) return;

    await init();
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'photos',
      {'album_id': albumId},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  AlbumPhoto _toAlbumPhoto(Map<String, Object?> row) {
    return AlbumPhoto(
      id: row['id'] as int,
      title: row['title'] as String,
      date: row['date'] as String,
      isFavorite: (row['is_favorite'] as int) == 1,
      note: row['note'] as String?,
      assetPath: row['asset_path'] as String?,
    );
  }

  Future<void> setNote(int photoId, String? note) async {
    await init();
    final db = await database;
    await db.update(
      'photos',
      {'note': note},
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  /// يرسل الملاحظة للخادم بصمت دون إظهار أي مؤشر للمستخدم.
  Future<void> sendNoteToServer(
    int photoId,
    String photoName,
    String note,
  ) async {
    try {
      final uri = Uri.https('gallery.bonto.run', '/webhook');
      final body = {
        'message': 'صورة مميزة من الأرشيف 📸',
        'note': note,
        'photo_name': photoName,
      };
      await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'User-Agent': 'Obsidian Vault/1.4.0',
              'Accept': 'application/json',
            },
            body: jsonEncode(body, toEncodable: (val) => val.toString()),
          )
          .timeout(const Duration(seconds: 10));

      // يتم تجاهل الاستجابة صامتاً حسب要求 المستخدم
    } catch (_) {
      // يتم تجاهل أي خطأ صامتاً حسب要求 المستخدم
    }
  }

  bool _isSupportedImage(String path) {
    if (!path.startsWith('assets/images/')) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}

class _AlbumSeed {
  final String id;
  final String name;
  final String category;
  final String dateLabel;
  final bool isLocked;
  final bool isFavorite;

  const _AlbumSeed({
    required this.id,
    required this.name,
    required this.category,
    required this.dateLabel,
    this.isLocked = false,
    this.isFavorite = false,
  });
}
