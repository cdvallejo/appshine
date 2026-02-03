class Book {
  final String id;
  final String title;
  final String? publishedDate;
  final String? imageUrl;
  final int? pageCount;
  final String? isbn;
  final String? editionKey; // OLID for direct edition API access
  List<String>? authors;
  String? description;

  Book({
    required this.id,
    required this.title,
    this.publishedDate,
    this.imageUrl,
    this.pageCount,
    this.isbn,
    this.editionKey,
    this.authors,
    this.description,
  });

  // Factory method to create a Book from JSON data (Open Library API format)
  factory Book.fromJson(Map<String, dynamic> json) {
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
    if (json['author_name'] is List) {
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
      id: json['key'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      imageUrl: coverUrl,
      isbn: isbn,
      editionKey: editionKey,
      authors: authors,
      description: json['description'] is Map 
          ? (json['description'] as Map)['value']?.toString()
          : json['description']?.toString(),
      publishedDate: publishedDate,
      pageCount: null,
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
      return 'Pages not available';
    }
    return '~ $pageCount pages';
  }
}
