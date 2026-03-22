import 'package:appshine/data/database_service.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:appshine/widgets_extra/social_event_image_gallery.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Screen for adding a new moment associated with a social event.
///
/// Allows the user to record a specific moment at a social event, including:
/// * Event title and subtype (Culture, Meeting, Sport...).
/// * Date and location of the event.
/// * Personal notes about the moment.
/// * Multiple images captured from camera or gallery.
///
/// Images are saved locally to the device's Pictures folder, not to cloud storage.
/// Only image filenames are stored in Firestore for backup compatibility.
class AddMomentScreenSocialEvent extends StatefulWidget {
  /// The social event for which the moment will be recorded.
  final SocialEvent socialEvent;

  /// Creates a new instance of [AddMomentScreenSocialEvent].
  ///
  /// Parameters:
  /// * [socialEvent]: The social event data for this moment.
  const AddMomentScreenSocialEvent({super.key, required this.socialEvent});

  @override
  State<AddMomentScreenSocialEvent> createState() =>
      _AddMomentScreenSocialEventState();
}

/// State for [AddMomentScreenSocialEvent].
///
/// Manages event details, date, location, notes, and image uploads.
/// Coordinates image selection, local storage, and data persistence
/// via [DatabaseService].
class _AddMomentScreenSocialEventState
    extends State<AddMomentScreenSocialEvent> {
  /// Controller for personal notes about the social event moment.
  final _notesController = TextEditingController();

  /// Controller for the location where the event took place.
  final _locationController = TextEditingController();

  /// Controller for the editable event title.
  final _titleController = TextEditingController();

  /// Global key to access the image gallery widget methods
  final _imageGalleryKey = GlobalKey<SocialEventImageGalleryState>();

  /// The selected date for the social event. Defaults to today.
  DateTime _selectedDate = DateTime.now();

  /// The selected event subtype (Culture, Meeting, Sport...).
  /// Required before saving the moment.
  String? _selectedSubtype;

  /// Used to display a loading indicator in the save button.
  bool _isSaving = false;

  /// Builds the UI for adding a social event moment.
  ///
  /// Returns a [Scaffold] containing:
  /// * Editable event title and subtype dropdown.
  /// * Image picker buttons (camera and gallery).
  /// * Preview of selected images with removal option.
  /// * Date picker with calendar.
  /// * Location field.
  /// * Multi-line notes area.
  ///
  /// Validates that a subtype has been selected before allowing save.
  /// Orchestrates image upload and moment data persistence via [DatabaseService].
  /// Handles validation, error display, and screen closure.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('addEventMoment')),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : () async {
              // 1. Validate that a subtype has been selected
              if (_selectedSubtype == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('selectEventSubtype'))),
                );
                return;
              }

              setState(() => _isSaving = true);

              // 2. Upload any pending images to local cache
              List<String> uploadedImageNames = [];
              try {
                final imageNames = await _imageGalleryKey.currentState?.uploadNewImages();
                uploadedImageNames = imageNames ?? [];
              } catch (e) {
                setState(() => _isSaving = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${loc.translate('errorSavingImages')}: $e',
                      ),
                    ),
                  );
                }
                return;
              }

              // 3. Async function to save the moment
              try {
                // Create a new SocialEvent with the image names before saving
                final socialEventWithImages = SocialEvent(
                  title: _titleController.text,
                  subtype: _selectedSubtype!,
                  imageNames: uploadedImageNames.isNotEmpty
                      ? uploadedImageNames
                      : null,
                );

                await DatabaseService().addMomentSocialEvent(
                  socialEvent: socialEventWithImages,
                  date: _selectedDate,
                  location: _locationController.text,
                  notes: _notesController.text,
                  subtype: _selectedSubtype!,
                );

                // 4. If successful, notify the user and close the screen
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.translate('momentSaved'))),
                  );
                  Navigator.pop(context);
                }
              } catch (error) {
                // 5. If an error occurs, show it to the user
                if (context.mounted) {
                  setState(() => _isSaving = false);
                  final String message = error.toString().contains('timed out') 
                      ? loc.translate('saveLocally') // Save operation timed out, but data is saved offline
                      : '${loc.translate('savingError')}: $error'; // Saving error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                  // Close screen even after error
                  Navigator.pop(context);
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
                decoration: InputDecoration(
                  hintText: loc.translate('newEvent'),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),

              // Event subtype dropdown selector
              DropdownButton<String>(
                isExpanded: true,
                hint: Text(loc.translate('selectEventSubtype')),
                value: _selectedSubtype,
                items: SocialEvent.subtypes
                    .map(
                      (subtype) => DropdownMenuItem(
                        value: subtype,
                        child: Text(
                          loc.translate(
                            AppLocalizations.getSocialEventSubtypeKey(subtype),
                          ),
                        ),
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

              // Image gallery widget for selecting and managing images
              SocialEventImageGallery(
                key: _imageGalleryKey,
                onImagesChanged: () => setState(() {}),
              ),

              const SizedBox(height: 4),
              const Divider(height: 40),
              // Date and location fields
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
                  // Location field with icon (flex 2)
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
                                    contentPadding: const EdgeInsets.symmetric(
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
              // Bottom section: Personal notes
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
}
