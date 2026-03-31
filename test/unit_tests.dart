import 'package:appshine/models/social_event_model.dart';
import 'package:appshine/models/moment_model.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';

/// Este archivo contiene 14 pruebas unitarias para los modelos de datos y funcionalidades clave de la aplicación.
/// Se incluyen pruebas para:
/// - Book Model: Validación de creación desde JSON de Open Library, manejo de casos sin autores, etc.
/// - Media Model: Validación de creación desde JSON de TMDb, manejo de casos con id no numérico, etc.
/// - SocialEvent Model: Validación de creación desde Map, manejo de casos sin imágenes, etc.
/// - Moment Model: Validación de creación desde Map, manejo de campos opcionales, etc.
/// - AppLocalizations: Validación de traducciones y cambio de idioma.
/// - AppTheme: Validación de temas LIGHT y DARK.
void main() {
  // ----- BOOK MODEL TESTS -----
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
        'publisher': ['Secker & Warburg'],
        'cover_edition_key': 'olid-123456',
      };

      final book = Book.fromJson(json);

      expect(book.title, equals('1984'));
      expect(book.authors, isNotNull);
      expect(book.authors, contains('George Orwell'));
      expect(book.publishedDate, equals('1949'));
      expect(book.pageCount, equals(328));
      expect(book.publisher, equals('Secker & Warburg'));
      expect(book.subtype, equals('Novel'));
      expect(book.id, equals('OL45883W'));
    });

    /// Test 2: Book válido sin autores
    test('Book.fromJson() - debería manejar JSON sin autores', () {
      final json = {
        'key': 'OL123456W',
        'title': 'Unknown Book',
        'first_publish_year': 2000,
        'isbn': ['1234567890'],
        'number_of_pages_median': 200,
        'cover_edition_key': 'olid-789',
      };

      final book = Book.fromJson(json);

      expect(book.authors, isEmpty);
    });
  });

  // ----- MEDIA MODEL TESTS -----
  group('Media Model Tests', () {
    /// Test 3: Crear Media válido desde JSON (Movie)
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

    /// Test 4: Crear Media válido desde JSON (TV Series)
    test('Media.fromJson() - debería crear una serie de TV desde JSON', () {
      final json = {
        'id': 1399,
        'name': 'Breaking Bad',
        'media_type': 'tv',
        'first_air_date': '2008-01-20',
        'poster_path': '/poster.jpg',
      };

      final media = Media.fromJson(json);

      expect(media.title, equals('Breaking Bad'));
      expect(media.type, equals('tv'));
      expect(media.subtype, equals('TV Series'));
    });

    /// Test 5: Media con id vacío (debe lanzar excepción)
    test('Media.fromJson() - debería lanzar excepción si id es no es numérico', () {
      final json = {
        'id': '',
        'name': 'Breaking Bad',
        'media_type': 'tv',
        'first_air_date': '2008-01-20',
        'poster_path': '/poster.jpg',
      };

      try {
        Media.fromJson(json);
        fail('Debería lanzar FormatException');
      } catch (e) {
        expect(e, isA<FormatException>()); // Pasa si se lanza FormatException
      }
    });
  });

  // ----- SOCIAL EVENT MODEL TESTS -----
  group('SocialEvent Model Tests', () {
    /// Test 6: Crear SocialEvent válido desde Map
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

    /// Test 7: SocialEvent sin imágenes
    test('SocialEvent.fromMap() - debería manejar lista vacía de imágenes', () {
      final map = {
        'title': 'Dinner Party',
        'subtype': 'Hangout',
        'imageNames': [],
      };

      final event = SocialEvent.fromMap(map);

      expect(event.imageNames, isEmpty);
      expect(event.title, equals('Dinner Party'));
    });

    /// Test 8: SocialEvent.toMap()
    test('SocialEvent.toMap() - debería convertir evento a map', () {
      final event = SocialEvent(
        title: 'Concert',
        subtype: 'Cultural',
        imageNames: ['concert1.jpg'],
      );

      final map = event.toMap();

      expect(map['title'], equals('Concert'));
      expect(map['subtype'], equals('Cultural'));
      expect(map['imageNames'], equals(['concert1.jpg']));
    });

    /// Test 9: SocialEvent con subtype variado
    test('SocialEvent.fromMap() - debería aceptar diferentes subtipos', () {
      final subtypes = [
        'Cultural',
        'Gaming',
        'Hangout',
        'Milestone',
        'Sport',
        'Other',
      ];

      for (final subtype in subtypes) {
        final map = {
          'title': 'Event',
          'subtype': subtype,
          'imageNames': [],
        };

        final event = SocialEvent.fromMap(map);

        expect(event.subtype, equals(subtype));
      }
    });

    /// Test 10: SocialEvent sin subtype (debería fallar)
    test('SocialEvent.fromMap() - debería fallar sin subtype', () {
      final map = {
        'title': 'Party',
        'imageNames': [],
      };

      try {
        SocialEvent.fromMap(map);
        fail('Debería lanzar FormatException');
      } catch (e) {
        expect(e, isA<FormatException>()); // Pasa si se lanza FormatException
      }
    });
  });

  // ----- MOMENT MODEL TESTS -----
  group('Moment Model Tests', () {
    /// Test 11: Crear Moment válido desde Map
    test('Moment.fromMap() - debería crear un moment válido desde Map', () {
      final map = {
        'userId': 'user_123',
        'type': 'book',
        'title': '1984',
        'date': Timestamp.fromDate(DateTime(2026, 3, 16)),
        'notes': 'Un clasicazo',
        'status': 'Leído',
        'location': 'Casa',
        'imageUrl': 'https://example.com/cover.jpg',
      };

      final moment = Moment.fromMap(map, 'doc_1');

      expect(moment.id, equals('doc_1')); // Dato que generaría Firestore, no viene del Map
      expect(moment.userId, equals('user_123'));
      expect(moment.type, equals(MomentType.book));
      expect(moment.title, equals('1984'));
      expect(moment.date, equals(DateTime(2026, 3, 16)));
      expect(moment.notes, equals('Un clasicazo'));
      expect(moment.status, equals('Leído'));
      expect(moment.location, equals('Casa'));
      expect(moment.imageUrl, equals('https://example.com/cover.jpg'));
    });

    /// Test 12: Los campos opcionales deben ser null si no se proporcionan
    test('Moment.fromMap() - campos opcionales pueden ser null', () {
      final minimalMap = {
        'userId': 'user123',
        'type': 'book',
        'title': '1984',
        'date': Timestamp.fromDate(DateTime(2026, 1, 15)),
      };

      final moment = Moment.fromMap(minimalMap, 'movie123'); // Parámetros: Map mínimo sin campos opcionales y un ID de documento simulado

      expect(moment.notes, isNull);
      expect(moment.status, isNull);
      expect(moment.location, isNull);
      expect(moment.imageUrl, isNull);
    });

    // ----- IDIOMA Y ESTILO MODEL TESTS -----
    /// Test 13: Cambio de idioma funcional
    test('AppLocalizations.translate() - debería cambiar entre ES y EN', () {
      final locEs = AppLocalizations(const Locale('es'));
      final locEn = AppLocalizations(const Locale('en'));

      expect(locEs.translate('save'), equals('Guardar'));
      expect(locEn.translate('save'), equals('Save'));
      // Comprobación de palabras y sus traducciones
      expect(locEs.translate('cancel'), equals('Cancelar'));
      expect(locEn.translate('cancel'), equals('Cancel'));
      expect(locEs.getMonthName(1), equals('Enero'));
      expect(locEn.getMonthName(1), equals('January'));
      expect(locEs.translate('clave_inexistente'), equals('clave_inexistente'));
    });

    /// Test 14: Cambio de estilo funcional
    test('AppTheme - debería definir LIGHT y DARK correctamente', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
    });
  });
}
