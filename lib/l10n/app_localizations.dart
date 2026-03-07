import 'package:flutter/material.dart';

/// Localization support for the Appshine application.
///
/// This class provides translations for Spanish ('es') and English ('en').
/// It manages all user-facing strings in the application and provides
/// convenience methods for accessing common translations and generating
/// localized subtype names for different moment types (Media, Book, SocialEvent).
///
/// Usage:
/// ```dart
/// final loc = AppLocalizations.of(context);
/// String translated = loc.translate('key');
/// ```
class AppLocalizations {
  /// The [Locale] associated with this localization instance.
  final Locale locale;

  /// Creates a new [AppLocalizations] instance with the given [locale].
  AppLocalizations(this.locale);

  /// Retrieves the [AppLocalizations] instance from the given [context].
  ///
  /// This method follows the standard Flutter localization pattern
  /// using an InheritedWidget's "of" syntax. If no localization
  /// is available in the context, defaults to Spanish ('es').
  ///
  /// Parameters:
  ///   * [context] - The build context from which to retrieve localizations.
  ///
  /// Returns:
  ///   The [AppLocalizations] instance, or a Spanish locale instance if not found.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

  /// Map of all localized strings organized by language and key.
  ///
  /// Structure: language code ('es', 'en') -> translation key -> translated string
  static const Map<String, Map<String, String>> _localizedStrings = {
    'es': {
      // App & Navigation
      'settings': 'Configuración',
      'logout': 'Cerrar sesión',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'edit': 'Editar',
      'delete': 'Eliminar',

      // Login Screen
      'login': 'Iniciar Sesión',
      'register': 'Registro Appshine',
      'email': 'Email',
      'password': 'Contraseña',
      'enterButton': 'Entrar',
      'registerButton': 'Registrarse',
      'noAccount': '¿No tienes cuenta? Regístrate aquí',
      'hasAccount': '¿Ya tienes cuenta? Inicia sesión',

      // Home Screen
      'welcome': 'Bienvenido, Admin',
      'untitled': 'Sin título',
      'movieOrTv': 'Película | Serie de TV',
      'bookOrComic': 'Libro | Cómic',
      'socialEvent': 'Evento Social',
      'addNewMoment': 'Añadir nuevo momento',

      // Settings Screen
      'language': 'IDIOMA',
      'spanish': 'Español',
      'english': 'Inglés',
      'theme': 'TEMA',
      'darkMode': 'Modo oscuro',
      'insights': 'Insights',
      'insightsComing': 'Insights - Próximamente',
      'closeSessionTitle': 'Cerrar sesión',
      'closeSessionMessage': '¿Estás seguro de que quieres cerrar sesión?',

      // General fields
      'writeNote': 'Escribe aquí una nota.',
      'myNotes': 'Mis Notas',
      'momentSaved': 'Momento guardado!',
      'savingError': 'Error guardando el momento: ',
      'pleaseSelectSubtype': 'Por favor selecciona un subtipo',
      'year': 'Año',
      'country': 'País',
      'changesSaved': 'Cambios guardados correctamente',
      'unknownCountry': 'País desconocido',
      'unknown': 'Desconocido',
      'newEvent': 'Nuevo Evento',
      'where': 'Añadir ubicación',
      'searchByTitle': 'Buscar por título',
      'noNotes': 'No hay notas...',

      // Search delegate
      'typeToSearch': 'Escribe para buscar y pulsa el botón de búsqueda',
      'noMoviesFound': 'No se han encontrado películas',
      'noBooksFound': 'No se han encontrado libros',

      // Media Screen
      'addMovieMoment': 'Añadir Momento de Película',
      'selectMediaSubtype': 'Seleccionar película o serie',
      'movie': 'Película',
      'tvSeries': 'Serie de TV',
      'directors': 'Dirección',
      'cast': 'Reparto',
      'creator': 'Creador/es',

      // Book Screen
      'addBookMoment': 'Añadir Momento de Libro',
      'selectBookType': 'Seleccionar tipo de libro',
      'novel': 'Novela',
      'comic': 'Cómic',
      'essay': 'Ensayo',
      'sheetMusic': 'Partitura',
      'other': 'Otro',
      'title': 'Título',
      'author': 'Autor/es',
      'pages': 'Páginas',
      'publisher': 'Editorial',
      'isbn': 'ISBN',

      // Social Event Screen
      'addEventMoment': 'Añadir Evento Social',
      'selectEventType': 'Seleccionar tipo de evento',
      'selectEventSubtype': 'Selecciona un subtipo',
      'cultural': 'Cultural',
      'gaming': 'Juegos',
      'social': 'Social',
      'sport': 'Deporte',
      'gallery': 'Galería',
      'camera': 'Cámara',
      'noImagesAdded': 'No hay imágenes añadidas',
      'imagesSavedDevice': 'Imágenes guardadas en el dispositivo',
      'errorSavingImages': 'Error al guardar imágenes',

      // Moment Detail Screen
      'detail': 'Detalle',
      'deleteConfirmTitle': 'Eliminar momento',
      'deleteConfirmMessage':
          '¿Estás seguro? Esta acción no se puede deshacer.',

      // Update Moment Sheet
      'editMoment': 'Editar momento',
      'saveChanges': 'Guardar cambios',

      // Insights Screen
      'myMoments': 'Mis momentos',
      'momentsTotal': 'Momentos registrados',
      'statisticsByType': 'Estadística por tipo',

      // Messages
      'noMoments': 'No hay momentos',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'ok': 'Ok',
      'yes': 'Sí',
      'no': 'No',

      // Months
      'january': 'Enero',
      'february': 'Febrero',
      'march': 'Marzo',
      'april': 'Abril',
      'may': 'Mayo',
      'june': 'Junio',
      'july': 'Julio',
      'august': 'Agosto',
      'september': 'Septiembre',
      'october': 'Octubre',
      'november': 'Noviembre',
      'december': 'Diciembre',

      // Days
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',

      // Admin
      'admin': 'Admin',
    },

    //  -- ENGLISH translations --
    'en': {
      // App & Navigation
      'settings': 'Settings',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',

      // Login Screen
      'login': 'Login',
      'register': 'Appshine Sign Up',
      'email': 'Email',
      'password': 'Password',
      'enterButton': 'Enter',
      'registerButton': 'Register',
      'noAccount': 'Don\'t have an account? Register here',
      'hasAccount': 'Already have an account? Login',

      // Home Screen
      'welcome': 'Welcome, Admin',
      'untitled': 'Untitled',
      'movieOrTv': 'Movie | TV Series',
      'bookOrComic': 'Book | Comic',
      'socialEvent': 'Social Event',
      'addNewMoment': 'Add new moment',

      // General fields
      'writeNote': 'Write here a note.',
      'myNotes': 'My Notes',
      'year': 'Year',
      'country': 'Country',
      'momentSaved': 'Moment saved!',
      'savingError': 'Error saving the moment: ',
      'pleaseSelectSubtype': 'Please select a subtype',
      'changesSaved': 'Changes saved successfully',
      'unknownCountry': 'Unknown country',
      'unknown': 'Unknown',
      'newEvent': 'New Event',
      'where': 'Add location',
      'searchByTitle': 'Search by title',
      'searchByAuthor': 'Search by author',
      'noNotes': 'No notes...',
      'other': 'Other',

      // Search delegate
      'typeToSearch': 'Type to search and press the search button',
      'noMoviesFound': 'No movies found',
      'noBooksFound': 'No books found',

      // Settings Screen
      'language': 'LANGUAGE',
      'spanish': 'Spanish',
      'english': 'English',
      'theme': 'THEME',
      'darkMode': 'Dark mode',
      'insights': 'Insights',
      'insightsComing': 'Insights - Coming soon',
      'closeSessionTitle': 'Close session',
      'closeSessionMessage': 'Are you sure you want to close the session?',

      // Media Screen
      'addMovieMoment': 'Add Movie Moment',
      'selectMediaSubtype': 'Select movie or TV Series',
      'movie': 'Movie',
      'tvSeries': 'TV Series',
      'directors': 'Direction',
      'cast': 'Cast',
      'creator': 'Creator',

      // Book Screen
      'addBookMoment': 'Add Book Moment',
      'selectBookType': 'Select book type',
      'novel': 'Novel',
      'comic': 'Comic',
      'essay': 'Essay',
      'sheetMusic': 'Sheet Music',
      'title': 'Title',
      'author': 'Author/s',
      'pages': 'Pages',
      'publisher': 'Publisher',
      'isbn': 'ISBN',

      // Social Event Screen
      'addEventMoment': 'Add Social Event Moment',
      'selectEventType': 'Select event type',
      'selectEventSubtype': 'Please select a subtype',
      'cultural': 'Cultural',
      'gaming': 'Gaming',
      'social': 'Social',
      'sport': 'Sport',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'noImagesAdded': 'No images added yet',
      'imagesSavedDevice': 'Images saved to device',
      'errorSavingImages': 'Error saving images',

      // Moment Detail Screen
      'detail': 'Detail',
      'deleteConfirmTitle': 'Delete moment',
      'deleteConfirmMessage': 'Are you sure? This action cannot be undone.',

      // Insights Screen
      'myMoments': 'My moments',
      'momentsTotal': 'Total moments',
      'statisticsByType': 'Statistics by type',

      // Messages
      'noMoments': 'No moments',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'ok': 'Ok',
      'yes': 'Yes',
      'no': 'No',

      // Update Moment Sheet
      'editMoment': 'Edit moment',
      'saveChanges': 'Save changes',

      // Months
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',

      // Days
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',

      // Admin
      'admin': 'Admin',
    },
  };

  /// Translates a localization key to the corresponding string in the current locale.
  ///
  /// Looks up the translation key in the current language's dictionary.
  /// If the key is not found, returns the key itself as a fallback.
  ///
  /// Parameters:
  ///   * [key] - The localization key to translate.
  ///
  /// Returns:
  ///   The translated string, or the key if translation not found.
  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ?? key;
  }

  // ========================================
  // CONVENIENCE GETTERS FOR FREQUENTLY USED STRINGS
  // ========================================

  /// Translated string for 'Settings'.
  String get settings => translate('settings');

  /// Translated string for 'Logout'.
  String get logout => translate('logout');

  /// Translated string for 'Cancel'.
  String get cancel => translate('cancel');

  /// Gets the localized name of a month.
  ///
  /// Parameters:
  ///   * [month] - The month number (1-12).
  ///
  /// Returns:
  ///   The translated month name for the given month number.
  String getMonthName(int month) {
    const monthKeys = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    return translate(monthKeys[month - 1]);
  }

  /// Gets the localized name of a weekday.
  ///
  /// Parameters:
  ///   * [weekday] - The weekday number (1-7, where 1 = Monday).
  ///
  /// Returns:
  ///   The translated weekday name for the given weekday number.
  String getWeekdayName(int weekday) {
    const dayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return translate(dayKeys[weekday - 1]);
  }

  /// Gets the translation key for any moment subtype based on type.
  ///
  /// Routes to the appropriate subtype key getter based on moment type.
  /// Single entry point for translating all moment subtypes.
  ///
  /// Parameters:
  ///   * [type] - The moment type ('media', 'book', 'socialEvent')
  ///   * [subtype] - The subtype name
  ///
  /// Returns:
  ///   The translation key for the subtype
  static String getSubtypeKey(String type, String subtype) {
    switch (type) {
      case 'media':
        return getMediaSubtypeKey(subtype);
      case 'book':
        return getBookSubtypeKey(subtype);
      case 'socialEvent':
        return getSocialEventSubtypeKey(subtype);
      default:
        return 'unknown';
    }
  }

  /// Gets the translation key for a book subtype.
  ///
  /// Parameters:
  ///   * [subtype] - The subtype of the book (e.g., Novel, Comic, Essay).
  ///
  /// Returns:
  ///   The translation key for the subtype.
  static String getBookSubtypeKey(String subtype) {
    final subtypeLower = subtype.toLowerCase();
    if (subtypeLower.contains('novel')) return 'novel';
    if (subtypeLower.contains('comic')) return 'comic';
    if (subtypeLower.contains('essay')) return 'essay';
    if (subtypeLower.contains('sheet')) return 'sheetMusic';
    if (subtypeLower.contains('other')) return 'other';
    return 'unknown';
  }

  /// Gets the translation key for a media subtype.
  ///
  /// Parameters:
  ///   * [subtype] - The subtype of the media (e.g., Movie, TV Series).
  ///
  /// Returns:
  ///   The translation key for the subtype.
  static String getMediaSubtypeKey(String subtype) {
    final subtypeLower = subtype.toLowerCase();
    if (subtypeLower.contains('movie')) return 'movie';
    if (subtypeLower.contains('tv')) return 'tvSeries';
    return 'unknown';
  }

  /// Gets the translation key for a social event subtype.
  ///
  /// Parameters:
  ///   * [subtype] - The subtype of the social event (e.g., Cultural, Gaming, Sport).
  ///
  /// Returns:
  ///   The translation key for the subtype.
  static String getSocialEventSubtypeKey(String subtype) {
    final subtypeLower = subtype.toLowerCase();
    if (subtypeLower.contains('cultural')) return 'cultural';
    if (subtypeLower.contains('gaming')) return 'gaming';
    if (subtypeLower.contains('social')) return 'social';
    if (subtypeLower.contains('sport')) return 'sport';
    if (subtypeLower.contains('other')) return 'other';
    return 'unknown';
  }
}

/// Delegate for loading [AppLocalizations] instances.
///
/// This class bridges the [AppLocalizations] with the Flutter localization system.
/// It is responsible for determining supported locales and instantiating
/// localization objects for the application.
///
/// Supported languages: Spanish ('es'), English ('en')
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  /// Creates a new [AppLocalizationsDelegate].
  const AppLocalizationsDelegate();

  /// Determines whether the given [locale] is supported by this app.
  ///
  /// Currently supports Spanish ('es') and English ('en').
  ///
  /// Parameters:
  ///   * [locale] - The locale to check for support.
  ///
  /// Returns:
  ///   true if the locale's language code is supported, false otherwise.
  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  /// Loads the localization for the given [locale].
  ///
  /// Parameters:
  ///   * [locale] - The locale for which to load localization strings.
  ///
  /// Returns:
  ///   A Future that resolves to an [AppLocalizations] instance.
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  /// Determines whether to reload localization data.
  ///
  /// Returns false to indicate that localization data is stable
  /// and does not need to be reloaded when the delegate changes.
  ///
  /// Parameters:
  ///   * [old] - The old [AppLocalizationsDelegate] instance.
  ///
  /// Returns:
  ///   false - localization data is never reloaded.
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
