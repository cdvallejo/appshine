import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/media_model.dart';
import 'package:appshine/repositories/media_repository.dart';
import 'package:flutter/material.dart';

class MediaSearchDelegate extends SearchDelegate<Media?> {
  final MediaRepository _repo = MediaRepository();
  final String searchLabel;

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

  Widget _search(BuildContext context) {

    return FutureBuilder<List<Media>>(
      future: _repo.searchMedia(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final movies = snapshot.data ?? [];

        if (movies.isEmpty) {
          return const Center(child: Text('No movies found'));
        }

        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];

            // DESIGN MOVIE ITEM
            return InkWell(
              onTap: () => close(context, movie),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster image
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
                        // Placeholder in case of no poster
                        : Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                    const SizedBox(width: 16),
                    // Title, year
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
