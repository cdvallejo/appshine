import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie_model.dart';

class TMDBRepository {
  // TMDB API Key and base URL
  final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    // Build the request URL
    final url = Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=$query&language=es-ES');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List results = data['results'];
      
      // Convert each result into an object of our Movie class
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Error connecting to TMDB: ${response.statusCode}');
    }
  }
}