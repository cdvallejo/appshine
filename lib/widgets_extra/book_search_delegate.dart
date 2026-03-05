import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/book_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookSearchDelegate extends SearchDelegate<Book?> {
  // TODO: Move to OpenLibrarySearchDelegate when refactoring
  // final BookRepository _repo = BookRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String searchLabel;

  // TODO: Refactor into separate local and Open Library search delegates
  // Split into BookSearchDelegate (local) and OpenLibrarySearchDelegate (Open Library API)
  // Open OpenLibrarySearchDelegate when user clicks "Buscar en Open Library" button

  // Constructor requires searchLabel parameter because the [searchFieldLabel] getter
  // doesn't have access to BuildContext, so we pass the localized text here
  BookSearchDelegate({required this.searchLabel});

  @override
  String? get searchFieldLabel => searchLabel;

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
    final loc = AppLocalizations.of(context);
    return Center(
      child: Text(loc.translate('typeToSearch')),
    );
  }

  /// Search for books in local Firestore collection
  Future<List<Book>> _searchLocal(String query) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Search in books collection using titleLower for case-insensitive search
      // Note: Firestore doesn't have native "contains" so we use range queries
      final queryLower = query.toLowerCase();
      final snapshot = await _db
          .collection('books')
          .where('titleLower', isGreaterThanOrEqualTo: queryLower)
          .where('titleLower', isLessThan: '${queryLower}z')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Book.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error searching local books: $e');
      return [];
    }
  }

  // Common search widget used by both results and suggestions
  Widget _search(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters.'));
    }

    return FutureBuilder<List<Book>>(
      future: _searchLocal(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];

        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.translate('noBooksFound')),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open Open Library search delegate
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar en Open Library'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];

            return InkWell(
              onTap: () => close(context, book),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        : Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                    const SizedBox(width: 16),
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
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
