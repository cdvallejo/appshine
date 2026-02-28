import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

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
      'myMoments': 'Mis momentos',
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
      'typeToSearch': 'Escribe para buscar y presiona el botón de búsqueda',
      'where': 'Añadir ubicación',
      'searchByTitle': 'Buscar por título',
      'noNotes': 'No hay notas...',

      // Media Screen
      'addMovieMoment': 'Añadir Momento de Película',
      'selectSubtype': 'Seleccionar película o serie',
      'director': 'Dirección',
      'cast': 'Reparto',
      'creator': 'Creador/es',

      // Book Screen
      'addBookMoment': 'Añadir Momento de Libro',
      'selectBookType': 'Seleccionar tipo de libro',
      'title': 'Título',
      'author': 'Autor/es',
      'pages': 'Páginas',
      'publisher': 'Editorial',
      'isbn': 'ISBN',

      // Social Event Screen
      'addEventMoment': 'Añadir Momento Social',
      'selectEventType': 'Seleccionar tipo de evento',
      'selectEventSubtype': 'Selecciona un subtipo',
      'gallery': 'Galería',
      'noImagesAdded': 'No hay imágenes añadidas',
      'imagesSavedDevice': 'Imágenes guardadas en el dispositivo',
      'errorSavingImages': 'Error al guardar imágenes',

      // Moment Detail Screen
      'detail': 'Detalle',
      'deleteConfirmTitle': 'Eliminar momento',
      'deleteConfirmMessage': '¿Estás seguro? Esta acción no se puede deshacer.',

      // Update Moment Sheet
      'editMoment': 'Editar momento',
      'saveChanges': 'Guardar cambios',

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
      'myMoments': 'My Moments',
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
      'typeToSearch': 'Type to search and press the search button',
      'where': 'Add location',
      'searchByTitle': 'Search by title',
      'searchByAuthor': 'Search by author',
      'noNotes': 'No notes...',

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
      'selectSubtype': 'Select movie or TV Series',
      'director': 'Director',
      'cast': 'Cast',
      'creator': 'Creator',


      // Book Screen
      'addBookMoment': 'Add Book Moment',
      'selectBookType': 'Select book type',
      'title': 'Title',
      'author': 'Author/s',
      'pages': 'Pages',
      'publisher': 'Publisher',
      'isbn': 'ISBN',

      // Social Event Screen
      'addEventMoment': 'Add Social Event Moment',
      'selectEventType': 'Select event type',
      'selectEventSubtype': 'Please select a subtype',
      'gallery': 'Gallery',
      'noImagesAdded': 'No images added yet',
      'imagesSavedDevice': 'Images saved to device',
      'errorSavingImages': 'Error saving images',

      // Moment Detail Screen
      'detail': 'Detail',
      'deleteConfirmTitle': 'Delete moment',
      'deleteConfirmMessage': 'Are you sure? This action cannot be undone.',

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

  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for common strings
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get login => translate('login');
  String get cancel => translate('cancel');
  String get year => translate('year');
  String get country => translate('country');
  String get director => translate('director');
  String get cast => translate('cast');
  String get myNotes => translate('myNotes');
  String get date => translate('date');
  String get location => translate('location');
  String get momentSaved => translate('momentSaved');

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
}

// Class bridge to connect the AppLocalizations with the Flutter localization system
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  // Supported languages
  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
