import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/media_model.dart';

// Repository is the engine that fetches data from TMDB API to models.
/* TMDB API Repository is much HARDER
it's needed to make multiple requests to get all the details. */
class MediaRepository {
  // TMDB API Key and base URL
  final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Media>> searchMedia(String query) async {
    if (query.isEmpty) return [];
    try {
      // Uri.parse with queryParameters to handle spaces and special characters, more secure.
      final url = Uri.parse(_baseUrl).replace(
        path: '/3/search/multi',
        queryParameters: {
          'api_key': _apiKey,
          'query': query,
          'language': 'es-ES',
        },
      );
      // HTTP GET request with timeout
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout en la búsqueda de libros'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        // Filter to only include movies and TV shows, exclude people
        final filtered = results
            .where((item) => item['media_type'] == 'movie' || item['media_type'] == 'tv')
            .toList();
        return filtered.map((json) => Media.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch extra details for a specific movie or TV show with two more requests
  Future<void> getMovieDetails(Media media) async {
    try {
      // Determine the correct endpoint based on media type
      final String mediaType = media.type == 'tv' ? 'tv' : 'movie';
      
      // Faster in parallel requests
      final results = await Future.wait([
        http.get(
          Uri.parse(_baseUrl).replace(
            // Country info - results[0]
            path: '/3/$mediaType/${media.id}',
            queryParameters: {
              'api_key': _apiKey,
              'language': 'es-ES',
            },
          ),
        ),
        http.get(
          Uri.parse(_baseUrl).replace(
            // Credits info - results[1]
            path: '/3/$mediaType/${media.id}/credits',
            queryParameters: {
              'api_key': _apiKey,
              'language': 'es-ES',
            },
          ),
        ),
      ]);

      // 1. Country
      if (results[0].statusCode == 200) {
        final data = json.decode(results[0].body);
        final countries = data['production_countries'] as List?;
        final productionCompanies = data['production_companies'] as List?;
        
        // Get the origin country from the first production company
        String countryCode = '';
        if (productionCompanies?.isNotEmpty ?? false) {
          countryCode = productionCompanies![0]['origin_country'] as String? ?? '';
        }
        
        // Find the country name from production_countries that matches the country code
        if (countryCode.isNotEmpty && countries!.isNotEmpty) {
          final country = countries.firstWhere(
            (c) => c['iso_3166_1'] == countryCode,
            orElse: () => null,
          );
          media.country = country?['name'] ?? 'Unknown country';
        } else if (countries?.isNotEmpty ?? false) {
          // Fallback to first production_country if no production_company found
          media.country = countries![0]['name'];
        } else {
          media.country = 'Unknown country';
        }
        
        // For TV shows, also get creators from here
        if (mediaType == 'tv') {
          final createdBy = data['created_by'] as List? ?? [];
          media.creators = createdBy.isEmpty
              ? []
              : createdBy
                    .take(4)
                    .map((c) => c['name'] as String)
                    .toList();
        }
      } else {
        media.country = 'N/A';
      }

      // 2. Director and cast
      if (results[1].statusCode == 200) {
        final data = json.decode(results[1].body);
        final crew = data['crew'] as List? ?? []; // if null, assign empty list
        final cast = data['cast'] as List? ?? [];

        // Get directors by their known_for_department for TV, or job for movies
        List<dynamic> directorsList = [];
        if (mediaType == 'tv') {
          directorsList = crew
              .where((p) => p['known_for_department'] == 'Directing')
              .toList();
        } else {
          directorsList = crew
              .where((p) => p['job'] == 'Director')
              .toList();
        }

        media.directors = directorsList.isEmpty
            ? []
            : directorsList
                  .take(4)
                  .map((d) => d['name'] as String)
                  .toList();

        media.cast = cast.isEmpty
            ? []
            : cast
                  .take(3)
                  .map((a) => a['name'] as String)
                  .toList();
      } else {
        media.directors = [];
        media.creators ??= [];
        media.cast = [];
      }
    } catch (e) {
      media.country = 'Error loading';
      media.directors = ['Error loading'];
      media.creators = ['Error loading'];
      media.cast = ['Error loading'];
    }
  }
}
