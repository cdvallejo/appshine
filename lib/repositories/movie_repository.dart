import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie_model.dart';

// Repository is the engine that fetches data from TMDB API to models.
/* TMDB API Repository is much HARDER than Google Books API because
it's needed to make multiple requests to get all the details. */
class MovieRepository {
  // TMDB API Key and base URL
  final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    try {
      // Uri.parse with queryParameters to handle spaces and special characters, more secure.
      final url = Uri.parse(_baseUrl).replace(
        path: '/3/search/movie',
        queryParameters: {
          'api_key': _apiKey,
          'query': query,
          'language': 'es-ES',
        },
      );
      // HTTP GET request with timeout
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout en la búsqueda de libros'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch extra details for a specific movie with two more requests
  Future<void> fillExtraDetails(Movie movie) async {
    try {
      // Faster in parallel requests
      final results = await Future.wait([
        http.get(
          Uri.parse(_baseUrl).replace(
            // Country info - results[0]
            path: '/3/movie/${movie.id}',
            queryParameters: {
              'api_key': _apiKey,
              'language': 'es-ES',
            },
          ),
        ),
        http.get(
          Uri.parse(_baseUrl).replace(
            // Credits info - results[1]
            path: '/3/movie/${movie.id}/credits',
            queryParameters: {
              'api_key': _apiKey,
              'language': 'es-ES',
            },
          ),
        ),
      ]);

      // 1. Country
      if (results[0].statusCode == 200) {
        final data = json.decode(results[0].body);
        final countries = data['production_countries'] as List?;
        movie.country = (countries?.isNotEmpty ?? false)
            ? countries![0]['name']
            : 'Unknown country';
      } else {
        movie.country = 'N/A';
      }

      // 2. Director and actors
      if (results[1].statusCode == 200) {
        final data = json.decode(results[1].body);
        final crew = data['crew'] as List? ?? []; // if null, assign empty list
        final cast = data['cast'] as List? ?? [];

        final directorsList = crew
            .where((p) => p['job'] == 'Director')
            .toList();

        // CAMBIO: Ahora asignamos una LISTA, no un String con comas
        movie.directors = directorsList.isEmpty
            ? [] // Lista vacía en lugar de 'Unknown'
            : directorsList
                  .take(4)
                  .map((d) => d['name'] as String)
                  .toList(); // .toList() al final!

        movie.actors = cast.isEmpty
            ? []
            : cast
                  .take(3)
                  .map((a) => a['name'] as String)
                  .toList(); // .toList() al final!
      } else {
        movie.directors = [];
        movie.actors = [];
      }
    } catch (e) {
      movie.country = 'Error loading';
      movie.directors = ['Error loading'];
      movie.actors = ['Error loading'];
    }
  }
}
