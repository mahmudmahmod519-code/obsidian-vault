import '../models/album.dart';
import '../models/album_photo.dart';

/// جميع الصور المحلية المرفقة مع التطبيق.
const List<String> _imageAssets = [
  "assets/images/473224271_580251011518346_3843995772034379473_n.jpg",
  "assets/images/FB_IMG_1732380331760.jpg",
  "assets/images/FB_IMG_1732380342375.jpg",
  "assets/images/IMG-20231216-WA0002.jpg",
  "assets/images/IMG-20231216-WA0010.jpg",
  "assets/images/IMG-20231216-WA0014.jpg",
  "assets/images/IMG-20231216-WA0015.jpg",
  "assets/images/IMG-20240204-WA0004.jpg",
  "assets/images/IMG-20240229-WA0015.jpg",
  "assets/images/IMG-20240303-WA0005.jpg",
  "assets/images/IMG-20240303-WA0006.jpg",
  "assets/images/IMG-20241113-WA0014.jpg",
  "assets/images/IMG-20241113-WA0015.jpg",
  "assets/images/IMG-20241123-WA0074.jpg",
  "assets/images/IMG-20241123-WA0173.jpg",
  "assets/images/IMG-20250327-WA0001.jpg",
  "assets/images/IMG-20250511-WA0081.jpg",
  "assets/images/IMG-20250911-WA0001.jpg",
  "assets/images/IMG-20250925-WA0013.jpg",
  "assets/images/IMG_20250308_193932.jpg",
  "assets/images/IMG_20250502_061213.jpg",
  "assets/images/IMG_20250502_062602.jpg",
  "assets/images/IMG_20250502_062603.jpg",
  "assets/images/IMG_20250502_062721.jpg",
  "assets/images/IMG_20250502_062724.jpg",
  "assets/images/IMG_20250502_062801.jpg",
  "assets/images/IMG_20250502_090133.jpg",
  "assets/images/IMG_20250523_161424.jpg",
  "assets/images/IMG_20250701_205139.jpg",
  "assets/images/IMG_20250701_232024.jpg",
  "assets/images/IMG_20250729_203608.jpg",
  "assets/images/IMG_20250805_205209.jpg",
  "assets/images/IMG_20250810_202249.jpg",
  "assets/images/IMG_20250813_203618.jpg",
  "assets/images/IMG_20250813_203624.jpg",
  "assets/images/IMG_20250822_184140.jpg",
  "assets/images/IMG_20250824_123733.jpg",
  "assets/images/IMG_20250824_180257.jpg",
  "assets/images/IMG_20250916_140843.jpg",
  "assets/images/IMG_20251129_144040.jpg",
  "assets/images/IMG_20251129_144751.jpg",
  "assets/images/IMG_20251129_145200.jpg",
  "assets/images/IMG_20251129_145604.jpg",
  "assets/images/IMG_20251129_150032.jpg",
  "assets/images/IMG_20251129_150219.jpg",
  "assets/images/IMG_20251129_214001.jpg",
  "assets/images/IMG_20251214_002926.jpg",
  "assets/images/IMG_20251219_161948.jpg",
  "assets/images/IMG_20260413_150455.jpg",
  "assets/images/IMG_20260413_173915.jpg",
  "assets/images/IMG_20260502_062803.jpg",
  "assets/images/IMG_20260502_063510.jpg",
  "assets/images/IMG_20260504_091416.jpg",
  "assets/images/IMG_20260626_064126.jpg",
  "assets/images/IMG_20260702_141717.jpg",
  "assets/images/IMG_20260702_141910.jpg",
  "assets/images/IMG_20260702_142137.jpg",
  "assets/images/IMG_20260702_142324.jpg",
  "assets/images/IMG_20260704_180808.jpg",
  "assets/images/IMG_2771.jpg",
  "assets/images/IMG_2789.jpg",
  "assets/images/Picsart_23-11-21_14-38-38-972.jpg",
];

const List<String> _dateBuckets = [
  'اليوم',
  'أمس',
  'هذا الأسبوع',
  'أكتوبر 2026',
  'سبتمبر 2026',
  'أغسطس 2026',
  'يوليو 2026',
];

final List<AlbumPhoto> demoPhotos = List<AlbumPhoto>.generate(
  _imageAssets.length,
  (index) => AlbumPhoto(
    imageUrl: _imageAssets[index],
    title: 'ذكرى ${index + 1}',
    date: _dateBuckets[index % _dateBuckets.length],
    isFavorite: index % 6 == 0,
  ),
);

String _photo(int index) => _imageAssets[index];

List<String> _slice(int start, int end) {
  final safeStart = start.clamp(0, _imageAssets.length).toInt();
  final safeEnd = end.clamp(safeStart, _imageAssets.length).toInt();
  return _imageAssets.sublist(safeStart, safeEnd);
}

final List<Album> demoAlbums = [
  Album(
    id: 'memories',
    name: 'ذكريات',
    coverImage: _photo(0),
    photos: _slice(0, 8),
    category: 'الكل',
    dateLabel: 'أكتوبر 2026',
    isFavorite: true,
  ),
  Album(
    id: 'family',
    name: 'عائلة',
    coverImage: _photo(8),
    photos: _slice(8, 16),
    category: 'عائلة',
    dateLabel: 'سبتمبر 2026',
    isLocked: true,
  ),
  Album(
    id: 'travel',
    name: 'سفر',
    coverImage: _photo(16),
    photos: _slice(16, 24),
    category: 'سفر',
    dateLabel: 'أغسطس 2026',
  ),
  Album(
    id: 'nature',
    name: 'طبيعة',
    coverImage: _photo(24),
    photos: _slice(24, 32),
    category: 'طبيعة',
    dateLabel: 'يوليو 2026',
    isFavorite: true,
  ),
  Album(
    id: 'city',
    name: 'مدينة',
    coverImage: _photo(32),
    photos: _slice(32, 40),
    category: 'مدينة',
    dateLabel: 'يونيو 2026',
  ),
  Album(
    id: 'night',
    name: 'ليل',
    coverImage: _photo(40),
    photos: _slice(40, 48),
    category: 'ليل',
    dateLabel: 'مايو 2026',
    isLocked: true,
  ),
  Album(
    id: 'friends',
    name: 'أصدقاء',
    coverImage: _photo(48),
    photos: _slice(48, 56),
    category: 'أصدقاء',
    dateLabel: 'أبريل 2026',
  ),
  Album(
    id: 'snaps',
    name: 'لقطات',
    coverImage: _photo(56),
    photos: _slice(56, 62),
    category: 'لقطات',
    dateLabel: 'مارس 2026',
    isFavorite: true,
  ),
];

const List<String> albumCategories = [
  'الكل',
  'عائلة',
  'سفر',
  'طبيعة',
  'مدينة',
  'ليل',
  'أصدقاء',
  'لقطات',
];
