class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String releaseDate;

  Movie({required this.id, required this.title, this.posterPath, required this.releaseDate});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      releaseDate: json['release_date'] ?? '',
    );
  }
}