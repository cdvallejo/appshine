class SocialEvent {
  static const List<String> subtypes = ['Dinner', 'Concert', 'Exhibition', 'Workshop', 'Trip'];

  final String title;
  final String subtype; // 'Dinner', 'Concert', 'Exhibition', 'Workshop', 'Trip'
  final List<String>? imageNames; // Filenames of saved images (for future backup with drive!)

  SocialEvent({
    required this.title,
    required this.subtype,
    this.imageNames,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtype': subtype,
    'imageNames': imageNames,
  };

  /// Factory method to create a SocialEvent from Firestore map data
  /// Throws [FormatException] if required fields are missing or invalid
  factory SocialEvent.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    if (map['title'] == null || (map['title'] is String && (map['title'] as String).isEmpty)) {
      throw FormatException('Missing required field: title');
    }
    if (map['subtype'] == null || (map['subtype'] is String && (map['subtype'] as String).isEmpty)) {
      throw FormatException('Missing required field: subtype');
    }

    final subtype = (map['subtype'] as String).trim();
    if (!subtypes.contains(subtype)) {
      throw FormatException('Invalid subtype: $subtype. Must be one of: ${subtypes.join(", ")}');
    }

    List<String>? imageNames;
    if (map['imageNames'] != null) {
      try {
        imageNames = List<String>.from(map['imageNames'] as List<dynamic>);
      } catch (e) {
        throw FormatException('Invalid imageNames format: expected List<String>');
      }
    }

    return SocialEvent(
      subtype: subtype,
      title: (map['title'] as String).trim(),
      imageNames: imageNames,
    );
  }
}