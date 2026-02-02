import 'package:appshine/data/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import '../models/book_model.dart';

class AddMomentScreenBook extends StatefulWidget {
  final Book book;
  const AddMomentScreenBook({super.key, required this.book});

  @override
  State<AddMomentScreenBook> createState() => _AddMomentScreenBookState();
}

class _AddMomentScreenBookState extends State<AddMomentScreenBook> {
  final _notesController = TextEditingController();
  final _locationController = TextEditingController(
    text: 'Home',
  ); // Default value
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
        title: const Text('Add Book Moment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // 1. Async function to save the moment
              try {
                // 2. Call the function with await
                await DatabaseService().addMomentBook(
                  book: widget.book,
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
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Para que el texto empiece arriba
              children: [
                Image.network(widget.book.fullCoverUrl, width: 100),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Año con Text.rich (Gris la etiqueta, negro el valor)
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Year: ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextSpan(
                              text: widget.book.releaseYear,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Autores (usando join para que quede bonito: "Autor 1, Autor 2")
                      Text(
                        'Author: ${widget.book.authors?.join(', ') ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.black87),
                      ),

                      const SizedBox(height: 4),

                      // Page count
                      Text(
                        widget.book.formattedPageCount,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
