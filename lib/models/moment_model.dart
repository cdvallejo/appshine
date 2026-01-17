import 'package:cloud_firestore/cloud_firestore.dart';

enum MomentType {
  movie,
  book,
  social
}

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

  // Specific fields for different moment types
  final int? tmdbId;
  final String? director;
  final String? author;
  final List<String>? people;

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
    this.tmdbId,
    this.director,
    this.author,
    this.people,
  });

factory Moment.fromMap(Map<String, dynamic> map, String docId) {
    return Moment(
      id: docId,
      userId: map['userId'] ?? '',
      
      // Safe enum parsing with fallback
      type: MomentType.values.firstWhere(
        (e) => e.name == map['type'], 
        orElse: () => MomentType.social
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
      tmdbId: map['tmdbId'] is String ? int.tryParse(map['tmdbId']) : map['tmdbId'], // Handle String to int conversion is not an int
      director: map['director'],
      author: map['author'],
      people: map['people'] != null ? List<String>.from(map['people']) : null,
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
      'tmdbId': tmdbId,
      'director': director,
      'author': author,
      'people': people,
    };
  }
}
