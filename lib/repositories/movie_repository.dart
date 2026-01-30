import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie_model.dart';

/* TMDB API Repository is much HARDER than Google Books API because
it's needed to make multiple requests to get all the details. */
class MovieRepository {
  // TMDB API Key and base URL
  final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    // Try-cast: if connection fails, return empty list. Automatically handles exceptions!
    try {
      final url = Uri.parse(
        '$_baseUrl/search/movie?api_key=$_apiKey&query=$query&language=es-ES',
      );
      final response = await http.get(url);

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
          Uri.parse( // Country info - results[0]
            '$_baseUrl/movie/${movie.id}?api_key=$_apiKey&language=es-ES',
          ),
        ),
        http.get(
          Uri.parse( // Credits info - results[1]
            '$_baseUrl/movie/${movie.id}/credits?api_key=$_apiKey&language=es-ES',
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

        movie.directors = directorsList.isEmpty
            ? 'Unknown director'
            : directorsList.take(4).map((d) => d['name'] as String).join(', ');
        movie.actors = cast.isEmpty
            ? 'Unknown cast'
            : cast.take(3).map((a) => a['name'] as String).join(', ');
      } else {
        movie.directors = 'N/A';
        movie.actors = 'N/A';
      }
    } catch (e) {
      movie.country = 'Error loading';
      movie.directors = 'Error loading';
      movie.actors = 'Error loading';
    }
  }
}
