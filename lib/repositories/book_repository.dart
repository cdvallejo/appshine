import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

// Repository using Open Library API - free, unlimited, no API key needed
class BookRepository {
  final String _searchBaseUrl = 'https://openlibrary.org/search.json';

  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    try {
      // Open Library search API - simple and unlimited
      final url = Uri.parse(_searchBaseUrl).replace(
        queryParameters: {
          'q': query,
          'limit': '20',
          // Ask Open Library explicitly for the fields we use in the model.
          'fields': 'key,title,author_name,first_publish_year,isbn,cover_edition_key,cover_i,number_of_pages_median,publisher',
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
    // If we don't have an edition key, try a fallback using work editions.
    if (book.editionKey == null || book.editionKey!.isEmpty) {
      return _getBookDetailsFromWorkEditions(book);
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

          // Extract publisher from Books API details.
          String? publisher = book.publisher;
          final publishers = bookData['publishers'];
          if (publishers is List && publishers.isNotEmpty) {
            final first = publishers.first;
            if (first is Map && first['name'] != null) {
              publisher = first['name'].toString();
            } else {
              publisher = first.toString();
            }
          }
          
          // Extract ISBN from identifiers
          String? isbn = book.isbn;
          if (bookData['identifiers'] is Map) {
            final identifiers = bookData['identifiers'] as Map<String, dynamic>;
            if (identifiers['isbn_13'] is List && (identifiers['isbn_13'] as List).isNotEmpty) {
              isbn = (identifiers['isbn_13'] as List)[0].toString();
            } else if (identifiers['isbn_10'] is List && (identifiers['isbn_10'] as List).isNotEmpty) {
              isbn = (identifiers['isbn_10'] as List)[0].toString();
            }
          }
          
          return Book(
            id: book.id,
            title: book.title,
            publishedDate: book.publishedDate,
            imageUrl: book.imageUrl,
            pageCount: pageCount ?? book.pageCount,
            isbn: isbn,
            publisher: publisher,
            editionKey: book.editionKey,
            authors: book.authors,
            subtype: 'Novel',
          );
        }
      }
      
      // If Books API fails, return the book as-is
      return book;
    } catch (e) {
      return book;
    }
  }

  // Fallback details when editionKey is missing.
  Future<Book> _getBookDetailsFromWorkEditions(Book book) async {
    try {
      final url = Uri.parse('https://openlibrary.org/works/${book.id}/editions.json').replace(
        queryParameters: {
          'limit': '1',
        },
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout fetching editions fallback'),
      );

      if (response.statusCode != 200) {
        return book;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final entries = data['entries'];
      if (entries is! List || entries.isEmpty || entries.first is! Map) {
        return book;
      }

      final edition = entries.first as Map<String, dynamic>;
      int? pageCount = book.pageCount;
      final rawPageCount = edition['number_of_pages'];
      if (rawPageCount is num) {
        pageCount = rawPageCount.toInt();
      }

      String? publisher = book.publisher;
      final publishers = edition['publishers'];
      if (publishers is List && publishers.isNotEmpty) {
        publisher = publishers.first.toString();
      }

      return book.copyWith(
        pageCount: pageCount,
        publisher: publisher,
      );
    } catch (_) {
      return book;
    }
  }
}