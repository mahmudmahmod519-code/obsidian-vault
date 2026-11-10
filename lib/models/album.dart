class Album {
  final String id;
  final String name;
  final int? coverPhotoId;
  final int photoCount;
  final String category;
  final String dateLabel;
  final bool isLocked;
  final bool isFavorite;

  const Album({
    required this.id,
    required this.name,
    required this.coverPhotoId,
    required this.photoCount,
    this.category = 'الكل',
    this.dateLabel = '',
    this.isLocked = false,
    this.isFavorite = false,
  });
}
