class SocialEvent {
  static const List<String> subtypes = ['Dinner', 'Concert', 'Exhibition', 'Workshop', 'Trip'];

  final String title;
  final String subtype; // 'Dinner', 'Concert', 'Exhibition', 'Workshop', 'Trip'

  SocialEvent({required this.title, required this.subtype});

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtype': subtype,
  };

  factory SocialEvent.fromMap(Map<String, dynamic> map) {
    return SocialEvent(
      subtype: map['subtype'] ?? 'Dinner',
      title: map['title'] ?? '',
    );
  }
}