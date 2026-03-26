import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

/// Service for managing image thumbnails across the app.
///
/// Provides utilities for:
/// * Generating thumbnails with configurable dimensions
/// * Getting image paths (primary, secondary, thumbnail)
/// * Creating directories as needed
///
/// Usage:
/// ```dart
/// // Generate thumbnail for media/book (100×150px)
/// await ImageThumbnailService.generateThumbnail(originalPath, thumbnailPath);
///
/// // Generate thumbnail for social events (150×150px)
/// await ImageThumbnailService.generateThumbnail(
///   originalPath,
///   thumbnailPath,
///   width: 150,
///   height: 150,
/// );
/// ```
class ImageThumbnailService {
  /// Returns the path to the primary image in app's documents directory.
  ///
  /// This is the authoritative copy of the image.
  /// Path: `getApplicationDocumentsDirectory/Appshine Images/{fileName}`
  static Future<String> getImagePath(String fileName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/Appshine Images/$fileName';
  }

  /// Returns the path to the thumbnail in app's documents directory.
  ///
  /// Path: `getApplicationDocumentsDirectory/Appshine Thumbnails/{fileName}`
  static Future<String> getThumbnailPath(String fileName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/Appshine Thumbnails/$fileName';
  }

  /// Returns the path to the secondary image in the Pictures folder.
  ///
  /// This is a copy for Android gallery visibility.
  /// Path: `/storage/emulated/0/Pictures/Appshine Images/{fileName}`
  static String getPicturesImagePath(String fileName) {
    const picturesPath = '/storage/emulated/0/Pictures';
    return '$picturesPath/Appshine Images/$fileName';
  }

  /// Generates a thumbnail from the original image with specified dimensions.
  ///
  /// Respects the original aspect ratio by resizing first, then centering and cropping.
  /// This ensures images are always displayed without distortion.
  ///
  /// Process:
  /// 1. Decode the original image
  /// 2. Resize the shorter dimension to fit (maintaining aspect ratio)
  /// 3. Center crop to get exactly [width]×[height]px
  /// 4. Save with quality 85
  ///
  /// Parameters:
  ///   * [originalPath] - Path to the original image file
  ///   * [thumbnailPath] - Path where the thumbnail will be saved
  ///   * [width] - Target thumbnail width in pixels (default: 100 for media/books)
  ///   * [height] - Target thumbnail height in pixels (default: 150 for media/books)
  static Future<void> generateThumbnail(
    String originalPath,
    String thumbnailPath, {
    int width = 100,
    int height = 150,
  }) async {
    try {
      final originalFile = File(originalPath);
      
      // 1. Decode the original image
      final image = img.decodeImage(originalFile.readAsBytesSync());
      if (image == null) return;

      // 2. Define target size
      final int targetWidth = width;
      final int targetHeight = height;

      // 3. Resize the shorter dimension to fit the target size
      img.Image resizedImage;
      if (image.width / image.height > targetWidth / targetHeight) {
        // Original is too wide, resize by height
        resizedImage = img.copyResize(image, height: targetHeight);
      } else {
        // Original is too tall, resize by width
        resizedImage = img.copyResize(image, width: targetWidth);
      }

      // 4. Center crop to get exact size
      final thumbnail = img.copyCrop(
        resizedImage,
        x: (resizedImage.width - targetWidth) ~/ 2,  // Center horizontally
        y: (resizedImage.height - targetHeight) ~/ 2, // Center vertically
        width: targetWidth,
        height: targetHeight,
      );

      // 5. Save with good quality
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
    } catch (e) {
      // Silently fail - thumbnail generation is non-critical
      // The app can fall back to the full image if needed
    }
  }

  /// Downloads an image from a URL (media/book poster from API), saves it locally,
  /// and generates a thumbnail with specified dimensions.
  ///
  /// This is used for media and book moments where the image comes from an API URL
  /// (Firebase Storage). The process:
  /// 1. Downloads the image from the URL
  /// 2. Saves it to "Appshine Images" (NO gallery copy for API images)
  /// 3. Generates a thumbnail with center crop
  ///
  /// Note: Gallery copies are created ONLY for social events, not for API images.
  ///
  /// Parameters:
  ///   * [imageUrl] - The URL to download the image from
  ///   * [fileName] - The filename to save as (e.g., "movie_123.jpg")
  ///   * [width] - Target thumbnail width in pixels (default: 100)
  ///   * [height] - Target thumbnail height in pixels (default: 150)
  ///
  /// Returns:
  ///   The path to the generated thumbnail, or null if download/generation failed
  static Future<String?> downloadAndGenerateThumbnail(
    String imageUrl,
    String fileName, {
    int width = 100,
    int height = 150,
  }) async {
    try {
      // 1. Download the image from URL
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDocDir.path}/Appshine Images');
      final thumbnailsDir = Directory('${appDocDir.path}/Appshine Thumbnails');

      // Create directories if they don't exist
      if (!imagesDir.existsSync()) {
        await imagesDir.create(recursive: true);
      }
      if (!thumbnailsDir.existsSync()) {
        await thumbnailsDir.create(recursive: true);
      }

      // 2. Save the original image locally
      final imagePath = '${imagesDir.path}/$fileName';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(response.bodyBytes);

      // 3. Generate thumbnail from the downloaded image
      final thumbnailPath = '${thumbnailsDir.path}/$fileName';
      await generateThumbnail(imagePath, thumbnailPath, width: width, height: height);

      return thumbnailPath;
    } catch (e) {
      return null;
    }
  }
}