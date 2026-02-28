import 'package:appshine/data/database_service.dart';
import 'package:appshine/repositories/book_repository.dart';
import 'package:appshine/l10n/app_localizations.dart';
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
  final _locationController = TextEditingController();
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _publisherController = TextEditingController();
  final _authorsController = TextEditingController();
  final _pagesController = TextEditingController();
  final _isbnController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final BookRepository _bookRepository = BookRepository();
  late Book _bookWithDetails;
  String? _selectedSubtype;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('addBookMoment')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // 1. Validate subtype is selected
              if (_selectedSubtype == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('pleaseSelectSubtype'))),
                );
                return;
              }

              // 2. Async function to save the moment
              try {
                // 3. Update the book with edited values and call the function with await
                _bookWithDetails = _bookWithDetails.copyWith(
                  title: _titleController.text,
                  publishedDate: _yearController.text,
                  // Authors needs to be split back
                  authors: _authorsController.text.split(',').map((author) => author.trim()).toList(),
                  pageCount: int.tryParse(_pagesController.text),
                  publisher: _publisherController.text,
                  isbn: _isbnController.text,
                );
                await DatabaseService().addMomentBook(
                  book: _bookWithDetails,
                  date: _selectedDate,
                  location: _locationController.text,
                  notes: _notesController.text,
                  subtype: _selectedSubtype!,
                );

                // 4. If everything goes well, notify the user and close
                if (context.mounted) {
                  // Extra safety in case the user closed the screen before
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.translate('momentSaved'))),
                  );
                  Navigator.pop(context);
                }
              } catch (error) {
                // 5. If there was an error, show it
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${loc.translate('savingError')}$error')),
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
            // PART UPPER SECTION: COVER
            Image.network(
              widget.book.fullCoverUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.scaleDown,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PART BOOK DETAILS SECTION: EDITABLE
                  FutureBuilder(
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
                      // Save the updated book for later use
                      _bookWithDetails = book;
                      // Initialize controllers with API data (only once)
                      if (_titleController.text.isEmpty) {
                        _titleController.text = book.title;
                        _yearController.text = book.releaseYear;
                        _publisherController.text = '...'; // Placeholder, as Open Library doesn't provide publisher in search results
                        _authorsController.text = book.authors?.join(', ') ?? loc.translate('unknown');
                        _pagesController.text = book.formattedPageCount;
                      }
                      // Always update the ISBN (in case it arrives from API)
                      _isbnController.text = book.isbn ?? '';
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

                          // Subtype dropdown
                          DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(loc.translate('selectBookType')),
                            value: _selectedSubtype,
                            items: Book.subtypes
                                .map((subtype) => DropdownMenuItem(
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
                          const SizedBox(height: 8),

                          // Authors field (editable)
                          TextField(
                            controller: _authorsController,
                            decoration: InputDecoration(
                              label: Text(loc.translate('author')),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Year field (editable)
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
                                  controller: _publisherController,
                                  decoration: InputDecoration(
                                    label: Text(loc.translate('publisher')),
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
                          // Pages and ISBN fields (editable)
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _pagesController,
                                  decoration: InputDecoration(
                                    label: Text(loc.translate('pages')),
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
                                  controller: _isbnController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    label: Text('ISBN'),
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
                                          DateFormat('dd/MM/yyyy').format(_selectedDate),
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
                                            contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                            border: const UnderlineInputBorder(),
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
                  Text(
                    loc.translate('myNotes'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
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
