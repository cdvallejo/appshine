import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

/// Repository for searching and enriching book data from Open Library.
class BookRepository {
  final String _searchBaseUrl = 'https://openlibrary.org/search.json';
  
  // Cover URL constants (centralized)
  static const String _coverBaseUrl = 'https://covers.openlibrary.org/b';
  static const String _coverPlaceholder = 'https://via.placeholder.com/150x200?text=No+Cover';

  /// Builds a cover URL from cover IDs.
  /// Tries edition key first, then internal cover ID.
  String _buildCoverUrl(String? editionKey, String? coverId) {
    if (editionKey != null && editionKey.isNotEmpty) {
      return '$_coverBaseUrl/olid/$editionKey-M.jpg';
    } else if (coverId != null && coverId.isNotEmpty) {
      return '$_coverBaseUrl/id/$coverId-M.jpg';
    }
    return _coverPlaceholder;
  }

  /// Searches books using Open Library `search.json`.
  ///
  /// Parameters:
  /// * [query]: User search text.
  ///
  /// Returns:
  /// * A list of normalized [Book] items.
  /// * An empty list when query is empty, request fails, or parsing fails.
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    try {
      // Open Library search API - simple and unlimited
      final url = Uri.parse(_searchBaseUrl).replace(
        queryParameters: {
          'q': query,
          'limit': '20',
          // Ask Open Library explicitly for the fields we use in the model.
          'fields':
              'key,title,author_name,first_publish_year,isbn,cover_edition_key,cover_i,number_of_pages_median,publisher',
        },
      );

      // HTTP GET request with timeout
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Timeout while fetching books from Open Library',
            ),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docs = data['docs'] as List? ?? [];
        final books = <Book>[];
        for (final json in docs) {
          try {
            final book = Book.fromJson(json);
            // Build cover URL from IDs
            final coverUrl = _buildCoverUrl(book.editionKey, book.coverId);
            books.add(book.copyWith(imageUrl: coverUrl));
          } catch (_) {
            // Skip books that fail to parse
          }
        }
        return books;
      } else {
        return [];
      }
    } catch (_) {
      return []; // If there was an error, return an empty list
    }
  }

  /// Fetches additional details for a [book].
  ///
  /// It tries `api/books` when [Book.editionKey] exists, and falls back to
  /// work editions when it does not.
  ///
  /// Parameters:
  /// * [book]: Base book instance to enrich.
  ///
  /// Returns:
  /// * An enriched [Book] when detail data is available.
  /// * The original [book] when detail lookup fails.
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

      final response = await http
          .get(url)
          .timeout(
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
            if (identifiers['isbn_13'] is List &&
                (identifiers['isbn_13'] as List).isNotEmpty) {
              isbn = (identifiers['isbn_13'] as List)[0].toString();
            } else if (identifiers['isbn_10'] is List &&
                (identifiers['isbn_10'] as List).isNotEmpty) {
              isbn = (identifiers['isbn_10'] as List)[0].toString();
            }
          }

          return book.copyWith(
            pageCount: pageCount,
            isbn: isbn,
            publisher: publisher,
            subtype: 'Novel',
          );
        }
      }

      return book;
    } catch (_) {
      return book; // If Books API fails in lazy loading, return the book as-is
    }
  }

  /// Fallback detail lookup using work editions endpoint.
  ///
  /// Parameters:
  /// * [book]: Base book instance to enrich.
  ///
  /// Returns:
  /// * A partially enriched [Book] using edition fields when available.
  /// * The original [book] when fallback lookup fails.
  Future<Book> _getBookDetailsFromWorkEditions(Book book) async {
    try {
      final url = Uri.parse(
        'https://openlibrary.org/works/${book.id}/editions.json',
      ).replace(queryParameters: {'limit': '1'});

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Timeout fetching editions fallback'),
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

      return book.copyWith(pageCount: pageCount, publisher: publisher);
    } catch (_) {
      // If fallback also fails, return the original book.
      return book;
    }
  }
}
