import 'package:appshine/data/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/media_model.dart';
import '../models/moment_model.dart';
import '../repositories/media_repository.dart';

class AddMomentScreen extends StatefulWidget {
  final Media media;
  const AddMomentScreen({super.key, required this.media});

  @override
  State<AddMomentScreen> createState() => _AddMomentScreenState();
}

class _AddMomentScreenState extends State<AddMomentScreen> {
  final _notesController = TextEditingController();
  final _locationController = TextEditingController(
    text: 'Cinema, Home...',
  ); // Default value
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _countryController = TextEditingController();
  final _directorsController = TextEditingController();
  final _creatorsController = TextEditingController();
  final _actorsController = TextEditingController();

  final MediaRepository _mediaRepository = MediaRepository();
  DateTime _selectedDate = DateTime.now();
  String? _selectedSubtype;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Movie Moment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // 1. Validate subtype is selected
              if (_selectedSubtype == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a subtype')),
                );
                return;
              }

              // 2. Async function to save the moment
              try {
                // 3. Update the media with edited values and call the function with await
                final editedMedia = widget.media.copyWith(
                  title: _titleController.text,
                  releaseDate: _yearController.text,
                  country: _countryController.text,
                  directors: _directorsController.text
                      .split(',')
                      .map((director) => director.trim())
                      .toList(),
                  creators: _creatorsController.text
                      .split(',')
                      .map((creator) => creator.trim())
                      .toList(),
                  actors: _actorsController.text
                      .split(',')
                      .map((actor) => actor.trim())
                      .toList(),
                );
                await DatabaseService().addMomentMedia(
                  media: editedMedia,
                  date: _selectedDate,
                  location: _locationController.text,
                  notes: _notesController.text,
                  subtype: _selectedSubtype!,
                );

                // 4. If everything goes well, notify the user and close
                if (context.mounted) {
                  // Extra safety in case the user closed the screen before
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Moment saved!')),
                  );
                  Navigator.pop(context);
                }
              } catch (error) {
                // 4. If there was an error, show it
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving moment: $error')),
                  );
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
            // PART UPPER SECTION: POSTER
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
                  // PART MEDIA DETAILS SECTION: EDITABLE
                  FutureBuilder(
                    future: _mediaRepository.getMovieDetails(widget.media),
                    builder: (context, snapshot) {
                      // 1. If the request is still on the way...
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 2. If the request has arrived (we now have director, actors, and country)...
                      // Initialize controllers with API data (only once)
                      if (_titleController.text.isEmpty) {
                        _titleController.text = widget.media.title;
                        _yearController.text = widget.media.releaseYear;
                        _countryController.text = widget.media.country ?? '';
                        _directorsController.text =
                            widget.media.directors?.join(', ') ?? 'Unknown';
                        _creatorsController.text =
                            widget.media.creators?.join(', ') ?? 'Unknown';
                        _actorsController.text =
                            widget.media.actors?.join(', ') ?? 'Unknown';
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
                            hint: const Text('Select subtype'),
                            value: _selectedSubtype,
                            items: Moment.defaultSubtypes[MomentType.media]
                                ?.map((subtype) => DropdownMenuItem(
                                      value: subtype,
                                      child: Text(subtype),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubtype = value;
                              });
                            },
                          ),

                          const SizedBox(height: 4),

                          // Year field (editable)
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _yearController,
                                  decoration: const InputDecoration(
                                    label: Text('Year'),
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
                              ), // Un poco de espacio de separación entre ellos
                              Expanded(
                                flex: 7,
                                child: TextField(
                                  controller: _countryController,
                                  decoration: const InputDecoration(
                                    label: Text('Country'),
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
                          if (widget.media.type == 'tv') ...[
                            TextField(
                              controller: _creatorsController,
                              decoration: const InputDecoration(
                                label: Text('Creator/s'),
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
                            decoration: const InputDecoration(
                              label: Text('Directors'),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _actorsController,
                            decoration: const InputDecoration(
                              label: Text('Cast'),
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

                  // PART MIDDLE SECTION: DATEPICKER AND LOCATION
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Row(
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
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 24,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month,
                                          size: 16,
                                          color: Colors.indigo,
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
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 24,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_pin,
                                        size: 16,
                                        color: Colors.indigo,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: TextField(
                                          controller: _locationController,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
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
                      );
                    },
                  ),
                  // PART BOTTOM SECTION: NOTES
                  const SizedBox(height: 20),
                  const Text(
                    "My Notes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write here a note.',
                      border: OutlineInputBorder(),
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
