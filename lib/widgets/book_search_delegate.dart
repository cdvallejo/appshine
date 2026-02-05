import 'package:appshine/models/book_model.dart';
import 'package:appshine/repositories/book_repository.dart';
import 'package:flutter/material.dart';

class BookSearchDelegate extends SearchDelegate<Book?> {
  final BookRepository _repo = BookRepository();

  // Clear query action button
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  // Leading icon on the left of the AppBar
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  // Build the results based on the search query
  @override
  Widget buildResults(BuildContext context) {
    return _search(context);
  }

  // Build suggestions as the user types
  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Type to search and press the search button'),
    );
  }

  // Common search widget used by both results and suggestions
  Widget _search(BuildContext context) {
    // Control barriers for short queries. FilmAffinity starts searching from 2 characters.
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters.'));
    }

    // Use FutureBuilder to handle asynchronous search
    return FutureBuilder<List<Book>>(
      future: _repo.searchBooks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];

        if (books.isEmpty) {
          return const Center(child: Text('No books found'));
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];

            // DESIGN SCREEN BOOK ITEM
            return InkWell(
              onTap: () => close(context, book),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster image
                    book.fullCoverUrl.isNotEmpty
                        ? Image.network(
                            book.fullCoverUrl,
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 80,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                          )
                        // Placeholder in case of no poster
                        : Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                    const SizedBox(width: 16),
                    // Title, year
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.releaseYear,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
