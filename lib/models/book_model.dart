/// Book model representing a book retrieved from the Open Library API.
class Book {
  static const List<String> subtypes = [
    'Novel',
    'Comic',
    'Essay',
    'Sheet music',
    'Other',
  ];

  final String id;
  final String title;
  final String? publishedDate;
  final String? imageUrl;
  final int? pageCount;
  final String? isbn;
  final String? publisher;
  final String? editionKey;
  final String? coverId; // Internal Cover ID from Open Library (cover_i)
  final String subtype;
  List<String> authors;

  /// Creates a [Book] model.
  ///
  /// Parameters:
  /// * [id]: Open Library work identifier (normalized code only).
  /// * [title]: Display title.
  /// * [authors]: List of authors (empty list when unknown).
  /// * [subtype]: Book subtype/category.
  /// * [publishedDate]: Optional publication date/year as text.
  /// * [imageUrl]: Optional cover URL.
  /// * [pageCount]: Optional page count.
  /// * [isbn]: Optional ISBN.
  /// * [publisher]: Optional publisher name.
  /// * [editionKey]: Optional Open Library edition key (OLID).
  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.subtype,
    this.publishedDate,
    this.imageUrl,
    this.pageCount,
    this.isbn,
    this.publisher,
    this.editionKey,
    this.coverId,
    
  });

  /// Creates a [Book] from Open Library API fields.
  ///
  /// Parameters:
  /// * [json]: Open Library map (`search.json` doc object).
  ///
  /// Returns:
  /// * A normalized [Book] instance with safe defaults for missing optional fields.
  ///
  /// Throws [FormatException] if required fields are missing.
  factory Book.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final key = json['key'];
    if (key == null || (key is! String) || (key).isEmpty) {
      throw FormatException('Missing or invalid required field: key (Open Library ID)');
    }
    
    final title = json['title'];
    if (title == null || (title is! String) || (title).isEmpty) {
      throw FormatException('Missing or invalid required field: title');
    }

    // Open Library covers: https://covers.openlibrary.org/b/$key/$value-$size.jpg
    // Repository will construct the URL from these IDs
    // Note: cover_i may be a number, so convert to string if present
    String? coverEditionKey = json['cover_edition_key']?.toString();
    String? coverId = json['cover_i']?.toString();

    List<String>? authors;
    if (json['author_name'] is List && (json['author_name'] as List).isNotEmpty) {
      authors = (json['author_name'] as List<dynamic>)
          .map((author) => author.toString())
          .toList();
    } else {
      authors = []; // Empty list avoids null checks in UI code.
    }

    String? publishedDate;
    if (json['first_publish_year'] != null) {
      publishedDate = json['first_publish_year'].toString();
    }

    // Extract ISBN (if available)
    String? isbn;
    if (json['isbn'] is List && (json['isbn'] as List).isNotEmpty) {
      isbn = (json['isbn'] as List)[0].toString();
    }

    // Extract page count (if available)
    int? pageCount;
    final rawPageCount = json['number_of_pages_median'];
    if (rawPageCount is num) {
      pageCount = rawPageCount.toInt();
    }

    // Extract publisher (if available)
    String? publisher;
    if (json['publisher'] is List && (json['publisher'] as List).isNotEmpty) {
      publisher = (json['publisher'] as List).first.toString();
    } else if (json['publisher'] is String && (json['publisher'] as String).trim().isNotEmpty) {
      publisher = (json['publisher'] as String).trim();
    }

    return Book(
      id: (key).split('/').last.trim(),
      title: (title).trim(),
      imageUrl: null, // Repository will construct the URL
      isbn: isbn,
      editionKey: coverEditionKey,
      coverId: coverId,
      publisher: publisher,
      authors: authors,
      publishedDate: publishedDate,
      pageCount: pageCount,
      subtype: 'Novel',
    );
  }

  /// Returns the 4-digit year extracted from [publishedDate], or `N/A`.
  String get releaseYear {
    if (publishedDate != null && publishedDate!.length >= 4) {
      return publishedDate!.substring(0, 4);
    }
    return 'N/A';
  }

  /// Returns the large cover URL variant for storage/use in detail views.
  String get fullCoverUrl {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return 'https://via.placeholder.com/150x200?text=No+Cover';
    }
    return imageUrl!.replaceAll('-M.jpg', '-L.jpg');
  }

  /// Returns the medium cover URL variant for search/result cards.
  String get searchCoverUrl {
    return imageUrl ?? 'https://via.placeholder.com/150x200?text=No+Cover';
  }

  /// Returns the cover URL with the requested Open Library size (`M`).
  ///
  /// Parameters:
  /// * [size]: Requested cover size code (`M`).
  ///
  /// Returns:
  /// * The cover URL in the requested size, or a placeholder URL when no cover exists.
  String getCoverUrl(String size) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return 'https://via.placeholder.com/150x200?text=No+Cover';
    }
    return imageUrl!.replaceAll('-M.jpg', '-$size.jpg');
  }

  /// Returns a display-ready page count, or `N/A` when unavailable.
  String get formattedPageCount {
    if (pageCount == null || pageCount! <= 0) {
      return 'N/A';
    }
    return '$pageCount';
  }

  /// Creates a copy of this [Book] overriding only provided fields.
  ///
  /// Returns:
  /// * A new [Book] with overridden values when provided, preserving others.
  Book copyWith({
    String? id,
    String? title,
    String? publishedDate,
    String? imageUrl,
    int? pageCount,
    String? isbn,
    String? publisher,
    String? editionKey,
    String? coverId,
    String? subtype,
    List<String>? authors,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      publishedDate: publishedDate ?? this.publishedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      pageCount: pageCount ?? this.pageCount,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      editionKey: editionKey ?? this.editionKey,
      coverId: coverId ?? this.coverId,
      subtype: subtype ?? this.subtype,
      authors: authors ?? this.authors,
    );
  }
}
