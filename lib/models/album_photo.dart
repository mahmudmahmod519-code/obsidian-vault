class AlbumPhoto {
  final String imageUrl;
  final String title;
  final String date;
  final bool isFavorite;

  const AlbumPhoto({
    required this.imageUrl,
    required this.title,
    required this.date,
    this.isFavorite = false,
  });

  AlbumPhoto copyWith({bool? isFavorite}) {
    return AlbumPhoto(
      imageUrl: imageUrl,
      title: title,
      date: date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
