class Movie {
  final int id;
  final String title;
  final String? imageUrl;
  final String releaseDate;
  // Cannot be final if we want to set it later in the details fetch
  List<String>? directors; 
  List<String>? actors;
  String? country;

  Movie({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.releaseDate,
    this.directors,
    this.actors,
    this.country,
  });

  // Factory method to create a Movie from JSON data
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      imageUrl: json['poster_path'] != null 
        ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}' 
        : null,
      releaseDate: json['release_date'] ?? '',
      directors: (json['directors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      actors: (json['actors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      country: json['country'],
    );
  }

   String get releaseYear {
    if (releaseDate.length >= 4) {
      return releaseDate.substring(0, 4); // Extract the year from the release date
    }
    return 'N/A';
  }

  // Getter to obtain the full poster URL
  String get fullPosterUrl => imageUrl != null 
      ? 'https://image.tmdb.org/t/p/w500$imageUrl' 
      : 'https://via.placeholder.com/500x750?text=No+Image';
}