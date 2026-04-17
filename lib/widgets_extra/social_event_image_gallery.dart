import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:appshine/utils/image_thumbnail_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Widget to manage image gallery for social events.
///
/// Allows users to select multiple images from camera or gallery, preview existing
/// and newly selected images, and delete images. Images are stored locally on the device,
/// not on Firebase Storage. Only image filenames are saved to Firestore for reference.
class SocialEventImageGallery extends StatefulWidget {
  /// List of existing image filenames saved in this moment (optional).
  /// If not provided, defaults to empty list.
  final List<String>? initialImageNames;

  /// Callback fired when images are added, removed, or filtered
  final VoidCallback? onImagesChanged;

  /// Creates a new instance of [SocialEventImageGallery].
  ///
  /// Parameters:
  /// * [initialImageNames]: Optional list of existing image filenames saved in this moment.
  /// * [onImagesChanged]: Callback fired when images are added, removed, or filtered.
  const SocialEventImageGallery({
    super.key,
    this.initialImageNames,
    this.onImagesChanged,
  });

  @override
  State<SocialEventImageGallery> createState() =>
      SocialEventImageGalleryState();
}

/// State for [SocialEventImageGallery].
///
/// Manages the list of existing image filenames and newly selected images,
/// including image picking, saving, and deletion logic.
class SocialEventImageGalleryState extends State<SocialEventImageGallery> {
  /// List of validated image names that physically exist on the device
  late List<String> _currentImageNames;

  /// Filenames of newly selected images (not yet saved to device)
  final List<String> _newImageFileNames = [];

  /// File objects of newly selected images (pending save)
  final List<XFile> _newImageFiles = [];

  /// Image picker plugin instance for selecting images
  final ImagePicker _imagePicker = ImagePicker();

  /// Initializes the state by validating existing image files and setting up the current image list.
  @override
  void initState() {
    super.initState();
    // Initialize _currentImageNames, always accessible from the start
    _currentImageNames = List.from(widget.initialImageNames ?? []);

    // Then validate image files asynchronously in the background
    // This filters out any images whose files were deleted manually
    _filterExistingImages();
  }

  /// Validates that all stored image files still exist on the device.
  ///
  /// When editing an event, images might have been deleted manually from the
  /// file system (e.g., via file manager). This method filters the list to
  /// only include images whose files still exist.
  ///
  /// Runs asynchronously to avoid blocking the UI during initialization.
  /// Only triggers a rebuild if the list actually changed.
  Future<void> _filterExistingImages() async {
    final List<String> existingImages = [];
    final initialNames = widget.initialImageNames ?? [];

    // Check each image filename to see if the file still exists
    for (String imageName in initialNames) {
      final imagePath = await _getImagePath(imageName);
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        existingImages.add(imageName);
      }
    }

    // Only update if the list changed (avoid unnecessary rebuilds)
    if (existingImages.length != _currentImageNames.length) {
      setState(() {
        _currentImageNames = existingImages;
      });

      // Notify parent widget that images were filtered/removed
      widget.onImagesChanged?.call();
    }
  }

  /// Returns the current list of validated existing image names that are saved to Firestore
  List<String> getCurrentImageNames() => _currentImageNames;

  /// Returns images that were deleted (exist in past list but not in current list)
  List<String> getDeletedImageNames(List<String> originalNames) {
    return originalNames
        .where((name) => !_currentImageNames.contains(name))
        .toList();
  }

  /// Returns newly selected image files (not yet saved to device)
  List<XFile> getNewImageFiles() => _newImageFiles;

  /// Opens image picker to select multiple images from camera or gallery.
  ///
  /// Behavior:
  /// * Gallery: allows selecting multiple images at once.
  /// * Camera: captures a single photo.
  /// * Selected images are stored in [_newImageFiles] and [_newImageFileNames].
  /// * Notifies parent via [onImagesChanged] callback.
  ///
  /// Parameters:
  /// * [source]: The image source (camera or gallery).
  Future<void> _pickImage(ImageSource source) async {
    try {
      final List<XFile> pickedFiles;
      if (source == ImageSource.gallery) {
        pickedFiles = await _imagePicker.pickMultiImage();
      } else {
        // Camera: call pickImage once and wrap result in list if not null
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          requestFullMetadata: false,
        );
        pickedFiles = pickedFile != null ? [pickedFile] : [];
      }

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImageFiles.addAll(pickedFiles);
          _newImageFileNames.addAll(pickedFiles.map((f) => f.name));
        });
        widget.onImagesChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  /// Saves newly selected images to local device storage.
  ///
  /// Process:
  /// * Saves the primary copy to app's documents directory (safe, no special permissions needed).
  /// * Creates a secondary copy in Pictures folder for visibility in Android gallery.
  /// * Triggers Android media scanner so images appear in gallery app.
  /// * Returns the updated complete list of image names.
  ///
  /// Returns:
  /// * A [List<String>] of all image filenames (existing + newly saved).
  ///
  /// Notes:
  /// * Primary storage: `getApplicationDocumentsDirectory/Appshine Images/`
  /// * Gallery copy: `/storage/emulated/0/Pictures/Appshine Images/`
  /// * Only filenames are stored in Firestore, not actual file data.
  /// * Media scanner broadcast ensures images are visible in Android gallery.

  Future<List<String>> uploadNewImages() async {
    if (_newImageFiles.isEmpty) return _currentImageNames;

    try {
      // Request WRITE_EXTERNAL_STORAGE permission for Android (API 26+)
      final loc = AppLocalizations.of(context);
      final PermissionStatus status = await Permission.photos.request();
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('errorSavingImages')),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return _currentImageNames;
      }

      // Get app's documents directory for primary storage
      final appDocDir = await getApplicationDocumentsDirectory();

      final appshineImagesDir = Directory('${appDocDir.path}/Appshine Images');

      if (!await appshineImagesDir.exists()) {
        await appshineImagesDir.create(recursive: true);
      }

      // Prepare Pictures directory for gallery visibility
      const picturesPath = '/storage/emulated/0/Pictures';
      final galleryImagesDir = Directory('$picturesPath/Appshine Images');

      if (!await galleryImagesDir.exists()) {
        await galleryImagesDir.create(recursive: true);
      }

      // Create thumbnails directory
      final thumbnailsDir = Directory('${appDocDir.path}/Appshine Thumbnails');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      final List<String> newFileNames = [];
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Process each newly selected image
      for (int i = 0; i < _newImageFiles.length; i++) {
        try {
          final XFile imageFile = _newImageFiles[i];
          final File sourceFile = File(imageFile.path);

          final String fileName = '${baseTimestamp}_${i}_${imageFile.name}';

          // Save PRIMARY copy to app's documents directory
          final String appDocPath = '${appshineImagesDir.path}/$fileName';
          await sourceFile.copy(appDocPath);
          newFileNames.add(fileName);

          // Generate and save thumbnail (150×150px square for social events)
          final String thumbnailPath = '${thumbnailsDir.path}/$fileName';
          await ImageThumbnailService.generateThumbnail(
            appDocPath,
            thumbnailPath,
            width: 150,
            height: 150,
          );

          // Save SECONDARY copy to Pictures folder for gallery visibility
          final String galleryPath = '${galleryImagesDir.path}/$fileName';
          await sourceFile.copy(galleryPath);

          // Notify Android media scanner
          const platform = MethodChannel('com.carlosvallejo.appshine/gallery');
          try {
            await platform.invokeMethod('scanFile', {'path': galleryPath});
          } catch (e) {
            try {
              await platform.invokeMethod('scanFile', {
                'path': galleryImagesDir.path,
              });
            } catch (_) {
              // Media scanner is non-critical
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving image ${i + 1}: $e'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }

      // Update UI: add newly saved images to existing list and clear pending list
      setState(() {
        _currentImageNames.addAll(newFileNames);
        _newImageFiles.clear();
        _newImageFileNames.clear();
      });

      return _currentImageNames;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving images: $e')));
      }
      rethrow;
    }
  }

  /// Builds the gallery UI with image pickers and preview sections.
  ///
  /// Returns:
  /// * A [Column] widget containing:
  ///   * Title "Images"
  ///   * Camera and Gallery buttons (side by side)
  ///   * Existing Images section (if any exist)
  ///   * New Images section (if any selected)
  ///   * Empty state message (if no images)
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // BUTTONS: Camera and Gallery pickers (allow multi-select)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_currentImageNames.isNotEmpty || _newImageFileNames.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: Display already existing images (validated, file exists)
              if (_currentImageNames.isNotEmpty) ...[
                const Text(
                  'Existing Images:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentImageNames.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<String>(
                                future: _getImagePath(
                                  _currentImageNames[index],
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final imagePath = snapshot.data!;
                                  final imageFile = File(imagePath);
                                  return imageFile.existsSync()
                                      ? Image.file(
                                          imageFile,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                          ),
                                        );
                                },
                              ),
                            ),
                            // Red delete button overlay
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  // Just remove from list - actual file deletion happens when user saves (checks)
                                  setState(() {
                                    _currentImageNames.removeAt(index);
                                  });
                                  widget.onImagesChanged?.call();
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_newImageFileNames.isNotEmpty) const SizedBox(height: 12),
              ],
              // SECTION 2: Display newly selected images (pending save)
              // These are shown in a different color to indicate they're not saved yet
              if (_newImageFileNames.isNotEmpty) ...[
                const Text(
                  'New Images:',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImageFileNames.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_newImageFiles[index].path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Delete button for newly selected images
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  // Just remove from pending lists (file still exists in temp location)
                                  setState(() {
                                    _newImageFiles.removeAt(index);
                                    _newImageFileNames.removeAt(index);
                                  });
                                  widget.onImagesChanged?.call();
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          )
        else
          // Empty state: no images added yet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Text(
              loc.translate('noImagesAdded'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  /// Deletes an image file from both storage locations.
  ///
  /// Removes the image from:
  /// * Primary: app's documents directory (`getApplicationDocumentsDirectory`)
  /// * Secondary: Pictures folder (`/storage/emulated/0/Pictures/Appshine Images/`)
  ///
  /// Parameters:
  /// * [fileName]: The image filename to delete.
  Future<void> deleteImageFile(String fileName) async {
    try {
      // Delete from primary location (app documents directory)
      final primaryPath = await _getImagePath(fileName);
      final primaryFile = File(primaryPath);

      if (await primaryFile.exists()) {
        await primaryFile.delete();
      }

      // Delete from secondary location (Pictures folder)
      const picturesPath = '/storage/emulated/0/Pictures';
      final galleryPath = '$picturesPath/Appshine Images/$fileName';
      final galleryFile = File(galleryPath);

      if (await galleryFile.exists()) {
        await galleryFile.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting image: $e')));
      }
    }
  }

  /// Converts an image filename to its full device file path.
  ///
  /// Parameters:
  /// * [fileName]: The image filename (\"1234_0_photo.jpg\").
  ///
  /// Returns:
  /// * The complete absolute file path to the primary image location in app documents.
  ///
  /// Path structure: `getApplicationDocumentsDirectory/Appshine Images/{fileName}`
  Future<String> _getImagePath(String fileName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/Appshine Images/$fileName';
  }
}
