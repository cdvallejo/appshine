import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to add a media moment to Firestore
  Future<void> addMomentMedia({
    required Media media,
    required DateTime date,
    required String location,
    required String notes,
    required String subtype,
  }) async {
    // Checking if user is logged in
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not identified');

    try {
      // 2. Sending data to Firestore
      await _db.collection('moments').add({
        'userId': user.uid, // Security: who saves it
        'type': 'audiovisual', // Moment type
        'subtype': subtype,
        'mediaId': media.id,
        'title': media.title,
        'year': media.releaseYear,
        'country': media.country,
        'director': media.directors,
        'creators': media.creators,
        'actors': media.actors,
        'imageUrl': media.imageUrl,
        'date': Timestamp.fromDate(date), // Firebase format
        'location': location,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(), // Official server time
      });
    } catch (e) {
      rethrow; // Throws the error so the screen can show a message
    }
  }

  Future<void> addMomentBook({
    required Book book, 
    required DateTime date, 
    required String location, 
    required String notes,
    required String subtype,
    }) async {
      // Checking if user is logged in
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not identified');

    try {
      // 2. Sending data to Firestore
      await _db.collection('moments').add({
        'userId': user.uid, // Security: who saves it
        'type': 'book',
        'subtype': subtype,
        'bookId': book.id,
        'title': book.title,
        'authors': book.authors,
        'publishedDate': book.publishedDate,
        'isbn': book.isbn,
        'publisher': book.publisher,
        'imageUrl': book.fullCoverUrl,
        'pageCount': book.pageCount,
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

  // Function to update a moment's notes
  Future<void> updateMoment(String momentId, Map<String, dynamic> data) async {
  try {
    await _db.collection('moments').doc(momentId).update(data);
  } catch (e) {
    debugPrint("Error al actualizar: $e");
    rethrow;
  }
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
