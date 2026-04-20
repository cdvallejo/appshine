import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/book_model.dart';
import 'package:appshine/repositories/book_repository.dart';
import 'package:flutter/material.dart';

/// Custom SearchDelegate for searching books using the Open Library API.
/// Returns a [Book] object when a result is selected, or null if the search is cancelled.
class BookSearchDelegate extends SearchDelegate<Book?> {
  /// Repository instance for searching books via the Open Library API.
  final BookRepository _repo = BookRepository();

  /// The localized label text for the search field.
  final String searchLabel; 

  /// Creates a new [BookSearchDelegate].
  ///
  /// The [searchLabel] parameter is required and should contain the localized text
  /// for the search field hint label ("Search books...", etc).
  BookSearchDelegate({required this.searchLabel});

  @override
  String? get searchFieldLabel => searchLabel;

  /// Builds the action buttons displayed on the right side of the search AppBar.
  ///
  /// Returns: 
  ///  * A list containing a clear button that resets the search query to an empty string.
  ///
  /// Note: This method is automatically invoked by Flutter's SearchDelegate framework.
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  /// Builds the widget displayed on the left side of the search AppBar.
  ///
  /// Returns:
  /// * A back button that closes the search and returns null.
  ///
  /// Note: This method is automatically invoked by Flutter's SearchDelegate framework.
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  /// Builds the widget displayed when the user submits a search query.
  /// Delegates to [_search] to display search results based on the current query.
  /// 
  /// Returns:
  /// *A loading spinner while fetching results
  ///
  /// Note: This method is automatically invoked by Flutter when the user presses the search/submit button.
  @override
  Widget buildResults(BuildContext context) {
    return _search(context);
  }

  /// Builds suggestions displayed as the user types in the search field.
  ///
  /// Returns:
  /// * A centered message prompting the user to type to search.
  ///
  /// Note: This method is automatically invoked by Flutter as the user types in the search field.
  @override
  Widget buildSuggestions(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Text(loc.translate('typeToSearch')),
    );
  }

  /// Builds the search results list from the provided query.
  ///
  /// Uses [FutureBuilder] to asynchronously fetch books from [BookRepository.searchBooks].
  /// Displays:
  /// - A loading spinner while fetching results
  /// - An error message if the search fails
  /// - A "no books found" message if the query returns no results
  /// - A list of books with their cover images, titles, and release years
  /// 
  /// Returns:
  /// * A [ListView] of search results when the query is successful.
  ///
  /// When a book is tapped, it closes the search and returns the selected [Book] object.
  Widget _search(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
          return Center(child: Text(loc.translate('noBooksFound')));
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
