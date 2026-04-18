import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:appshine/utils/image_thumbnail_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validates that the current user exists in Firebase Auth.
  /// Reloads user data from server to detect if account was deleted.
  /// 
  /// Throws:
  ///   * Exception if user is not authenticated
  ///   * Exception if user was deleted from Firebase Auth
  Future<void> _validateUserExists() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated'); // Check if user is in local cache

    try {
      await user.reload(); // Reload user data from server to detect if account was deleted
    } catch (e) {
      throw Exception('User authentication invalid: $e');
    }
  }

  /// Adds a media moment to Firestore for the current user.
  /// Validates that the user exists and is authenticated before attempting to save.
  /// 
  /// Parameters:
  /// * [media]: The media object containing details about the movie or TV show
  /// * [date]: The date of the moment
  /// * [location]: The location where the moment took place
  /// * [notes]: User's notes about the moment
  /// * [subtype]: The subtype of the media (e.g., "movie", "tv_show")
  /// 
  /// Throws:
  /// * [Exception] if user is not authenticated or account was deleted
  /// * [Exception] if Firestore operation fails or times out
  Future<void> addMomentMedia({
    required Media media,
    required DateTime date,
    required String location,
    required String notes,
    required String subtype,
  }) async {
    // Validate user exists and is authenticated
    await _validateUserExists();
    
    final user = _auth.currentUser; // Get the current user after validation
    if (user == null) throw Exception('User not identified'); // Extra check validation

    try {
      // 1. Download image from API and generate thumbnail (if imageUrl available)
      String? fileName;
      if (media.imageUrl != null && media.imageUrl!.isNotEmpty) {
        final imageUrl = media.imageUrl!;
        fileName = 'media_${media.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await ImageThumbnailService.downloadAndGenerateThumbnail(
          imageUrl,
          fileName,
        );
      }

      // 2. Sending data to Firestore
      await _db.collection('moments').add({
        'userId': user.uid, // Security: who saves it
        'type': 'media', // Moment type
        'subtype': subtype,
        'mediaId': media.id,
        'title': media.title,
        'year': media.releaseYear,
        'country': media.country,
        'directors': media.directors,
        'creators': media.creators,
        'screenwriters': media.screenwriters,
        'genres': media.genres,
        'cast': media.cast,
        'imageUrl': media.imageUrl,
        'imageFileName': fileName, // Store filename for local and thumbnail
        'date': Timestamp.fromDate(date), // Firebase format
        'location': location,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(), // Official server time
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Save operation timed out. Data saved offline and will sync when connection is restored.'),
      );
    } catch (e) {
      rethrow; // Throws the error so the screen can show a message
    }
  }

  /// Adds a book moment to Firestore for the current user.
  /// Validates that the user exists and is authenticated before attempting to save.
  /// 
  /// Parameters:
  /// * [book]: The book object containing details about the book
  /// * [date]: The date of the moment
  /// * [location]: The location where the moment took place
  /// * [notes]: User's notes about the moment
  /// * [subtype]: The subtype of the book moment
  /// 
  /// Throws:
  /// * [Exception] if user is not authenticated or account was deleted
  /// * [Exception] if Firestore operation fails or times out
  Future<void> addMomentBook({
    required Book book,
    required DateTime date,
    required String location,
    required String notes,
    required String subtype,
  }) async {
    // Validate user exists and is authenticated
    await _validateUserExists();
    
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not identified');

    try {
      // 1. Download image from API and generate thumbnail (if imageUrl available)
      String? fileName;
      if (book.imageUrl != null && book.imageUrl!.isNotEmpty) {
        final imageUrl = book.fullCoverUrl; // Use fullCoverUrl which handles placeholder
        fileName = 'book_${book.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await ImageThumbnailService.downloadAndGenerateThumbnail(
          imageUrl,
          fileName,
        );
      }

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
        'imageFileName': fileName, // Store filename for local thumbnail
        'pageCount': book.pageCount,
        'date': Timestamp.fromDate(date), // Firebase format
        'location': location,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(), // Official server time
      }).timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw Exception('Save operation timed out. Data saved offline and will sync when connection is restored.'),
      );
    } catch (e) {
      rethrow; // Throws the error so the screen can show a message
    }
  }

  /// Adds a social event moment to Firestore for the current user.
  /// Validates that the user exists and is authenticated before attempting to save.
  /// 
  /// Parameters:
  /// * [socialEvent]: The social event object containing details about the event
  /// * [date]: The date of the moment
  /// * [location]: The location where the moment took place
  /// * [notes]: User's notes about the moment
  /// * [subtype]: The subtype of the social event moment
  /// 
  /// Throws:
  /// * [Exception] if user is not authenticated or account was deleted
  /// * [Exception] if Firestore operation fails or times out
  Future<void> addMomentSocialEvent({
    required SocialEvent socialEvent,
    required DateTime date,
    required String location,
    required String notes,
    required String subtype,
  }) async {
    // Validate user exists and is authenticated
    await _validateUserExists();
    
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
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Save operation timed out. Data saved offline and will sync when connection is restored.'),
      );
    } catch (_) {
      rethrow;
    }
  }

  /// Retrieves a stream of moments for the current user, ordered by date.
  /// Validates that the user exists and is authenticated before returning the stream.
  /// 
  /// Returns:
  /// * [Stream<QuerySnapshot>]: A stream of moments for the current user, ordered by date
  /// 
  /// Throws:
  /// * [Exception] if user is not authenticated or account was deleted
  /// * [Exception] if Firestore operation fails or times out
  Stream<QuerySnapshot> getMomentsStream() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate user exists before returning stream
    _validateUserExists().then((_) {
      // User is valid
    }).catchError((e) {
      debugPrint('User validation error in getMomentsStream: $e');
    });

    // Query to get moments for the current user, ordered by event date
    return _db
        .collection('moments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  /// Updates a moment's details in Firestore.
  /// Validates that the user exists and is authenticated before attempting to update.
  /// 
  /// Parameters:
  /// * [momentId]: The ID of the moment to update
  /// * [data]: The updated data for the moment
  /// 
  /// Throws:
  /// * [Exception] if user is not authenticated or account was deleted
  /// * [Exception] if Firestore operation fails or times out
  Future<void> updateMoment(String momentId, Map<String, dynamic> data) async {
    // Validate user exists and is authenticated
    await _validateUserExists();
    
    try {
      await _db.collection('moments').doc(momentId).update(data).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Update operation timed out. Changes saved offline and will sync when connection is restored.'),
      );
      
    } catch (_) {
      rethrow;
    }
  }

  /// Deletes a moment by its ID.
  /// Validates that the user exists and is authenticated before attempting to delete.
  /// Cleans up associated files:
  /// * For social events: deletes all image files from disk
  /// * For media/books: deletes local thumbnail files
  /// 
  /// Parameters:
  /// * [momentId]: The ID of the moment to delete
  /// * [imageNames]: Optional list of image filenames to delete (for social events)
  /// * [momentType]: Optional type of moment ('socialEvent', 'media', 'book')
  /// * [imageFileName]: Optional filename of the thumbnail (for media/books)
  /// 
  /// Throws:
  /// * [Exception] if user is not authenticated or account was deleted
  /// * [Exception] if Firestore operation fails or times out
  Future<void> deleteMoment(
    String momentId, {
    List<String>? imageNames,
    String? momentType,
    String? imageFileName,
  }) async {
    // Validate user exists and is authenticated
    await _validateUserExists();
    
    try {
      // Delete image files from disk if it's a social event
      if (momentType == 'socialEvent' && imageNames != null && imageNames.isNotEmpty) {
        await _deleteImageFilesFromAppDirectory(imageNames);
      }
      
      // Delete thumbnail file if it's media or book
      if ((momentType == 'media' || momentType == 'book') && imageFileName != null) {
        await _deleteThumbnailFile(imageFileName);
      }
      
      // Then delete from Firestore
      await _db.collection('moments').doc(momentId).delete().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Delete operation timed out. Changes saved offline and will sync when connection is restored.'),
      );
      
    } catch (_) { 
      rethrow;
    }
  }

  /// Deletes image files from app's primary storage directory only.
  /// This frees up app storage while keeping a copy in the Pictures folder for recovery.
  /// Also deletes corresponding thumbnails to keep directories clean.
  /// 
  /// Parameters:
  /// * [imageNames]: List of image filenames to delete from app directory
  Future<void> _deleteImageFilesFromAppDirectory(List<String> imageNames) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      for (String imageName in imageNames) {
        // Delete original image from primary location (app documents directory)
        final primaryPath = '${appDocDir.path}/Appshine Images/$imageName';
        final primaryFile = File(primaryPath);
        if (await primaryFile.exists()) {
          await primaryFile.delete();
        }
        
        // Also delete corresponding thumbnail (social events generate thumbnails too)
        final thumbnailPath = '${appDocDir.path}/Appshine Thumbnails/$imageName';
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
        // NOTE: Pictures folder copy is intentionally kept for recovery purposes
      }
    } catch (e) {
      // Don't rethrow - continue with Firestore deletion even if file deletion fails
    }
  }

  /// Deletes image and thumbnail files for media/book moments.
  /// Removes both the original image and generated thumbnail from app's documents directory.
  /// 
  /// Deletes from:
  /// * Appshine Images/{fileName} - Original downloaded image from API
  /// * Appshine Thumbnails/{fileName} - Generated thumbnail (100×150)
  /// 
  /// Parameters:
  /// * [imageFileName]: The image filename (same name used for both original and thumbnail)
  Future<void> _deleteThumbnailFile(String imageFileName) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      // Delete original image from Appshine Images
      final imagePath = '${appDocDir.path}/Appshine Images/$imageFileName';
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      
      // Delete thumbnail from Appshine Thumbnails
      final thumbnailPath = '${appDocDir.path}/Appshine Thumbnails/$imageFileName';
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    } catch (e) {
      // Don't rethrow - continue with Firestore deletion even if file deletion fails
    }
  }
}
