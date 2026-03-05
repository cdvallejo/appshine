import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves or updates a Media in the 'media' collection
  /// Returns the ID (mediaId) for reference in moments
  Future<int> _saveOrUpdateMedia(Media media) async {
    try {
      await _db
          .collection('media')
          .doc(media.id.toString())
          .set(media.toFirestore(), SetOptions(merge: true));
      return media.id;
    } catch (e) {
      debugPrint("Error saving media: $e");
      rethrow;
    }
  }

  /// Saves or updates a Book in the 'books' collection
  /// Returns the ID (bookId) for reference in moments
  Future<String> _saveOrUpdateBook(Book book) async {
    try {
      await _db
          .collection('books')
          .doc(book.id)
          .set(book.toFirestore(), SetOptions(merge: true));
      return book.id;
    } catch (e) {
      debugPrint("Error saving book: $e");
      rethrow;
    }
  }

  /// Adds a media viewing moment to Firestore
  /// Separates the Media record (stored in 'media' collection)
  /// from the Moment record (stored in 'moments' collection with only a reference)
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
      // 1. Save or update the Media in the 'media' collection
      final mediaId = await _saveOrUpdateMedia(media);

      // 2. Create a Moment record with reference to the Media
      await _db.collection('moments').add({
        'userId': user.uid, // Security: who saves it
        'type': 'media', // Moment type
        'subtype': subtype,
        'mediaId': mediaId, // Reference to media
        'date': Timestamp.fromDate(date), // Firebase format
        'location': location,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(), // Official server time
      });
    } catch (e) {
      rethrow; // Throws the error so the screen can show a message
    }
  }

  /// Adds a book reading moment to Firestore
  /// Separates the Book record (stored in 'books' collection)
  /// from the Moment record (stored in 'moments' collection with only a reference)
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
      // 1. Save or update the Book in the 'books' collection
      final bookId = await _saveOrUpdateBook(book);

      // 2. Create a Moment record with reference to the Book
      await _db.collection('moments').add({
        'userId': user.uid, // Security: who saves it
        'type': 'book',
        'subtype': subtype,
        'bookId': bookId, // Reference to book
        'date': Timestamp.fromDate(date), // Firebase format
        'location': location,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(), // Official server time
      });
    } catch (e) {
      rethrow; // Throws the error so the screen can show a message
    }
  }

  Future<void> addMomentSocialEvent({
    required SocialEvent socialEvent,
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
        'type': 'socialEvent',
        'subtype': subtype,
        'title': socialEvent.title,
        'date': Timestamp.fromDate(date),
        'location': location,
        'notes': notes,
        'imageNames': socialEvent.imageNames, // Image filenames from model
        'createdAt': FieldValue.serverTimestamp(), // Official server time
      });
    } catch (e) {
      rethrow; // Throws the error so the screen can show a message
    }
  }

  // Function to get a stream of moments for the current user
  Stream<QuerySnapshot> getMomentsStream() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not identified');

    // Query to get moments for the current user, ordered by event date
    return _db
        .collection('moments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  /// Retrieves moments enriched with their associated media/book data
  /// For media moments, fetches the full Media object from the 'media' collection
  /// For book moments, fetches the full Book object from the 'books' collection
  /// Useful for displaying moment details with all media information
  Future<Map<String, dynamic>> getMomentEnriched(String momentId) async {
    try {
      final momentDoc = await _db.collection('moments').doc(momentId).get();
      final momentData = momentDoc.data();

      if (momentData == null) {
        throw Exception('Moment not found');
      }

      // Enrich moment with media or book data based on type
      if (momentData['type'] == 'media' && momentData['mediaId'] != null) {
        final mediaDoc =
            await _db.collection('media').doc(momentData['mediaId'].toString()).get();
        if (mediaDoc.exists) {
          return {
            'moment': momentData,
            'media': mediaDoc.data(),
          };
        }
      } else if (momentData['type'] == 'book' && momentData['bookId'] != null) {
        final bookDoc = await _db.collection('books').doc(momentData['bookId']).get();
        if (bookDoc.exists) {
          return {
            'moment': momentData,
            'book': bookDoc.data(),
          };
        }
      }

      return {'moment': momentData};
    } catch (e) {
      debugPrint("Error fetching enriched moment: $e");
      rethrow;
    }
  }

  /// Get all moments for a specific media (useful for viewing history)
  /// This will be used for the "View History" feature in the future
  Stream<QuerySnapshot> getMomentsByMedia(int mediaId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not identified');

    return _db
        .collection('moments')
        .where('userId', isEqualTo: user.uid)
        .where('mediaId', isEqualTo: mediaId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  /// Get all moments for a specific book (useful for viewing history)
  /// This will be used for the "View History" feature in the future
  Stream<QuerySnapshot> getMomentsByBook(String bookId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not identified');

    return _db
        .collection('moments')
        .where('userId', isEqualTo: user.uid)
        .where('bookId', isEqualTo: bookId)
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
