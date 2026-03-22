import 'package:appshine/data/database_service.dart';
import 'package:appshine/repositories/book_repository.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import '../models/book_model.dart';

/// Screen for adding a new reading moment associated with a book.
///
/// Allows the user to record a book read.
/// The user can edit book details, select the date, location, add personal notes,
/// and choose the book subtype (Novel, comic...).
/// Data is saved to the database via Firebase [DatabaseService].
class AddMomentScreenBook extends StatefulWidget {
  /// The book for which the reading moment will be recorded.
  final Book book;

  /// Creates a new instance of [AddMomentScreenBook].
  ///
  /// Parameters:
  /// * [book]: The book data for this reading moment.
  const AddMomentScreenBook({super.key, required this.book});

  @override
  State<AddMomentScreenBook> createState() => _AddMomentScreenBookState();
}

/// State for [AddMomentScreenBook].
///
/// Manages editable book fields, reading moment date, location, and personal notes.
/// Coordinates validation and data persistence via [DatabaseService].
class _AddMomentScreenBookState extends State<AddMomentScreenBook> {
  /// Controller for personal notes about the reading moment.
  final _notesController = TextEditingController();

  /// Controller for the location where the book was read.
  final _locationController = TextEditingController();

  /// Controller for the editable book title.
  final _titleController = TextEditingController();

  /// Controller for the publication year.
  final _yearController = TextEditingController();

  /// Controller for the publisher.
  final _publisherController = TextEditingController();

  /// Controller for authors
  final _authorsController = TextEditingController();

  /// Controller for the number of pages.
  final _pagesController = TextEditingController();

  /// Controller for the ISBN (read-only).
  final _isbnController = TextEditingController();

  /// The selected date for the reading moment. Defaults to today.
  DateTime _selectedDate = DateTime.now();

  /// Repository for fetching additional book details from the API.
  final BookRepository _bookRepository = BookRepository();

  /// The complete book instance with details fetched from the API.
  late Book _bookWithDetails;

  /// The selected book subtype (Novel, Comic...).
  /// Required before saving the moment.
  String? _selectedSubtype;

  /// Indicates if a save operation is in progress.
  bool _isSaving = false;

  /// Builds the UI for adding a reading moment.
  ///
  /// Returns a [Scaffold] containing:
  /// * Book cover image at the top.
  /// * Editable book details (title, authors, year, publisher, pages).
  /// * Book subtype dropdown selector.
  /// * Date picker with calendar.
  /// * Location field.
  /// * Multi-line notes area.
  ///
  /// Validates that a subtype has been selected before allowing save.
  /// Saves to database via [DatabaseService] and handles errors.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('addBookMoment')),
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
            onPressed: _isSaving ? null : () async {
              // 1. Validate that a subtype has been selected
              if (_selectedSubtype == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('pleaseSelectSubtype'))),
                );
                return;
              }

              setState(() => _isSaving = true);

              // 2. Async function to save the moment
              try {
                // 3. Update the book with edited values and save
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
                  final String message = error.toString().contains('timed out')
                      ? loc.translate('saveLocally')
                      : '${loc.translate('savingError')}$error';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
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
            // Upper section: Book cover image
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
                  // Book details section: Editable fields
                  FutureBuilder(
                    future: _bookRepository.getBookDetails(widget.book),
                    builder: (context, snapshot) {
                      // 1. If the request is still in progress
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // 2. If the request has returned with additional details
                      final book = snapshot.data ?? widget.book;
                      // Save the updated book for later use
                      _bookWithDetails = book;
                      // Initialize controllers with API data (only once)
                      if (_titleController.text.isEmpty) {
                        _titleController.text = book.title;
                        _yearController.text = book.releaseYear;
                        _publisherController.text = (book.publisher != null && book.publisher!.trim().isNotEmpty)
                            ? book.publisher!
                            : loc.translate('unknown');
                        _authorsController.text = book.authors.isEmpty ? loc.translate('unknown') : book.authors.join(', ');
                        _pagesController.text = book.formattedPageCount;
                      }
                      // Always update ISBN (in case it arrives from API)
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

                          // Book subtype dropdown selector
                          DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(loc.translate('selectBookType')),
                            value: _selectedSubtype,
                            items: Book.subtypes
                                .map((subtype) => DropdownMenuItem(
                                      value: subtype,
                                      child: Text(loc.translate(AppLocalizations.getBookSubtypeKey(subtype))),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubtype = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),

                          // Authors field (editable, comma-separated)
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

                          // Year and publisher fields (editable)
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
                          // Pages and ISBN fields
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
