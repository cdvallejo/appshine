import 'package:appshine/data/database_service.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AddMomentScreenSocialEvent extends StatefulWidget {
  final SocialEvent socialEvent;
  const AddMomentScreenSocialEvent({super.key, required this.socialEvent});

  @override
  State<AddMomentScreenSocialEvent> createState() =>
      _AddMomentScreenSocialEventState();
}

class _AddMomentScreenSocialEventState
    extends State<AddMomentScreenSocialEvent> {
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _titleController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<String> _selectedImages = [];
  final List<XFile> _selectedImageFiles = [];
  final List<String> _selectedImageNames = []; // Only filenames (for backup compatibility)

  DateTime _selectedDate = DateTime.now();
  String? _selectedSubtype;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.socialEvent.title; // Here receive the title from the previous screen!
  }
  
  // Let user pick an image from camera or gallery, and add it to the pending list (_selectedImageFiles)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFiles.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImages(AppLocalizations loc) async {
    // Saves selected images to local cache and updates _selectedImages with their local paths
    // Images are NOT uploaded to Firebase Storage, only their names. Saved locally on the device.
    if (_selectedImageFiles.isEmpty) return;

    try {
      // Obtain the app's documents directory to save images locally
      final appDir = await getApplicationDocumentsDirectory();
      
      // Create a subdirectory for social event images if it doesn't exist
      final socialEventsDir = Directory('${appDir.path}/social_events');
      if (!await socialEventsDir.exists()) {
        // If the directory doesn't exist, create it (recursive: true to create any intermediate folders if needed)
        await socialEventsDir.create(recursive: true);
      }

      // For each selected image file, copy it to the new location and save its local path
      for (XFile imageFile in _selectedImageFiles) {
        // Obtén el archivo original desde galería/cámara
        final File sourceFile = File(imageFile.path);
        
        // Create a unique file name using timestamp and original name to avoid conflicts
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
        
        // Define local path where the image will be saved
        final String localPath = '${socialEventsDir.path}/$fileName';
        
        // Copy the file to the new location
        await sourceFile.copy(localPath);

        // Add local path and filename to lists
        // _selectedImages: full path for UI display
        // _selectedImageNames: only filename for Firestore (backup compatible)
        setState(() {
          _selectedImages.add(localPath);
          _selectedImageNames.add(fileName);
        });
      }

      // Clean the pending list of selected image files since they are now saved
      setState(() {
        _selectedImageFiles.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('imagesSavedDevice'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.translate('errorSavingImages')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('addEventMoment')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // 1. Validate subtype is selected
              if (_selectedSubtype == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('selectEventSubtype'))),
                );
                return;
              }

              // 2. If there are new images pending to save, save them first to local cache and update _selectedImages with their local paths
              if (_selectedImageFiles.isNotEmpty) {
                try {
                  await _uploadImages(loc);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${loc.translate('errorSavingImages')}: $e')),
                    );
                  }
                  return;
                }
              }

              // 3. Async function to save the moment
              try {
                // Create a new SocialEvent with the image names before saving
                final socialEventWithImages = SocialEvent(
                  title: _titleController.text,
                  subtype: _selectedSubtype!,
                  imageNames: _selectedImageNames.isNotEmpty ? _selectedImageNames : null,
                );

                await DatabaseService().addMomentSocialEvent(
                  socialEvent: socialEventWithImages,
                  date: _selectedDate,
                  location: _locationController.text,
                  notes: _notesController.text,
                  subtype: _selectedSubtype!,
                );

                // 5. If everything goes well, notify the user and close
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.translate('momentSaved'))),
                  );
                  Navigator.pop(context);
                }
              } catch (error) {
                // 6. If there was an error, show it
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${loc.translate('savingError')}: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field (editable)
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),

              // Subtype dropdown
              DropdownButton<String>(
                isExpanded: true,
                hint: Text(loc.translate('selectEventType')),
                value: _selectedSubtype,
                items: SocialEvent.subtypes
                    .map(
                      (subtype) => DropdownMenuItem(
                        value: subtype,
                        child: Text(subtype),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubtype = value;
                  });
                },
              ),

              const SizedBox(height: 4),
              const Divider(height: 40),

              /* PART IMAGES SECTION:
              1. User press "Camera" or "Gallery" → _pickImage()
              XFile is added to _selectedImageFiles (pending files to save)
              2. XFile is displayed in "Selected files" section (not yet saved, just preview)
              (_selectedImages is still unchanged, it only contains already saved images)
              3. User press "Save moment" en appbar
              4. Calls _uploadImages():
              - Save each XFile to local cache and get its local path
              - Add local path to _selectedImages (which is showing the "Saved images" section)
              - Clean _selectedImageFiles (pending list) because its now saved
              5. Finally, save the data moment to Firestore. No Firebase storage involved for images, only local cache */
              Text(
                loc.translate('images'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Buttons to pick images (camera/gallery)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(loc.translate('camera')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.image),
                      label: Text(loc.translate('gallery')),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              // IMAGES PENDING TO SAVE (just picked, not saved yet)
              if (_selectedImageFiles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImageFiles.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_selectedImageFiles[index].path),
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
                                        _selectedImageFiles.removeAt(index);
                                      });
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
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Text(
                    loc.translate('noImagesAdded'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 4),
              const Divider(height: 40),
              Row(
                children: [
                  // Date field (flex 1)
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 24,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Location field (flex 2)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 24,
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_pin,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: _locationController,
                                  onTap: () => _locationController.clear(),
                                  decoration: InputDecoration(
                                    hintText: loc.translate('where'),
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 0,
                                        ),
                                    border: UnderlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // PART BOTTOM SECTION: NOTES
              const SizedBox(height: 20),
              Text(
                loc.translate('myNotes'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: loc.translate('writeNote'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
