class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String releaseDate;
  // Cannot be final if we want to set it later in the details fetch
  String? director; 
  String? actors;
  String? country;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    required this.releaseDate,
    this.director,
    this.actors,
    this.country,
  });

  // Este crea la "cáscara" con lo que viene del buscador
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
      return releaseDate.substring(0, 4); // Coge los 4 primeros dígitos (el año)
    }
    return 'N/A';
  }

  // Getter to obtain the full poster URL
  String get fullPosterUrl => posterPath != null 
      ? 'https://image.tmdb.org/t/p/w500$posterPath' 
      : 'https://via.placeholder.com/500x750?text=No+Image';
}