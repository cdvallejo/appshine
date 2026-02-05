import 'package:appshine/data/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/media_model.dart';
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
    text: 'Home',
  ); // Default value

  final MediaRepository _mediaRepository = MediaRepository();
  DateTime _selectedDate = DateTime.now();

  // Function to show the calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Movie Moment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // 1. Async function to save the moment
              try {
                // 2. Call the function with await
                await DatabaseService().addMomentMedia(
                  media: widget.media,
                  date: _selectedDate,
                  location: _locationController.text,
                  notes: _notesController.text,
                );

                // 3. If everything goes well, notify the user and close
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PART UPPER SECTION: POSTER AND DETAILS
            Row(
              children: [
                Image.network(widget.media.fullPosterUrl, width: 100),
                const SizedBox(width: 20),
                Expanded(
                  /* Movies requieres additional details (director, actors, country), so we use the repository here.
                  Lazy Loading */
                  child: FutureBuilder(
                    future: _mediaRepository.movieExtraDetails(widget.media),
                    builder: (context, snapshot) {
                      // 1. If the messenger is still on the way...
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(), // Shows the loading spinner
                        );
                      }

                      // 2. If the messenger has arrived (we now have director, actors, and country)...
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.media.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Chip(
                            label: Text(
                              widget.media.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(height: 4),
                          // Text rich for different styles in the same line: name field grey, value black
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Year: ',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                TextSpan(
                                  text: widget.media.releaseYear,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Country: ${widget.media.country}',
                            style: const TextStyle(fontStyle: FontStyle.normal),
                          ),
                          const SizedBox(height: 4),
                          if (widget.media.type == 'tv') ...[
                            Text(
                              'Created by: ${widget.media.creators?.join(', ') ?? 'Unknown'}',
                              style: const TextStyle(fontStyle: FontStyle.normal),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            'Direction: ${widget.media.directors?.join(', ') ?? 'Unknown'}',
                            style: const TextStyle(fontStyle: FontStyle.normal),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cast: ${widget.media.actors?.join(', ') ?? 'Unknown'}',
                            style: const TextStyle(fontStyle: FontStyle.normal),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 40),

            // PART MIDDLE SECTION: DATEPICKER AND LOCATION
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicWidth(
                  // To make the ListTile take only the space it needs
                  child: ListTile(
                    title: const Text("Date"),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                ),
                Expanded(
                  // Not IntrinsicWidth to take the rest of the space because TextField needs defined width
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 0, right: 0),
                    leading: const Icon(Icons.location_on),
                    title: const Text("Location"),
                    subtitle: TextField(
                      onChanged: (val) =>
                          setState(() => _locationController.text = val),
                      decoration: const InputDecoration(
                        hintText: 'Cinema, Home...',
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
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
    );
  }
}
