import 'package:appshine/data/database_service.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final _locationController = TextEditingController(
    text: 'Unknown Location',
  );
  final _titleController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSubtype;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.socialEvent.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Social Event Moment'),
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
                final editedSocialEvent = widget.socialEvent.copyWith(
                  title: _titleController.text,
                );
                await DatabaseService().addMomentSocialEvent(
                  socialEvent: editedSocialEvent,
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
            widget.socialEvent.images?.isNotEmpty == true
                ? Image.network(
                    widget.socialEvent.images!.first,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 60),
                      );
                    },
                  )
                : Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 60),
                  ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NO NEED FutureBuilder here because no API call is needed! User just edits the title and subtype, and we save it directly to Firestore with the existing data from the socialEvent object (like imageUrl, etc.)
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

                  // PART MIDDLE SECTION: DATEPICKER AND LOCATION
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
