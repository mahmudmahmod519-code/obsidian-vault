class AlbumPhoto {
  final int id;
  final String title;
  final String date;
  final bool isFavorite;

  const AlbumPhoto({
    required this.id,
    required this.title,
    required this.date,
    this.isFavorite = false,
  });

  AlbumPhoto copyWith({bool? isFavorite}) {
    return AlbumPhoto(
      id: id,
      title: title,
      date: date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
