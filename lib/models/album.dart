class Album {
  final String id;
  final String name;
  final String coverImage;
  final List<String> photos;
  final String category;
  final String dateLabel;
  final bool isLocked;
  final bool isFavorite;

  const Album({
    required this.id,
    required this.name,
    required this.coverImage,
    required this.photos,
    this.category = 'الكل',
    this.dateLabel = '',
    this.isLocked = false,
    this.isFavorite = false,
  });

  int get photoCount => photos.length;
}
