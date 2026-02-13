class SocialEvent {
  static const List<String> subtypes = ['Dinner', 'Concert', 'Exhibition', 'Workshop', 'Trip'];

  final String title;
  final String subtype; // 'Dinner', 'Concert', 'Exhibition', 'Workshop', 'Trip'
  final List<String>? images; // User can upload multiple images for a social event

  SocialEvent({required this.title, required this.subtype, this.images});

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtype': subtype,
    'images': images,
  };

  factory SocialEvent.fromMap(Map<String, dynamic> map) {
    return SocialEvent(
      subtype: map['subtype'] ?? 'Dinner',
      images: List<String>.from(map['images'] ?? []),
      title: map['title'] ?? '',
    );
  }

  // Getter to obtain the poster URL (first image or placeholder)
  String get posterUrl => images?.isNotEmpty == true
      ? images!.first
      : 'https://via.placeholder.com/500x300?text=No+Image';

  SocialEvent copyWith({String? title}) {
    return SocialEvent(
      title: title ?? this.title,
      subtype: subtype,
      images: images,
    );
  }
}