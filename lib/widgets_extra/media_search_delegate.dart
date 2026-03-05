import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/media_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MediaSearchDelegate extends SearchDelegate<Media?> {
  // TODO: Move to TMDBSearchDelegate when refactoring
  // final MediaRepository _repo = MediaRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String searchLabel;

  // TODO: Refactor into separate local and TMDB search delegates
  // Split into MediaSearchDelegate (local) and TMDBSearchDelegate (TMDB API)
  // Open TMDBSearchDelegate when user clicks "Buscar en TMDB" button

  /// Constructor requires searchLabel parameter because the [searchFieldLabel] getter
  /// doesn't have access to BuildContext, so we pass the localized text here
  MediaSearchDelegate({required this.searchLabel});

  @override
  String? get searchFieldLabel => searchLabel;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _search(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Text(loc.translate('typeToSearch')),
    );
  }

  /// Search for media in local Firestore collection
  Future<List<Media>> _searchLocal(String query) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Search in media collection using titleLower for case-insensitive search
      // Note: Firestore doesn't have native "contains" so we use range queries
      final queryLower = query.toLowerCase();
      final snapshot = await _db
          .collection('media')
          .where('titleLower', isGreaterThanOrEqualTo: queryLower)
          .where('titleLower', isLessThan: '${queryLower}z')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Media.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error searching local media: $e');
      return [];
    }
  }

  Widget _search(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return FutureBuilder<List<Media>>(
      future: _searchLocal(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final movies = snapshot.data ?? [];

        if (movies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.translate('noMoviesFound')),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open TMDB search delegate
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar en TMDB'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];

            return InkWell(
              onTap: () => close(context, movie),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    movie.imageUrl != null && movie.imageUrl!.isNotEmpty
                        ? Image.network(
                            movie.imageUrl!,
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
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            movie.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            movie.releaseYear,
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
