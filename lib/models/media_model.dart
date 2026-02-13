/* Generic model for both movies, TV shows, etc, with common fields and some optional ones for details
Audiovisual type - subtypes: Movie, TV Series
FUTURE: Videogame type */

class Media {
  static const List<String> subtypes = ['Movie', 'TV Series'];

  final int id;
  final String title;
  final String? imageUrl;
  final String? releaseDate;
  final String type; // movie or tv
  final String subtype; // 'Movie' or 'TV Series'
  // Cannot be final if we want to set it later in the details fetch
  List<String>? directors;
  List<String>? creators;
  List<String>? actors;
  String? country;

  Media({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.releaseDate,
    this.directors,
    this.creators,
    this.actors,
    this.country,
    required this.type,
    required this.subtype,
  });

  // Factory method to create a Media from JSON data
  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      title: json['media_type'] == 'tv' ? json['name'] : json['title'],
      imageUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      releaseDate:
          (json['media_type'] == 'tv'
              ? json['first_air_date']
              : json['release_date']) ??
          '',
      directors: (json['directors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      actors: (json['actors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      country: json['country'],
      type: json['media_type'],
      subtype: json['media_type'] == 'tv' ? 'TV Series' : 'Movie',
    );
  }

  String get releaseYear {
    final date = releaseDate;
    if (date != null && date.length >= 4) {
      return date.substring(0, 4);
    }
    return 'N/A';
  }

  // Getter to obtain the full poster URL
  String get fullPosterUrl => imageUrl != null
      ? 'https://image.tmdb.org/t/p/w500$imageUrl'
      : 'https://via.placeholder.com/500x750?text=No+Image';

  Media copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? releaseDate,
    String? type,
    String? subtype,
    List<String>? directors,
    List<String>? creators,
    List<String>? actors,
    String? country,
  }) {
    return Media(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      directors: directors ?? this.directors,
      creators: creators ?? this.creators,
      actors: actors ?? this.actors,
      country: country ?? this.country,
    );
  }
}
