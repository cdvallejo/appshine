class Book {
  final String id;
  final String title;
  final String? publishedDate;
  final String? thumbnailUrl; // Google API uses 'thumbnail' for book covers
  // Cannot be final if we want to set it later in the details fetch
  List<String>? authors; 
  String? description;

  Book({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.authors,
    this.description,
    this.publishedDate,
  });

  // Factory method to create a Book from JSON data
  factory Book.fromJson(Map<String, dynamic> json) {
    // 1. Title and other info are inside volumeInfo
    final volumeInfo = json['volumeInfo'] ?? {};
    // 2. Extract images if they exist
    final imageLinks = volumeInfo['imageLinks'];

    return Book(
      id: json['id'] ?? '', // ID is at the root level
      title: volumeInfo['title'] ?? 'Unknown Title',
      thumbnailUrl: imageLinks?['thumbnail']?.replaceFirst('http://', 'https://'), // Ensure HTTPS in case of HTTP (Google API uses sometimes http and Flutter requires https)
      authors: (volumeInfo['authors'] as List<dynamic>?)
          ?.map((author) => author.toString())
          .toList(),
      description: volumeInfo['description'],
      publishedDate: volumeInfo['publishedDate'],
    );
  }

   String get releaseYear {
    if (publishedDate != null && publishedDate!.length >= 4) {
      return publishedDate!.substring(0, 4); // Extract the year from the published date
    }
    return 'N/A';
  }

  // Getter to obtain the full cover URL
  String get fullCoverUrl => thumbnailUrl != null 
      ? thumbnailUrl! 
      : 'https://via.placeholder.com/500x750?text=No+Image';
}