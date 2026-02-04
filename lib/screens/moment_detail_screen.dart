import 'package:appshine/data/database_service.dart';
import 'package:appshine/widgets/delete_confirm_dialog.dart';
import 'package:appshine/widgets/moment_detail_row.dart';
import 'package:appshine/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MomentDetailScreen extends StatefulWidget {
  // StatefulWidget to manage editing state
  final Map<String, dynamic> momentData;
  final String momentId;

  const MomentDetailScreen({
    super.key,
    required this.momentData,
    required this.momentId,
  });

  @override
  State<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends State<MomentDetailScreen> {
  bool isEditing = false;
  late TextEditingController _notesController;
  late TextEditingController _locationController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _notesController = TextEditingController(text: widget.momentData['notes']);
    _locationController = TextEditingController(
      text: widget.momentData['location'],
    );
    _selectedDate = (widget.momentData['date'] as Timestamp).toDate();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Function to show the calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.momentData['title'] ?? 'Detalle'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // EDIT / SAVE BUTTON (Dynamic)
          IconButton(
            // Change icon depending on editing state
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () async {
              if (isEditing) {
                // 1. Save changes to Firestore
                await DatabaseService().updateMoment(widget.momentId, {
                  'notes': _notesController.text.trim(),
                  'location': _locationController.text.trim(),
                  'date': Timestamp.fromDate(_selectedDate!),
                });
                // Show a quick success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes saved successfully')),
                  );
                }
              }
              // 2. Change the editing mode
              setState(() => isEditing = !isEditing);
            },
          ),
          // Only show delete if not editing
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DeleteConfirmDialog(
                    onConfirm: () async {
                      // 1. Delete the moment from Firestore
                      await DatabaseService().deleteMoment(widget.momentId);

                      // 2. Close the detail screen
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Poster Section
            GestureDetector(
              onTap: () {
                showImageGallery(context, [widget.momentData['imageUrl']]);
              },
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  image: widget.momentData['imageUrl'] != null
                      ? DecorationImage(
                          image: NetworkImage(widget.momentData['imageUrl']),
                          fit: BoxFit.fitHeight,
                        )
                      : null,
                ),
              ),
            ),
            // 2. Details Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Title and Technical Details
                  Text(
                    safeStringValue(widget.momentData['title']),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.momentData['type'] == 'movie') ...[
                    buildDetailRow('Year', widget.momentData['year']),
                    buildDetailRow('Direction', widget.momentData['director']),
                    buildDetailRow('Actors', widget.momentData['actors']),
                  ] else if (widget.momentData['type'] == 'book') ...[
                    buildDetailRow('Year', widget.momentData['year']),
                    buildDetailRow('Author', widget.momentData['authors']),
                    buildDetailRow('Published', widget.momentData['publishedDate']),
                    buildDetailRow('Pages', widget.momentData['pageCount']),
                  ],

                  const Divider(height: 40),

                  // 3. Details Section (Location and Date)
                  Row(
                    children: [
                      // LEFT COLUMN: WHEN (Editable with DatePicker)
                      Expanded(
                        child: InkWell(
                          // If editing, allow date selection
                          onTap: isEditing ? () => _selectDate(context) : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WHEN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 16,
                                    color: isEditing
                                        ? Colors.orange
                                        : Colors.indigo,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isEditing
                                          ? Colors.orange
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // RIGHT COLUMN: WHERE (Editable with TextField)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WHERE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // If editing, allow location input
                            isEditing
                                ? TextField(
                                    controller: _locationController,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      const Icon(
                                        Icons.location_pin,
                                        size: 16,
                                        color: Colors.indigo,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _locationController.text.isEmpty
                                            ? 'Unknown'
                                            : _locationController.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 4. Your Notes (Editable with TextField)
                  const Text(
                    'MY NOTES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: isEditing
                        ? TextField(
                            controller: _notesController,
                            maxLines: null,
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text(
                            _notesController.text.trim().isEmpty
                                ? 'No comments...'
                                : _notesController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                  ),
                  const Divider(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Function to show a dialog image gallery
void showImageGallery(
  BuildContext context,
  List<String> urls, {
  int initialIndex = 0,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black, // Fondo negro para que resalten las fotos
      child: Stack(
        children: [
          // 1. El carrusel de imágenes
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: urls.length,
            itemBuilder: (context, index) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(urls[index], fit: BoxFit.contain),
            ),
          ),

          // 2. Botón de cerrar fijo arriba (fuera del PageView)
          Positioned(
            top: 10,
            right: 10,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54, // Fondo oscuro para el botón
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
