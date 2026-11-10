class AlbumPhoto {
  final int id;
  final String title;
  final String date;
  final bool isFavorite;
  final String? note;
  final String? assetPath;

  const AlbumPhoto({
    required this.id,
    required this.title,
    required this.date,
    this.isFavorite = false,
    this.note,
    this.assetPath,
  });

  AlbumPhoto copyWith({bool? isFavorite, String? note, String? assetPath}) {
    return AlbumPhoto(
      id: id,
      title: title,
      date: date,
      isFavorite: isFavorite ?? this.isFavorite,
      note: note ?? this.note,
      assetPath: assetPath ?? this.assetPath,
    );
  }
}
