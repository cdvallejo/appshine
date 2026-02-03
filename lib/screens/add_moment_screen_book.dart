import 'package:appshine/data/database_service.dart';
import 'package:appshine/repositories/book_repository.dart';
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
  final BookRepository _bookRepository = BookRepository();

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
            // PART UPPER SECTION: COVER AND DETAILS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(widget.book.fullCoverUrl, width: 100),
                const SizedBox(width: 20),
                Expanded(
                  /* Books require additional details, so we use the repository here.
                  Lazy Loading */
                  child: FutureBuilder(
                    future: _bookRepository.getBookDetails(widget.book),
                    builder: (context, snapshot) {
                      // 1. If the request is still on the way...
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // 2. If the request has arrived (we now have extra details)...
                      final book = snapshot.data ?? widget.book;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Year with Text.rich (Grey label, black value)
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Year: ',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                TextSpan(
                                  text: book.releaseYear,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Authors
                          Text(
                            'Authors: ${book.authors?.join(', ') ?? 'Unknown'}',
                            style: const TextStyle(fontStyle: FontStyle.normal),
                          ),

                          const SizedBox(height: 4),

                          // Pages
                          Text(
                            book.formattedPageCount,
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
                    contentPadding: const EdgeInsets.only(left: 0, right: 0),
                    leading: const Icon(Icons.location_on),
                    title: const Text("Location"),
                    subtitle: TextField(
                      onChanged: (val) =>
                          setState(() => _locationController.text = val),
                      decoration: const InputDecoration(
                        hintText: 'Library, Home...',
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
