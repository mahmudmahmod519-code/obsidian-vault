import 'album_photo.dart';

class ViewerPhoto {
  final String imageUrl;
  final String exif;
  final String timestamp;
  final String shutterAperture;
  final String focalIso;
  final String lens;
  final String resolution;
  final String hash;
  final bool isFavorite;

  const ViewerPhoto({
    required this.imageUrl,
    required this.exif,
    required this.timestamp,
    required this.shutterAperture,
    required this.focalIso,
    required this.lens,
    required this.resolution,
    required this.hash,
    this.isFavorite = false,
  });

  ViewerPhoto copyWith({bool? isFavorite}) {
    return ViewerPhoto(
      imageUrl: imageUrl,
      exif: exif,
      timestamp: timestamp,
      shutterAperture: shutterAperture,
      focalIso: focalIso,
      lens: lens,
      resolution: resolution,
      hash: hash,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory ViewerPhoto.fromAlbumPhoto(AlbumPhoto photo, {int index = 0}) {
    const exifs = [
      'ISO 100 • 24mm • f/1.8 • 1/2000s • 48MP RAW',
      'ISO 64 • 90mm • f/2.8 • 1/250s • 60MP DNG',
      'ISO 3200 • 14mm • f/1.4 • 25s • 50MP RAW',
      'ISO 200 • 35mm • f/2.0 • 1/500s • 42MP RAW',
    ];
    const apertures = [
      '1/2000s • f/1.8',
      '1/250s • f/2.8',
      '25s • f/1.4',
      '1/500s • f/2.0',
    ];
    const focals = [
      '24mm (Eq. 35mm) • 100',
      '90mm (Eq. 135mm) • 64',
      '14mm (Eq. 21mm) • 3200',
      '35mm (Eq. 52mm) • 200',
    ];
    const lenses = [
      'Summilux-M 1:1.4/24 ASPH',
      'APO-Summicron 90mm ASPH',
      'Sigma 14mm F1.4 DG DN',
      'Zeiss Distagon 35mm F1.4',
    ];
    const resolutions = [
      '8192 × 5464 • 48MP DNG',
      '9504 × 6336 • 60MP DNG',
      '8688 × 5792 • 50MP RAW',
      '7952 × 5304 • 42MP RAW',
    ];
    const hashes = [
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
      '2c624232cdd221771294dfbb310aca000a0df6ac8b66b696d90ef06fdefb64a3',
      '60303ae22b998861bce3b28f33eec1be758a213c86c93c076dbe9f558c11c752',
    ];

    final i = index % exifs.length;
    return ViewerPhoto(
      imageUrl: photo.imageUrl,
      exif: exifs[i],
      timestamp: '02:44:${(19 + index).toString().padLeft(2, '0')} UTC',
      shutterAperture: apertures[i],
      focalIso: focals[i],
      lens: lenses[i],
      resolution: resolutions[i],
      hash: hashes[i],
      isFavorite: photo.isFavorite,
    );
  }
}
