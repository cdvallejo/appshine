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

  /// Factory constructor to create a Moment instance from a Firestore document
  /// Throws [FormatException] if required fields are missing or invalid
  factory Moment.fromMap(Map<String, dynamic> map, String docId) {
    // Validate required fields
    if (map['userId'] == null || (map['userId'] is String && (map['userId'] as String).isEmpty)) {
      throw FormatException('Missing required field: userId');
    }
    if (map['type'] == null || (map['type'] is String && (map['type'] as String).isEmpty)) {
      throw FormatException('Missing required field: type');
    }
    if (map['title'] == null || (map['title'] is String && (map['title'] as String).isEmpty)) {
      throw FormatException('Missing required field: title');
    }
    if (map['date'] == null) {
      throw FormatException('Missing required field: date');
    }

    // Safe enum parsing with validation
    final typeString = map['type'] as String;
    final type = MomentType.values.cast<MomentType?>().firstWhere(
      (e) => e?.name == typeString,
      orElse: () => null,
    );
    if (type == null) {
      throw FormatException('Invalid type: $typeString. Must be one of: ${MomentType.values.map((e) => e.name).join(", ")}');
    }

    // Validate and parse date
    DateTime date;
    try {
      date = (map['date'] as Timestamp).toDate();
    } catch (e) {
      throw FormatException('Invalid date format: expected Timestamp');
    }

    return Moment(
      id: docId,
      userId: (map['userId'] as String).trim(),
      type: type,
      title: (map['title'] as String).trim(),
      date: date,
      notes: map['notes'] as String?,
      status: map['status'] as String?,
      location: map['location'] as String?,
      imageUrl: map['imageUrl'] as String?,
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
