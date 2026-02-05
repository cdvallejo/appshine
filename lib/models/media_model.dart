class Media {
  final int id;
  final String title;
  final String? imageUrl;
  final String? releaseDate;
  final String type; // movie or tv
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
}
