import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import '../models/movie_model.dart';

class AddMomentScreen extends StatefulWidget {
  final Movie movie;
  const AddMomentScreen({super.key, required this.movie});

  @override
  State<AddMomentScreen> createState() => _AddMomentScreenState();
}

class _AddMomentScreenState extends State<AddMomentScreen> {
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _location = 'Home'; // Default value

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
        title: const Text('Añadir Momento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              /* Guardar */
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
                Image.network(widget.movie.fullPosterUrl, width: 100),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Director: Christopher Nolan',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ), // Estático por ahora
                      const Text(
                        'Reparto: Leonardo DiCaprio, Cillian Murphy',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40),

            // PART MIDDLE SECTION: DATEPICKER AND LOCATION
            Row(
              children: [
                Expanded(
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
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text("Location"),
                    subtitle: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _location,
                        isExpanded: true,
                        isDense: true, // Forces compact layout with the first ListTile
                        items: <String>['Home', 'Cinema', 'Streaming', 'Other']
                            .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                        onChanged: (val) => setState(() => _location = val!),
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
