import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

/// Widget to manage image gallery for social events.
///
/// Allows users to:
/// - Select multiple images from camera or gallery simultaneously
/// - Preview existing images saved locally on the device
/// - Preview newly selected images before saving
/// - Delete both existing and new images
/// - Upload new images to local device storage (/storage/emulated/0/Pictures/Appshine Images)
///
/// Images are stored locally on the device, not on Firebase Storage.
/// Only image filenames are saved to Firestore for reference.
///
/// **Key features:**
/// - Automatic validation: filters out deleted image files on load
/// - Multi-select support: pick multiple images in one action
/// - Dual view: shows existing images separately from newly added ones
/// - File deletion: removes physical files when images are deleted
/// - Media scanner: notifies Android that new files were added
///
/// **Usage:**
/// ```dart
/// SocialEventImageGallery(
///   initialImageNames: event.imageNames,
///   onImagesChanged: () => setState(() {}),
/// )
/// ```
class SocialEventImageGallery extends StatefulWidget {
  /// List of existing image filenames saved in this moment
  final List<String> initialImageNames;
  
  /// Callback fired when images are added, removed, or filtered
  final VoidCallback? onImagesChanged;

  const SocialEventImageGallery({
    super.key,
    required this.initialImageNames,
    this.onImagesChanged,
  });

  @override
  State<SocialEventImageGallery> createState() =>
      _SocialEventImageGalleryState();
}

class _SocialEventImageGalleryState extends State<SocialEventImageGallery> {
  /// List of validated image names that physically exist on the device
  /// Updated after filtering out deleted files
  late List<String> _currentImageNames;
  
  /// Filenames of newly selected images (not yet saved to device)
  final List<String> _newImageFileNames = [];
  
  /// File objects of newly selected images (pending save)
  final List<XFile> _newImageFiles = [];
  
  /// Image picker plugin instance for selecting images
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize immediately with initial names to prevent late initialization error
    // This ensures _currentImageNames is always accessible from the start
    _currentImageNames = List.from(widget.initialImageNames);
    
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
    
    // Check each image filename to see if the file still exists
    for (String imageName in widget.initialImageNames) {
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

  /// Returns the current list of validated existing image names
  /// (existing images that are saved to Firestore)
  List<String> getCurrentImageNames() => _currentImageNames;

  /// Returns the list of newly selected image files
  /// (not yet saved to device or Firestore)
  List<XFile> getNewImageFiles() => _newImageFiles;

  /// Opens image picker to select multiple images from camera or gallery.
  ///
  /// **Parameters:**
  /// - [source]: ImageSource.camera for camera, ImageSource.gallery for gallery
  ///
  /// **Behavior:**
  /// - Gallery: allows selecting multiple images at once
  /// - Camera: uses pickMultipleMedia for batch photos
  /// - Selected images are stored in [_newImageFiles] and [_newImageFileNames]
  /// - Notifies parent when images are added
  Future<void> _pickImage(ImageSource source) async {
    try {
      final List<XFile> pickedFiles = source == ImageSource.gallery
          ? await _imagePicker.pickMultiImage()
          : (await _imagePicker.pickImage(source: ImageSource.camera) != null
              ? [await _imagePicker.pickImage(source: ImageSource.camera)]
              : []).whereType<XFile>().toList();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImageFiles.addAll(pickedFiles);
          _newImageFileNames.addAll(pickedFiles.map((f) => f.name));
        });
        widget.onImagesChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  /// Saves newly selected images to local device storage.
  ///
  /// **Process:**
  /// 1. Creates the Appshine Images directory if it doesn't exist
  /// 2. Copies each selected image file to the directory
  /// 3. Triggers Android media scanner so images appear in gallery app
  /// 4. Returns the updated complete list of image names
  ///
  /// **Important:**
  /// - Images are saved to: /storage/emulated/0/Pictures/Appshine Images/
  /// - Only filenames are stored in Firestore, not actual file data
  /// - Media scanner broadcast ensures images are visible in Android gallery
  ///
  /// **Returns:**
  /// Complete list of all image names (existing + newly saved)
  ///
  /// **Throws:**
  /// Rethrows exceptions for parent to handle
  Future<List<String>> uploadNewImages() async {
    if (_newImageFiles.isEmpty) return _currentImageNames;

    try {
      // Save to Pictures folder so images appear in Android gallery app
      const picturesPath = '/storage/emulated/0/Pictures';
      final appshineImagesDir = Directory('$picturesPath/Appshine Images');

      if (!await appshineImagesDir.exists()) {
        // Create directory with recursive flag (creates parent folders if needed)
        await appshineImagesDir.create(recursive: true);
      }

      final List<String> newFileNames = [];
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Process each newly selected image
      for (int i = 0; i < _newImageFiles.length; i++) {
        final XFile imageFile = _newImageFiles[i];
        final File sourceFile = File(imageFile.path);
        
        // Create unique filename using timestamp + counter + original name
        // This prevents collisions if multiple images selected at same millisecond
        final String fileName = '${baseTimestamp}_${i}_${imageFile.name}';
        final String localPath = '${appshineImagesDir.path}/$fileName';

        // Copy file from temporary gallery location to permanent storage
        await sourceFile.copy(localPath);
        newFileNames.add(fileName);
        
        // Notify Android media scanner that new file was added
        // This makes the image appear immediately in Android Gallery app
        const platform = MethodChannel('com.carlosvallejo.appshine/gallery');
        try {
          await platform.invokeMethod('scanFile', {'path': localPath});
        } catch (e) {
          // Fall back: try to scan the entire directory if individual file fails
          try {
            await platform.invokeMethod('scanFile', {'path': appshineImagesDir.path});
          } catch (_) {
            // If method channel fails completely, it's okay - app will still work
            // Images will appear in gallery on next rescan
          }
        }
      }

      // Update UI: add newly saved images to existing list and clear pending list
      setState(() {
        _currentImageNames.addAll(newFileNames);
        _newImageFiles.clear();
        _newImageFileNames.clear();
      });
      
      // Return the complete updated list for parent to store in Firestore
      return _currentImageNames;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving images: $e')),
        );
      }
      rethrow;
    }
  }

  /// Builds the gallery UI with image pickers and preview sections.
  ///
  /// **UI Structure:**
  /// 1. Title "Images"
  /// 2. Camera and Gallery buttons (side by side)
  /// 3. Existing Images section (if any exist)
  /// 4. New Images section (if any selected)
  /// 5. Empty state message (if no images)
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                const Text('Existing Images:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                future: _getImagePath(_currentImageNames[index]),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Center(
                                          child: CircularProgressIndicator()),
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
                                              Icons.image_not_supported),
                                        );
                                },
                              ),
                            ),
                            // Red delete button overlay
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  // Delete the physical file from device storage first
                                  final imagePath = await _getImagePath(_currentImageNames[index]);
                                  final imageFile = File(imagePath);
                                  if (await imageFile.exists()) {
                                    await imageFile.delete();
                                  }
                                  // Then remove filename from list
                                  // This will be saved to Firestore when user saves the event
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
                const Text('New Images:',
                    style: TextStyle(fontSize: 12, color: Colors.green)),
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
            child: const Text(
              'No images added yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  /// Converts an image filename to its full device file path.
  ///
  /// **Path structure:** /storage/emulated/0/Pictures/Appshine Images/{fileName}
  ///
  /// This method is used to:
  /// - Load image files for preview
  /// - Check if image files still exist
  /// - Delete image files when requested by user
  ///
  /// **Parameters:**
  /// - [fileName]: The image filename (e.g., "1234567890_0_photo.jpg")
  ///
  /// **Returns:**
  /// The complete absolute file path to the image
  ///
  /// **Example:**
  /// ```dart
  /// final path = await _getImagePath('1234567890_0_photo.jpg');
  /// // Returns: /storage/emulated/0/Pictures/Appshine Images/1234567890_0_photo.jpg
  /// ```
  Future<String> _getImagePath(String fileName) async {
    const picturesPath = '/storage/emulated/0/Pictures';
    return '$picturesPath/Appshine Images/$fileName';
  }
}
