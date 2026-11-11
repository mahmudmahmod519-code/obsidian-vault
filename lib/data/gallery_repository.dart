import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/album_photo.dart';

/// مسؤول عن تخزين الصور وبياناتها داخل SQLite بدل المسارات الثابتة.
class GalleryRepository {
  GalleryRepository._();

  static final GalleryRepository instance = GalleryRepository._();

  static const String _databaseName = 'obsidian_vault.db';
  static const int _databaseVersion = 3;

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
          CREATE TABLE photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_path TEXT NOT NULL UNIQUE,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            image BLOB NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS albums');
          await db.execute('ALTER TABLE photos DROP COLUMN album_id');
        }
      },
    );
  }

  /// يفتح قاعدة البيانات ويستورد الصور من assets/images مرة واحدة فقط.
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
    await _seedPhotos(db);
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

        await txn.insert('photos', {
          'asset_path': assetPath,
          'title': 'صورة ${index + 1}',
          'date': 'اليوم',
          'is_favorite': index % 6 == 0 ? 1 : 0,
          'image': bytes,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<List<AlbumPhoto>> getPhotos() async {
    await init();
    final db = await database;
    final rows = await db.query('photos', orderBy: 'id DESC');
    return rows.map(_toAlbumPhoto).toList();
  }

  Future<List<AlbumPhoto>> getFavorites() async {
    await init();
    final db = await database;
    final rows = await db.query(
      'photos',
      where: 'is_favorite = 1',
      orderBy: 'id DESC',
    );
    return rows.map(_toAlbumPhoto).toList();
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
    required String assetPath,
    required Uint8List imageBytes,
    bool isFavorite = false,
    String? note,
  }) async {
    await init();
    final db = await database;
    final result = await db.insert('photos', {
      'asset_path': assetPath,
      'title': title,
      'date': date,
      'is_favorite': isFavorite ? 1 : 0,
      'image': imageBytes,
      'note': note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
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
              'User-Agent': 'Obsidian Vault/1.4.1',
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

  bool _isSupportedImage(String path) {
    if (!path.startsWith('assets/images/')) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}
