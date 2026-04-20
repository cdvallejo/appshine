import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/media_model.dart';
import 'package:appshine/repositories/media_repository.dart';
import 'package:flutter/material.dart';

/// Custom SearchDelegate for searching movies and TV shows using the TMDb API.
/// Returns a [Media] object when a result is selected, or null if the search is cancelled.
class MediaSearchDelegate extends SearchDelegate<Media?> {
  /// Repository instance for searching media via the TMDb API.
  final MediaRepository _repo = MediaRepository();

  /// The localized label text for the search field.
  final String searchLabel;

  /// Creates a new [MediaSearchDelegate].
  ///
  /// The [searchLabel] parameter is required and should contain the localized text
  /// for the search field hint label ("Search movies...", etc).
  MediaSearchDelegate({required this.searchLabel});

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
  /// Uses [FutureBuilder] to asynchronously fetch media from [MediaRepository.searchMedia].
  /// Displays:
  /// - A loading spinner while fetching results
  /// - An error message if the search fails
  /// - A "no movies found" message if the query returns no results
  /// - A list of movies with their poster images, titles, and release years
  /// 
  /// Returns:
  /// * A [ListView] of search results when the query is successful.
  ///
  /// When a media item is tapped, it closes the search and returns the selected [Media] object.
  Widget _search(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final languageCode = '${loc.locale.languageCode}-${(loc.locale.countryCode ?? loc.locale.languageCode).toUpperCase()}';

    return FutureBuilder<List<Media>>(
      future: _repo.searchMedia(query, languageCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final movies = snapshot.data ?? [];

        if (movies.isEmpty) {
          return Center(child: Text(loc.translate('noMoviesFound')));
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
