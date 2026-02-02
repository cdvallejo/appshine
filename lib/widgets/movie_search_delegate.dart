import 'package:appshine/models/movie_model.dart';
import 'package:appshine/repositories/movie_repository.dart';
import 'package:flutter/material.dart';

class MovieSearchDelegate extends SearchDelegate<Movie?> {
  final MovieRepository _repo = MovieRepository();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _search(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _search(context);
  }

  Widget _search(BuildContext context) {
    // Control barriers for short queries. FilmAffinity starts searching from 2 characters.
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters.'));
    }

    return FutureBuilder<List<Movie>>(
      future: _repo.searchMovies(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final movies = snapshot.data ?? [];

        if (movies.isEmpty) {
          return const Center(child: Text('No movies found'));
        }

        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];

            // DESIGN MOVIE ITEM
            return InkWell(
              onTap: () => close(context, movie),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster image
                    movie.imageUrl != null && movie.imageUrl!.isNotEmpty
                        ? Image.network(
                            movie.imageUrl!,
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 80,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                          )
                        // Placeholder in case of no poster
                        : Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                    const SizedBox(width: 16),
                    // Title, year
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            movie.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            movie.releaseYear,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
