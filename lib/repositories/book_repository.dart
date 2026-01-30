import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/book_model.dart';

/* Google Books API Repository is much simpler than TMDB because
Google returns more data in the search results directly. */

class BookRepository {
  final String _apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    try {
      // Google returns authors and description in this call
      final url = Uri.parse('$_baseUrl?q=$query&key=$_apiKey&maxResults=20');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Google calls 'items' the list of books
        final List? items = data['items'];
        if (items == null) return [];

        // This is where the Repository passes the work to the Model
        return items.map((item) => Book.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}