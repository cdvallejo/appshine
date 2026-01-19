class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String releaseDate;
  // Cannot be final if we want to set it later in the details fetch
  String? directors; 
  String? actors;
  String? country;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
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
      posterPath: json['poster_path'],
      releaseDate: json['release_date'] ?? '',
    );
  }

   String get releaseYear {
    if (releaseDate.length >= 4) {
      return releaseDate.substring(0, 4); // Extract the year from the release date
    }
    return 'N/A';
  }

  // Getter to obtain the full poster URL
  String get fullPosterUrl => posterPath != null 
      ? 'https://image.tmdb.org/t/p/w500$posterPath' 
      : 'https://via.placeholder.com/500x750?text=No+Image';
}