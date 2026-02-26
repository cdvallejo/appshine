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

      // Settings Screen
      'language': 'IDIOMA',
      'spanish': 'Español',
      'english': 'English',
      'theme': 'TEMA',
      'darkMode': 'Modo oscuro',
      'insights': 'Insights',
      'insightsComing': 'Insights - Próximamente',
      'closeSessionTitle': 'Cerrar sesión',
      'closeSessionMessage': '¿Estás seguro de que quieres cerrar sesión?',

      // Media Screen
      'addMovieMoment': 'Añadir Momento de Película',
      'selectSubtype': 'Seleccionar subtipo',
      'year': 'Año',
      'country': 'País',
      'director': 'Director/es',
      'cast': 'Reparto',
      'creator': 'Creador/es',
      'date': 'Fecha',
      'location': 'Ubicación',
      'myNotes': 'Mis Notas',
      'writeNote': 'Escribe aquí una nota.',
      'momentSaved': 'Momento guardado!',
      'savingError': 'Error guardando el momento: ',
      'pleaseSelectSubtype': 'Por favor selecciona un subtipo',
      'changesSaved': 'Cambios guardados correctamente',
      'unknownCountry': 'País desconocido',
      'unknown': 'Desconocido',

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

      // Moment Detail Screen
      'detail': 'Detalle',
      'deleteConfirmTitle': 'Eliminar momento',
      'deleteConfirmMessage': '¿Estás seguro? Esta acción no se puede deshacer.',

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

      // Settings Screen
      'language': 'LANGUAGE',
      'spanish': 'Español',
      'english': 'English',
      'theme': 'THEME',
      'darkMode': 'Dark mode',
      'insights': 'Insights',
      'insightsComing': 'Insights - Coming soon',
      'closeSessionTitle': 'Close session',
      'closeSessionMessage': 'Are you sure you want to close the session?',

      // Media Screen
      'addMovieMoment': 'Add Movie Moment',
      'selectSubtype': 'Select subtype',
      'year': 'Year',
      'country': 'Country',
      'director': 'Director/s',
      'cast': 'Cast',
      'creator': 'Creator/s',
      'date': 'Date',
      'location': 'Location',
      'myNotes': 'My Notes',
      'writeNote': 'Write here a note.',
      'momentSaved': 'Moment saved!',
      'savingError': 'Error saving moment: ',
      'pleaseSelectSubtype': 'Please select a subtype',
      'changesSaved': 'Changes saved successfully',
      'unknownCountry': 'Unknown country',
      'unknown': 'Unknown',

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
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return translate(monthKeys[month - 1]);
  }

  String getWeekdayName(int weekday) {
    const dayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    return translate(dayKeys[weekday - 1]);
  }
}

// Class bridge to connect the AppLocalizations with the Flutter localization system
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
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
