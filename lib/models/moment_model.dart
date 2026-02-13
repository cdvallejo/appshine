import 'package:cloud_firestore/cloud_firestore.dart';

enum MomentType { media, book, socialEvent }

// Model class for a Moment
class Moment {
  final String? id;
  final String userId;
  final MomentType type;
  final String title;
  final DateTime date;
  final String? notes;
  final String? status;
  final String? location;
  final String? imageUrl;
  // Future ADD - hashtags, states, rating, etc.

  Moment({
    this.id,
    required this.userId,
    required this.type, // Enum for type
    required this.title,
    required this.date,
    this.notes,
    this.status,
    this.location,
    this.imageUrl,
  });

  // Factory constructor to create a Moment instance from a Firestore document
  factory Moment.fromMap(Map<String, dynamic> map, String docId) {
    return Moment(
      id: docId,
      userId: map['userId'] ?? '',
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

  // Method to convert a Moment instance to a map for Firestore storage
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
    };
  }
}
