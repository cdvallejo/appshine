import 'package:appshine/data/database_service.dart';
import 'package:flutter/material.dart';

class UpdateMomentSheet extends StatefulWidget {
  final String momentId;
  final String initialNotes;
  final String initialLocation;

  const UpdateMomentSheet({
    super.key,
    required this.momentId,
    required this.initialNotes,
    required this.initialLocation,
  });

  @override
  State<UpdateMomentSheet> createState() => _UpdateMomentSheetState();
}

class _UpdateMomentSheetState extends State<UpdateMomentSheet> {
  late TextEditingController _notesController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
    _locationController = TextEditingController(text: widget.initialLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(
          context,
        ).viewInsets.bottom, // Adjust padding for keyboard
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'EDIT MOMENT',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            // Inside the ElevatedButton in UpdateMomentSheet
            onPressed: () async {
              // 1. Update moment in the database
              await DatabaseService().updateMoment(widget.momentId, {
                'location': _locationController.text.trim(),
                'notes': _notesController.text.trim(),
              });

              // 2. Check mounted to ensure context is valid
              // Check if the context is still mounted before popping
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
