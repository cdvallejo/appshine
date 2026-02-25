class SocialEvent {
  static const List<String> subtypes = [
    'Coffee', // Momento breve (Café, desayuno)
    'Dining', // Comidas y cenas
    'Hangout', // Quedadas informales / Cañas
    'Concert', // Música en directo
    'Exhibition', // Museos y exposiciones
    'Meeting', // Reuniones de trabajo o TFE
    'Party', // Fiestas y eventos nocturnos
    'Show', // Cine, teatro, monólogos, espectáculos
    'Trip', // Viajes (el contenedor padre)
    'Sport', // Deporte social (partidos, rutas)
    'Workshop', // Cursos, talleres, aprendizaje
  ];
  final String title;
  final String subtype;
  final List<String>? imageNames; // Filenames of saved images (for future backup with drive!)

  SocialEvent({required this.title, required this.subtype, this.imageNames});

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtype': subtype,
    'imageNames': imageNames,
  };

  /// Factory method to create a SocialEvent from Firestore map data
  /// Throws [FormatException] if required fields are missing or invalid
  factory SocialEvent.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    if (map['title'] == null ||
        (map['title'] is String && (map['title'] as String).isEmpty)) {
      throw FormatException('Missing required field: title');
    }
    if (map['subtype'] == null ||
        (map['subtype'] is String && (map['subtype'] as String).isEmpty)) {
      throw FormatException('Missing required field: subtype');
    }

    final subtype = (map['subtype'] as String).trim();
    if (!subtypes.contains(subtype)) {
      throw FormatException(
        'Invalid subtype: $subtype. Must be one of: ${subtypes.join(", ")}',
      );
    }

    List<String>? imageNames;
    if (map['imageNames'] != null) {
      try {
        imageNames = List<String>.from(map['imageNames'] as List<dynamic>);
      } catch (e) {
        throw FormatException(
          'Invalid imageNames format: expected List<String>',
        );
      }
    }

    return SocialEvent(
      subtype: subtype,
      title: (map['title'] as String).trim(),
      imageNames: imageNames,
    );
  }
}
