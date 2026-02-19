class Book {
  static const List<String> subtypes = [
    'Novel',
    'Manga',
    'Comic',
    'Essay',
    'Technical',
    'Sheet music',
  ];

  final String id;
  final String title;
  final String? publishedDate;
  final String? imageUrl;
  final int? pageCount;
  final String? isbn;
  final String? publisher;
  final String? editionKey; // Open Library ID for direct edition API access
  final String subtype; // 'Novel', 'Manga', 'Comic', 'Essay', 'Technical', 'Sheet music'
  List<String>? authors;

  Book({
    required this.id,
    required this.title,
    this.publishedDate,
    this.imageUrl,
    this.pageCount,
    this.isbn,
    this.publisher,
    this.editionKey, // Open Library ID for direct edition API access
    this.authors,
    required this.subtype,
  });

  /// Factory method to create a Book from Open Library API JSON data
  /// Throws [FormatException] if required fields are missing
  factory Book.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['key'] == null || (json['key'] is String && (json['key'] as String).isEmpty)) {
      throw FormatException('Missing required field: key (Open Library ID)');
    }
    if (json['title'] == null || (json['title'] is String && (json['title'] as String).isEmpty)) {
      throw FormatException('Missing required field: title');
    }

    // Open Library covers: https://covers.openlibrary.org/b/$key/$value-$size.jpg
    String? coverUrl;
    
    // Priority 1: cover_edition_key (OLID - Open Library ID)
    if (json['cover_edition_key'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/olid/${json['cover_edition_key']}-M.jpg';
    } 
    // Priority 2: cover_i (Internal Cover ID)
    else if (json['cover_i'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${json['cover_i']}-M.jpg';
    }

    List<String>? authors;
    if (json['author_name'] is List && (json['author_name'] as List).isNotEmpty) {
      authors = (json['author_name'] as List<dynamic>)
          .map((author) => author.toString())
          .toList();
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
    
    // Extract edition key (OLID) for direct API access
    String? editionKey = json['cover_edition_key'] as String?;

    return Book(
      id: (json['key'] as String).trim(),
      title: (json['title'] as String).trim(),
      imageUrl: coverUrl,
      isbn: isbn,
      editionKey: editionKey,
      authors: authors,
      publishedDate: publishedDate,
      pageCount: null,
      subtype: 'Novel', // Default subtype, can be updated later
    );
  }

  String get releaseYear {
    if (publishedDate != null && publishedDate!.length >= 4) {
      return publishedDate!.substring(
        0,
        4,
      ); // Extract the year from the published date
    }
    return 'N/A';
  }

  // Getter to obtain the full cover URL in large size (for Firebase storage)
  String get fullCoverUrl {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return 'https://via.placeholder.com/150x200?text=No+Cover';
    }
    // Convert M size to L size for better quality when storing in Firebase
    return imageUrl!.replaceAll('-M.jpg', '-L.jpg');
  }

  // Getter to obtain the cover URL in medium size (for search results)
  String get searchCoverUrl {
    return imageUrl ?? 'https://via.placeholder.com/150x200?text=No+Cover';
  }

  // Method to get cover URL in specific size (S, M, L)
  String getCoverUrl(String size) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return 'https://via.placeholder.com/150x200?text=No+Cover';
    }
    // Replace M with the desired size
    return imageUrl!.replaceAll('-M.jpg', '-$size.jpg');
  }

  String get formattedPageCount {
    if (pageCount == null || pageCount! <= 0) {
      return 'N/A';
    }
    return '$pageCount';
  }

  Book copyWith({
    String? id,
    String? title,
    String? publishedDate,
    String? imageUrl,
    int? pageCount,
    String? isbn,
    String? publisher,
    String? editionKey,
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
      subtype: subtype ?? this.subtype,
      authors: authors ?? this.authors,
    );
  }
}
