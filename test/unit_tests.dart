import 'package:appshine/models/social_event_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';

void main() {
  group('Book Model Tests', () {
    /// Test 1: Crear un Book válido desde JSON de Open Library
    test('Book.fromJson() - debería crear un libro válido desde JSON', () {
      // Arrange
      final json = {
        'key': 'OL45883W',
        'title': '1984',
        'author_name': ['George Orwell'],
        'first_publish_year': 1949,
        'isbn': ['0451524934'],
        'number_of_pages_median': 328,
        'cover_edition_key': 'olid-123456',
      };

      // Act
      final book = Book.fromJson(json);

      // Assert
      expect(book.title, equals('1984'));
      expect(book.authors, isNotNull);
      expect(book.authors, contains('George Orwell'));
      expect(book.publishedDate, equals('1949'));
      expect(book.subtype, equals('Novel')); // Default subtype
    });
  });

  /// Test 2: Crear un Media válido desde JSON de TMDB
  group('Media Model Tests', () {
    /// Test 1: Crear Media válido desde JSON (Movie)
    test('Media.fromJson() - debería crear una película desde JSON', () {
      // Arrange
      final json = {
        'id': 550,
        'title': 'Fight Club',
        'media_type': 'movie',
        'release_date': '1999-10-15',
        'poster_path': '/poster.jpg',
      };

      // Act
      final media = Media.fromJson(json);

      // Assert
      expect(media.id, equals(550));
      expect(media.title, equals('Fight Club'));
      expect(media.type, equals('movie'));
      expect(media.subtype, equals('Movie'));
      expect(media.releaseYear, equals('1999'));
    });
  });

group('SocialEvent Model Tests', () {
    /// Test 3: Crear SocialEvent válido desde Map
    test('SocialEvent.fromMap() - debería crear evento válido desde Map', () {
      // Arrange
      final map = {
        'title': 'Movie Night',
        'subtype': 'Cultural',
        'imageNames': ['event1.jpg', 'event2.jpg'],
      };

      // Act
      final event = SocialEvent.fromMap(map);

      // Assert
      expect(event.title, equals('Movie Night'));
      expect(event.subtype, equals('Cultural'));
      expect(event.imageNames, equals(['event1.jpg', 'event2.jpg']));
    });

    /// Test 4: SocialEvent sin imágenes
    test('SocialEvent.fromMap() - debería manejar lista vacía de imágenes', () {
      final map = {
        'title': 'Dinner Party',
        'subtype': 'Social',
        'imageNames': [],
      };

      final event = SocialEvent.fromMap(map);

      expect(event.imageNames, isEmpty);
      expect(event.title, equals('Dinner Party'));
    });
  });
}

