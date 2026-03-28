/// Social event model representing social events.
class SocialEvent {
  static const List<String> subtypes = [
    'Cultural',   // Cine, teatro, museos...
    'Gaming',     // Partidas de rol, videojuegos, mesa...
    'Hangout',    // Cenas, cañas, quedar por quedar (la "Quedada")...
    'Milestone',  // Graduaciones, nacimientos, hitos importantes...
    'Sport',      // Partidos, gimnasio, rutas...
    'Other',      // Lo que no encaje en lo anterior.
  ];

  // TODO: Future user suggestions for tags based on subtype
  static const Map<String, List<String>> tagLibrary = {
  'Cultural': [
    'Cinema',
    'Concert',
    'Exhibition',
    'Festival',
    'Monologue',
    'Museum',
    'Show',
    'Theater',
  ],
  'Hangout': [
    'Birthday',
    'Coffee',
    'Dance',
    'Dining',
    'Meeting',
    'Party',
    'Walk',
  ],
  'Gaming': [
    'Board Games',
    'Escape Room',
    'Roleplay',
    'Video Games',
  ],
  'Sport': [
    'Basketball',
    'Beach Volley', 
    'Cycling',
    'Football',
    'Gym',
    'Hiking',
    'Padel',      
    'Running',
    'Swimming',
    'Tennis',
    'Volley',      
  ],
  'Milestone': [
    'Anniversary',
    'Graduation',
    'Milestone',
    'New Job',
    'New Home',
    'Newborn',
    'Wedding',
  ],
};

  final String title;
  final String subtype;
  final List<String>?
  imageNames; // Filenames of saved images (for future backup with drive!)

  /// Creates a [SocialEvent] model.
  /// 
  /// Parameters:
  /// * [title]: Display title of the event.
  /// * [subtype]: Event subtype (e.g., Cultural, Gaming, Hangout, Sport, Milestone, Other).
  /// * [imageNames]: Optional list of image filenames associated with the event.
  SocialEvent({required this.title, required this.subtype, this.imageNames});

  /// Converts this [SocialEvent] into a Firestore-friendly map.
  ///
  /// Returns:
  /// * A [Map<String, dynamic>] containing [title], [subtype], and [imageNames].
  Map<String, dynamic> toMap() => {
    'title': title,
    'subtype': subtype,
    'imageNames': imageNames,
  };

  /// Creates a [SocialEvent] from Firestore document fields.
  ///
  /// Parameters:
  /// * [map]: Firestore document fields.
  ///
  /// Returns:
  /// * A validated [SocialEvent] instance.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
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
