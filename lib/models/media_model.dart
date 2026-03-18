/// Media model representing movies and TV series from TMDB.
class Media {
  static const List<String> subtypes = ['Movie', 'TV Series'];

  final int id;
  final String title;
  final String? imageUrl;
  final String? releaseDate;
  final String type; // media
  final String subtype; // 'Movie' or 'TV Series'
  // Cannot be final if we want to set it later in the details fetch
  List<String>? directors;
  List<String>? creators;
  List<String>? screenwriters;
  List<String>? cast;
  List<String>? genres;
  String? country;

  /// Creates a [Media] model.
  ///
  /// Parameters:
  /// * [id]: TMDB numeric identifier.
  /// * [title]: Display title (`title` for movies, `name` for TV).
  /// * [imageUrl]: Optional poster URL.
  /// * [releaseDate]: Optional release/first air date.
  /// * [type]: Raw media type from API (`movie` or `tv`).
  /// * [subtype]: UI subtype label (`Movie` or `TV Series`).
  /// * [directors], [creators], [screenwriters], [cast], [genres]: Optional people/genre lists.
  /// * [country]: Optional production country.
  Media({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.releaseDate,
    this.directors,
    this.creators,
    this.screenwriters,
    this.cast,
    this.genres,
    this.country,
    required this.type,
    required this.subtype,
  });

  /// Creates a [Media] from TMDB API fields.
  ///
  /// Parameters:
  /// * [json]: TMDB map payload.
  ///
  /// Returns:
  /// * A normalized [Media] instance.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory Media.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final rawId = json['id'];
    if (rawId == null) {
      throw FormatException('Missing required field: id');
    }
    if (rawId is! num) {
      throw FormatException('Invalid field: id must be numeric');
    }
    if (json['media_type'] == null) {
      throw FormatException('Missing required field: media_type');
    }

    final mediaType = json['media_type'] as String;
    final title = mediaType == 'tv' ? json['name'] : json['title'];
    if (title == null || (title is String && title.isEmpty)) {
      throw FormatException('Missing required field: title (name for TV, title for movies)');
    }

    return Media(
      id: rawId.toInt(),
      title: title.toString(),
      imageUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      releaseDate:
          (mediaType == 'tv'
              ? json['first_air_date']
              : json['release_date']) ??
          '',
      directors: (json['directors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      cast: (json['cast'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      country: json['country'] as String?,
      type: mediaType,
      subtype: mediaType == 'tv' ? 'TV Series' : 'Movie',
    );
  }

  /// Returns the 4-digit year extracted from [releaseDate], or `N/A`.
  String get releaseYear {
    final date = releaseDate;
    if (date != null && date.length >= 4) {
      return date.substring(0, 4);
    }
    return 'N/A';
  }

  /// Returns the full poster URL, or a placeholder if no image exists.
  String get fullPosterUrl => imageUrl != null
      ? 'https://image.tmdb.org/t/p/w500$imageUrl'
      : 'https://via.placeholder.com/500x750?text=No+Image';

  /// Creates a copy of this [Media] overriding only provided fields.
  ///
  /// Returns:
  /// * A new [Media] with overridden values when provided, preserving others.
  Media copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? releaseDate,
    String? type,
    String? subtype,
    List<String>? directors,
    List<String>? creators,
    List<String>? screenwriters,
    List<String>? cast,
    List<String>? genres,
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
      screenwriters: screenwriters ?? this.screenwriters,
      cast: cast ?? this.cast,
      genres: genres ?? this.genres,
      country: country ?? this.country,
    );
  }
}
