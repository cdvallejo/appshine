import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

/// Widget to manage image gallery for social events, allowing users to add new images from camera or gallery, and display existing images.
class SocialEventImageGallery extends StatefulWidget {
  final List<String> initialImageNames;
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
  late List<String> _currentImageNames;
  final List<String> _newImageFileNames = [];
  final List<XFile> _newImageFiles = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _filterExistingImages();
  }

  /// Filter and keep only images that physically exist on the device
  Future<void> _filterExistingImages() async {
    final List<String> existingImages = [];
    
    for (String imageName in widget.initialImageNames) {
      final imagePath = await _getImagePath(imageName);
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        existingImages.add(imageName);
      }
    }
    
    setState(() {
      _currentImageNames = existingImages;
    });
    
    // If some images were removed (they don't exist), notify parent
    if (existingImages.length < widget.initialImageNames.length) {
      widget.onImagesChanged?.call();
    }
  }

  /// Get the current image names (existing + new that have been uploaded)
  List<String> getCurrentImageNames() => _currentImageNames;

  /// Get the new image files pending to upload
  List<XFile> getNewImageFiles() => _newImageFiles;

  /// Pick multiple images from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final List<XFile> pickedFiles = source == ImageSource.gallery
          ? await _imagePicker.pickMultiImage()
          : await _imagePicker.pickMultipleMedia().then(
              (files) => files.map((f) => XFile(f.path)).toList(),
            );
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

  /// Upload new images to local cache and add them to the existing list
  /// Returns the complete list of image names after upload
  Future<List<String>> uploadNewImages() async {
    if (_newImageFiles.isEmpty) return _currentImageNames;

    try {
      // Save to Pictures folder so images appear in gallery
      const picturesPath = '/storage/emulated/0/Pictures';
      final appshineImagesDir = Directory('$picturesPath/Appshine Images');

      if (!await appshineImagesDir.exists()) {
        await appshineImagesDir.create(recursive: true);
      }

      final List<String> newFileNames = [];
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < _newImageFiles.length; i++) {
        final XFile imageFile = _newImageFiles[i];
        final File sourceFile = File(imageFile.path);
        // Add counter to ensure unique filenames
        final String fileName = '${baseTimestamp}_${i}_${imageFile.name}';
        final String localPath = '${appshineImagesDir.path}/$fileName';

        await sourceFile.copy(localPath);
        newFileNames.add(fileName);
        
        // Trigger media scanner so the image appears in gallery
        const platform = MethodChannel('com.carlosvallejo.appshine/gallery');
        try {
          await platform.invokeMethod('scanFile', {'path': localPath});
        } catch (e) {
          // Fall back: just try to scan the directory
          try {
            await platform.invokeMethod('scanFile', {'path': appshineImagesDir.path});
          } catch (_) {
            // If method channel fails, it's okay, app will still work
          }
        }
      }

      // Single setState to update all at once
      setState(() {
        _currentImageNames.addAll(newFileNames);
        _newImageFiles.clear();
        _newImageFileNames.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images saved to device')),
        );
      }
      
      // Return the updated list
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

  /// Build the gallery UI
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
        // Buttons to pick images
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
        // Display existing and new images
        if (_currentImageNames.isNotEmpty || _newImageFileNames.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  // Delete the physical file first
                                  final imagePath = await _getImagePath(_currentImageNames[index]);
                                  final imageFile = File(imagePath);
                                  if (await imageFile.exists()) {
                                    await imageFile.delete();
                                  }
                                  // Then remove from list
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
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
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

  /// Helper method to get the full path of an image
  Future<String> _getImagePath(String fileName) async {
    const picturesPath = '/storage/emulated/0/Pictures';
    return '$picturesPath/Appshine Images/$fileName';
  }
}
