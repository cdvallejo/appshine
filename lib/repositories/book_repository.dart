import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/book_model.dart';

// Repository is the engine that fetches data from Google Books API to models.
/* Google Books API Repository is simpler than TMDB because
Google returns more data in the search results directly. */
class BookRepository {
  final String _apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    try {
      // Uri.parse with queryParameters to handle spaces and special characters, more secure.
      final url = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': query,
          'key': _apiKey,
          'maxResults': '20',
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
        final items = data['items'] as List? ?? [];
        return items.map((json) => Book.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      // If there was an error, return an empty list
      return [];
    }
  }
}