class Book {
  final String id;
  final String title;
  final String? publishedDate;
  final String? imageUrl; // Google API uses 'thumbnail' for book covers
  // Cannot be final if we want to set it later in the details fetch
  final int? pageCount;
  List<String>? authors;
  String? description;

  Book({
    required this.id,
    required this.title,
    this.publishedDate,
    this.imageUrl,
    this.pageCount,
    this.authors,
    this.description,
  });

  // Factory method to create a Book from JSON data
  factory Book.fromJson(Map<String, dynamic> json) {
  final volumeInfo = json['volumeInfo'] ?? {};
  final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;

  String? rawUrl = imageLinks?['thumbnail'];

  return Book(
    id: json['id'] ?? '',
    title: volumeInfo['title'] ?? 'Unknown Title',
    imageUrl: rawUrl?.replaceFirst('http://', 'https://'), 
    authors: (volumeInfo['authors'] as List<dynamic>?)
        ?.map((author) => author.toString())
        .toList(),
    description: volumeInfo['description'],
    publishedDate: volumeInfo['publishedDate'],
    pageCount: (volumeInfo['pageCount'] as num?)?.toInt(),
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

  // Getter to obtain the full cover URL with better quality
  String get fullCoverUrl {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return 'https://via.placeholder.com/150x200?text=No+Cover';
    }
    // Agrega ancho para obtener mejor resolución
    return imageUrl!.contains('&w=')
        ? imageUrl!
        : '${imageUrl!}&w=600';
  }

  String get formattedPageCount {
    if (pageCount == null || pageCount! <= 0) {
      return 'Pages not available';
    }
    return '~ $pageCount pages';
  }
}
