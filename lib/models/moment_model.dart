import 'package:cloud_firestore/cloud_firestore.dart';

enum MomentType { audiovisual, book, socialEvent }

// Model class for a Moment
class Moment {
  final String? id;
  final String userId;
  final MomentType type;
  final String subtype; // FUTURE ADD - book type, media type, event type, etc.
  final String title;
  final DateTime date;
  final String? notes;
  final String? status;
  final String? location;
  final String? imageUrl;
  // Future ADD - hashtags, states, rating, etc.

  // Tus subtipos iniciales
  static const Map<MomentType, List<String>> defaultSubtypes = {
    MomentType.audiovisual: ['Movie', 'TV Series'],
    MomentType.book: [
      'Novel',
      'Manga',
      'Comic',
      'Essay',
      'Technical',
      'Sheet music',
    ],
    MomentType.socialEvent: ['Dinner', 'Concert', 'Exhibition', 'Workshop', 'Trip'],
  };

  Moment({
    this.id,
    required this.userId,
    required this.type, // Enum for type
    required this.subtype, // Subtype for specific moment types
    required this.title,
    required this.date,
    this.notes,
    this.status,
    this.location,
    this.imageUrl,
  });

  factory Moment.fromMap(Map<String, dynamic> map, String docId) {
    return Moment(
      id: docId,
      userId: map['userId'] ?? '',
      subtype: map['subtype'] ?? '',
      // Safe enum parsing with fallback
      type: MomentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MomentType.socialEvent, // Default to socialEvent if type is missing or unrecognized
      ),

      title: map['title'] ?? 'Untitled',

      // If 'date' is missing or null, use current date as fallback
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),

      // ----------------------------------------------------
      notes: map['notes'],
      status: map['status'],
      location: map['location'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'status': status,
      'location': location,
      'imageUrl': imageUrl,
      'subtype': subtype,
    };
  }
}
