import 'package:appshine/data/database_service.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

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
  final List<XFile> _selectedImageFiles = [];
  final List<String> _selectedImageNames = []; // Only filenames (for backup compatibility)

  DateTime _selectedDate = DateTime.now();
  String? _selectedSubtype;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.socialEvent.title; // Here receive the title from the previous screen!
  }
  
  // Let user pick multiple images from camera or gallery, and add them to the pending list (_selectedImageFiles)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final List<XFile> pickedFiles = source == ImageSource.gallery
          ? await _imagePicker.pickMultiImage()
          : await _imagePicker.pickMultipleMedia().then(
              (files) => files.map((f) => XFile(f.path)).toList(),
            );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImageFiles.addAll(pickedFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _uploadImages(AppLocalizations loc) async {
    // Saves selected images to Pictures folder (gallery-accessible)
    // Images are NOT uploaded to Firebase Storage, only their names. Saved locally on the device.
    if (_selectedImageFiles.isEmpty) return;

    try {
      // Save to Pictures folder so images appear in gallery
      const picturesPath = '/storage/emulated/0/Pictures';
      final appshineImagesDir = Directory('$picturesPath/Appshine Images');
      
      if (!await appshineImagesDir.exists()) {
        // If the directory doesn't exist, create it (recursive: true to create any intermediate folders if needed)
        await appshineImagesDir.create(recursive: true);
      }

      // For each selected image file, copy it to the new location and save its local path
      for (XFile imageFile in _selectedImageFiles) {
        // Obtén el archivo original desde galería/cámara
        final File sourceFile = File(imageFile.path);
        
        // Create a unique file name using timestamp and original name to avoid conflicts
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
        
        // Define local path where the image will be saved
        final String localPath = '${appshineImagesDir.path}/$fileName';
        
        // Copy the file to the new location
        await sourceFile.copy(localPath);

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

        // Add local path and filename to lists
        // _selectedImageNames: only filename for Firestore (backup compatible)
        setState(() {
          _selectedImageNames.add(fileName);
        });
      }

      // Clean the pending list of selected image files since they are now saved
      setState(() {
        _selectedImageFiles.clear();
      });
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

              // 2. If there are new images pending to save, save them first to local cache and update the image names list
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
                hint: Text(loc.translate('selectEventSubtype')),
                value: _selectedSubtype,
                items: SocialEvent.subtypes
                    .map(
                      (subtype) => DropdownMenuItem(
                        value: subtype,
                        child: Text(loc.translate(_getSocialEventSubtypeKey(subtype))),
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
              3. User press "Save moment" en appbar
              4. Calls _uploadImages() via SocialEventImageGallery:
              - Save each XFile to local cache and get its filename
              - Add filename to _selectedImageNames (which is saved to Firestore)
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
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
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
  /// Gets the localized translation key for a social event subtype.
  ///
  /// Maps social event subtypes to their translation keys.
  ///
  /// Parameters:
  ///   * [subtype] - The subtype of the social event (e.g., Concert, Party).
  ///
  /// Returns:
  ///   The translation key for the subtype.
  String _getSocialEventSubtypeKey(String subtype) {
    final subtypeLower = subtype.toLowerCase();
    if (subtypeLower.contains('cultural')) return 'cultural';
    if (subtypeLower.contains('gaming')) return 'gaming';
    if (subtypeLower.contains('social')) return 'social';
    if (subtypeLower.contains('sport')) return 'sport';
    return 'unknown'; // Default case if no match is found. Firebase should never receive 'unknown' as subtype, because it's not an option in the dropdown.
  }
}
