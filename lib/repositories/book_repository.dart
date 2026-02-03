import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

// Repository using Open Library API - free, unlimited, no API key needed
class BookRepository {
  final String _searchBaseUrl = 'https://openlibrary.org/search.json';
  final String _detailsBaseUrl = 'https://openlibrary.org';

  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    try {
      // Open Library search API - simple and unlimited
      final url = Uri.parse(_searchBaseUrl).replace(
        queryParameters: {
          'q': query,
          'limit': '20',
        },
      );
      
      // HTTP GET request with timeout
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout while fetching books from Open Library'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docs = data['docs'] as List? ?? [];
        return docs.map((json) => Book.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      // If there was an error, return an empty list
      return [];
    }
  }

  // Fetch additional details for a book using edition key
  Future<Book> getBookDetails(Book book) async {
    // If no edition key, try to get description from work
    if (book.editionKey == null || book.editionKey!.isEmpty) {
      return _getBookDetailsFromWork(book);
    }

    try {
      // Use the Books API with the edition key (OLID)
      final url = Uri.parse('https://openlibrary.org/api/books').replace(
        queryParameters: {
          'bibkeys': 'OLID:${book.editionKey}',
          'jscmd': 'data',
          'format': 'json',
        },
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout fetching book details'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final key = 'OLID:${book.editionKey}';
        
        if (data[key] is Map) {
          final bookData = data[key] as Map<String, dynamic>;
          int? pageCount = bookData['number_of_pages'] as int?;
          
          return Book(
            id: book.id,
            title: book.title,
            publishedDate: book.publishedDate,
            imageUrl: book.imageUrl,
            pageCount: pageCount,
            isbn: book.isbn,
            editionKey: book.editionKey,
            authors: book.authors,
            description: book.description,
          );
        }
      }
      
      // If Books API fails, try work details
      return _getBookDetailsFromWork(book);
    } catch (e) {
      return _getBookDetailsFromWork(book);
    }
  }

  // Helper method to fetch description from work endpoint
  Future<Book> _getBookDetailsFromWork(Book book) async {
    if (book.id.isEmpty) return book;
    try {
      final workUrl = Uri.parse('$_detailsBaseUrl${book.id}.json');
      
      final workResponse = await http.get(workUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout fetching book details'),
      );

      if (workResponse.statusCode == 200) {
        final workData = json.decode(workResponse.body) as Map<String, dynamic>;
        
        final updatedDescription = workData['description'] is Map
            ? (workData['description'] as Map)['value']?.toString()
            : workData['description']?.toString();

        return Book(
          id: book.id,
          title: book.title,
          publishedDate: book.publishedDate,
          imageUrl: book.imageUrl,
          pageCount: book.pageCount,
          isbn: book.isbn,
          editionKey: book.editionKey,
          authors: book.authors,
          description: updatedDescription ?? book.description,
        );
      }
      return book;
    } catch (e) {
      return book;
    }
  }
}