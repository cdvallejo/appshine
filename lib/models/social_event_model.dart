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

  factory SocialEvent.fromMap(Map<String, dynamic> map) {
    return SocialEvent(
      subtype: map['subtype'] ?? 'Dinner',
      title: map['title'] ?? '',
      imageNames: map['imageNames'] != null ? List<String>.from(map['imageNames']) : null,
    );
  }
}