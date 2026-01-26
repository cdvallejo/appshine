import 'package:appshine/models/movie_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to add a movie moment to Firestore
  Future<void> addMomentMovie({
    required Movie movie,
    required DateTime date,
    required String location,
    required String notes,
  }) async {
    // Checking if user is logged in
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not identified');

    try {
      // 2. Sending data to Firestore
      await _db.collection('moments').add({
        'userId': user.uid, // Security: who saves it
        'type': 'movie',
        'movieId': movie.id,
        'title': movie.title,
        'year': movie.releaseYear,
        'country': movie.country,
        'director': movie.directors,
        'actors': movie.actors,
        'posterUrl': movie.fullPosterUrl,
        'date': Timestamp.fromDate(date), // Firebase format
        'location': location,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(), // Official server time
      });
    } catch (e) {
      rethrow; // Throws the error so the screen can show a message
    }
  }

  Stream<QuerySnapshot> getMomentsStream() {
  final user = _auth.currentUser;
  if (user == null) throw Exception('User not identified');

  // Query to get moments for the current user, ordered by creation date
  return _db.collection('moments')
      .where('userId', isEqualTo: user.uid)
      .orderBy('date', descending: true)
      .snapshots();
}

  // Function to delete a moment by its ID
  Future<void> deleteMoment(String momentId) async {
    try {
      await _db.collection('moments').doc(momentId).delete();
    } catch (e) {
      debugPrint("Error deleting moment: $e");
    rethrow;
    }
  }
}
