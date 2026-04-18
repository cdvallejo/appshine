import 'package:appshine/data/database_service.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/media_model.dart';
import '../repositories/media_repository.dart';

/// Screen for adding a new viewing moment associated with media (Movie or TV series).
///
/// Allows the user to record a watched Movie or TV series.
/// The user can edit media details, select the viewing date, location and add personal notes
/// Data is saved to the database via Firebase [DatabaseService].
class AddMomentScreen extends StatefulWidget {
  /// The media (movie or TV series) for which the viewing moment will be recorded.
  final Media media;

  /// Creates a new instance of [AddMomentScreen].
  ///
  /// Parameters:
  /// * [media]: The media data for this viewing moment.
  const AddMomentScreen({super.key, required this.media});

  @override
  State<AddMomentScreen> createState() => _AddMomentScreenState();
}

/// State for [AddMomentScreen].
///
/// Manages editable media fields, viewing moment date, location, and personal notes.
/// Coordinates validation and data persistence via [DatabaseService].
/// Supports both movies and TV shows with dynamic field visibility.
class _AddMomentScreenState extends State<AddMomentScreen> {
  /// Controller for personal notes about the viewing moment.
  final _notesController = TextEditingController();

  /// Controller for the location where the media was watched.
  final _locationController = TextEditingController();

  /// Controller for the editable media title.
  final _titleController = TextEditingController();

  /// Controller for the release year.
  final _yearController = TextEditingController();

  /// Controller for the production country.
  final _countryController = TextEditingController();

  /// Controller for directors (comma-separated).
  /// Only shown for movies.
  final _directorsController = TextEditingController();

  /// Controller for creators (only shown for TV shows, is comma-separated).
  final _creatorsController = TextEditingController();

  /// Controller for screenwriters (only shown for movies, is comma-separated).
  final _screenwritersController = TextEditingController();

  /// Controller for cast members (comma-separated).
  final _castController = TextEditingController();

  /// Controller for genres (comma-separated).
  final _genresController = TextEditingController();

  /// Repository for fetching additional media details from the API.
  final MediaRepository _mediaRepository = MediaRepository();

  /// The selected date for the viewing moment. Defaults to today.
  DateTime _selectedDate = DateTime.now();

  /// The selected media subtype (Movie, TV Series).
  /// Required before saving the moment.
  String? _selectedSubtype;

  /// Indicates if a save operation is in progress.
  bool _isSaving = false;

  /// Builds the UI for adding a viewing moment.
  ///
  /// Returns a [Scaffold] containing:
  /// * Media poster image at the top.
  /// * Editable media details (title, year, country, directors/creators, screenwriters, cast, genres).
  /// * Media subtype dropdown selector.
  /// * Date picker with calendar.
  /// * Location field.
  /// * Multi-line notes area.
  ///
  /// Shows different fields based on media type (movie vs TV show).
  /// Validates that a subtype has been selected before allowing save.
  /// Saves to database via [DatabaseService] and handles errors.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final languageCode =
        '${loc.locale.languageCode}-${(loc.locale.countryCode ?? loc.locale.languageCode).toUpperCase()}';
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('addMovieMoment')),
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
            onPressed: _isSaving
                ? null
                : () async {
                    // 1. Validate that a subtype has been selected
                    if (_selectedSubtype == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translate('pleaseSelectSubtype')),
                        ),
                      );
                      return;
                    }
                    setState(() => _isSaving = true); // Show loading indicator in the save button while saving

                    // 2. Async function to save the moment
                    try {
                      // 3. Update the media with edited values and save
                      final editedMedia = widget.media.copyWith(
                        title: _titleController.text,
                        releaseDate: _yearController.text,
                        country: _countryController.text,
                        directors: _directorsController.text
                            .split(',')
                            .map((directors) => directors.trim())
                            .toList(),
                        creators: _creatorsController.text
                            .split(',')
                            .map((creator) => creator.trim())
                            .toList(),
                        screenwriters: _screenwritersController.text
                            .split(',')
                            .map((screenwriter) => screenwriter.trim())
                            .toList(),
                        cast: _castController.text
                            .split(',')
                            .map((actor) => actor.trim())
                            .toList(),
                        genres: _genresController.text
                            .split(',')
                            .map((genre) => genre.trim())
                            .toList(),
                      );
                      await DatabaseService().addMomentMedia(
                        media: editedMedia,
                        date: _selectedDate,
                        location: _locationController.text,
                        notes: _notesController.text,
                        subtype: _selectedSubtype!,
                      );

                      // 4. If successful, notify the user and close the screen
                      if (context.mounted) {
                        // Extra safety in case the user closed the screen before
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.translate('momentSaved'))),
                        );
                        Navigator.pop(context);
                      }
                    } catch (error) {
                      // 5. If an error occurs, show it to the user
                      if (context.mounted) {
                        setState(() => _isSaving = false);
                        final String message =
                            error.toString().contains('timed out')
                            ? loc.translate('saveLocally')
                            : '${loc.translate('savingError')}$error';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                        // Close screen even after error
                        Navigator.pop(context);
                      }
                    }
                  },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upper section: Media poster image
            Image.network(
              widget.media.fullPosterUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.scaleDown,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media details section: Editable fields
                  // LAZY LOAD: Extra TMDB API request to fetch additional details: country, genres, directors...
                  FutureBuilder<Media>(
                    future: _mediaRepository.getMovieDetails(
                      widget.media,
                      languageCode,
                    ),
                    builder: (context, snapshot) {
                      // 1. If the request is still in progress
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 2. If the request has returned with additional details
                      // Initialize controllers with API data (only once)
                      if (_titleController.text.isEmpty) {
                        _titleController.text = widget.media.title;
                        _yearController.text = widget.media.releaseYear;
                        _countryController.text = widget.media.country ?? '';
                        _directorsController.text =
                            widget.media.directors?.join(', ') ?? loc.translate('unknown');
                        _creatorsController.text =
                            widget.media.creators?.join(', ') ?? loc.translate('unknown');
                        _screenwritersController.text =
                            widget.media.screenwriters?.join(', ') ?? loc.translate('unknown');
                        _genresController.text =
                            widget.media.genres?.join(', ') ?? loc.translate('unknown');
                        _castController.text =
                            widget.media.cast?.join(', ') ?? loc.translate('unknown');
                        // Set subtype based on media type
                        _selectedSubtype = widget.media.subtype;
                      }
                      return Column(
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
                              label: Text(loc.translate('title')),
                              isDense: true,
                              border: UnderlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Media subtype dropdown selector
                          DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(loc.translate('selectMediaSubtype')),
                            value: _selectedSubtype,
                            items: Media.subtypes
                                .map(
                                  (subtype) => DropdownMenuItem(
                                    value: subtype,
                                    child: Text(
                                      loc.translate(
                                        AppLocalizations.getMediaSubtypeKey(
                                          subtype,
                                        ),
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

                          // Year and country fields (editable)
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _yearController,
                                  decoration: InputDecoration(
                                    label: Text(loc.translate('year')),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                    border: UnderlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                flex: 7,
                                child: TextField(
                                  controller: _countryController,
                                  decoration: InputDecoration(
                                    label: Text(loc.translate('country')),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                    border: UnderlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // TV show creators field (shown only for TV)
                          if (widget.media.type == 'tv') ...[
                            TextField(
                              controller: _creatorsController,
                              decoration: InputDecoration(
                                label: Text(loc.translate('creator')),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 8,
                                ),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          TextField(
                            controller: _directorsController,
                            decoration: InputDecoration(
                              label: Text(loc.translate('directors')),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Movie screenwriters field (shown only for movies)
                          if (widget.media.type != 'tv') ...[
                            TextField(
                              controller: _screenwritersController,
                              decoration: InputDecoration(
                                label: Text(loc.translate('screenwriters')),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 8,
                                ),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          TextField(
                            controller: _castController,
                            decoration: InputDecoration(
                              label: Text(loc.translate('cast')),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Genres field
                          TextField(
                            controller: _genresController,
                            decoration: InputDecoration(
                              label: Text(loc.translate('genres')),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 40),

                  // Middle section: Date picker and location
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Row(
                        children: [
                          // Date field with calendar picker (flex 1)
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
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: TextField(
                                          controller: _locationController,
                                          decoration: InputDecoration(
                                            hintText: loc.translate('where'),
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 0,
                                                  vertical: 0,
                                                ),
                                            border:
                                                const UnderlineInputBorder(),
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
                      );
                    },
                  ),
                  // Bottom section: Personal notes
                  const SizedBox(height: 20),
                  Text(
                    loc.translate('myNotes'),
                    style: TextStyle(fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
