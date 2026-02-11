class SocialEvent {
  final List<String> images; // User can upload multiple images for a social event

  SocialEvent({required this.images});

  // To save it inside the Moment map in Firestore
  Map<String, dynamic> toMap() => {
    'images': images,
  };

  factory SocialEvent.fromMap(Map<String, dynamic> map) {
    return SocialEvent(
      images: List<String>.from(map['images'] ?? []),
    );
  }
}