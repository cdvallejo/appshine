import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    _currentImageNames = List.from(widget.initialImageNames);
  }

  /// Get the current image names (existing + new that have been uploaded)
  List<String> getCurrentImageNames() => _currentImageNames;

  /// Get the new image files pending to upload
  List<XFile> getNewImageFiles() => _newImageFiles;

  /// Pick an image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _newImageFiles.add(pickedFile);
          _newImageFileNames.add(pickedFile.name);
        });
        widget.onImagesChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  /// Upload new images to local cache and add them to the existing list
  /// Returns the complete list of image names after upload
  Future<List<String>> uploadNewImages() async {
    if (_newImageFiles.isEmpty) return _currentImageNames;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final socialEventsDir = Directory('${appDir.path}/social_events');

      if (!await socialEventsDir.exists()) {
        await socialEventsDir.create(recursive: true);
      }

      final List<String> newFileNames = [];
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < _newImageFiles.length; i++) {
        final XFile imageFile = _newImageFiles[i];
        final File sourceFile = File(imageFile.path);
        // Add counter to ensure unique filenames
        final String fileName = '${baseTimestamp}_${i}_${imageFile.name}';
        final String localPath = '${socialEventsDir.path}/$fileName';

        await sourceFile.copy(localPath);
        newFileNames.add(fileName);
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
                                onTap: () {
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
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/social_events/$fileName';
  }
}
