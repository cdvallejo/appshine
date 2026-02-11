import 'package:appshine/data/database_service.dart';
import 'package:appshine/widgets/delete_confirm_dialog.dart';
import 'package:appshine/widgets/moment_detail_row.dart';
import 'package:appshine/models/moment_model.dart';
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
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _locationController;
  late TextEditingController _authorsController;
  late TextEditingController _yearController;
  late TextEditingController _publisherController;
  late TextEditingController _isbnController;
  late TextEditingController _pageCountController;
  late TextEditingController _creatorsController;
  late TextEditingController _directionController;
  late TextEditingController _actorsController;
  late TextEditingController _countryController;
  DateTime? _selectedDate;
  late String _selectedSubtype;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _titleController = TextEditingController(text: widget.momentData['title'] ?? '');
    _notesController = TextEditingController(text: widget.momentData['notes']);
    _locationController = TextEditingController(
      text: widget.momentData['location'],
    );
    _authorsController = TextEditingController(
      text: _formatList(widget.momentData['authors']),
    );
    _yearController = TextEditingController(
      text: widget.momentData['year'] ?? widget.momentData['publishedDate'] ?? '',
    );
    _publisherController = TextEditingController(
      text: widget.momentData['publisher'] ?? '',
    );
    _isbnController = TextEditingController(
      text: widget.momentData['isbn'] ?? '',
    );
    _pageCountController = TextEditingController(
      text: widget.momentData['pageCount']?.toString() ?? widget.momentData['pages']?.toString() ?? '',
    );
    _creatorsController = TextEditingController(
      text: _formatList(widget.momentData['creators']),
    );
    _directionController = TextEditingController(
      text: _formatList(widget.momentData['director']),
    );
    _actorsController = TextEditingController(
      text: _formatList(widget.momentData['actors']),
    );
    _countryController = TextEditingController(
      text: widget.momentData['country'] ?? '',
    );
    _selectedDate = (widget.momentData['date'] as Timestamp).toDate();
    _selectedSubtype = widget.momentData['subtype'] ?? '';
  }

  String _formatList(dynamic value) {
    if (value is List) {
      return value.join(', ');
    } else if (value is String) {
      return value;
    }
    return '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _authorsController.dispose();
    _yearController.dispose();
    _publisherController.dispose();
    _isbnController.dispose();
    _pageCountController.dispose();
    _creatorsController.dispose();
    _directionController.dispose();
    _actorsController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // Function to show the calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Save changes to Firestore
  Future<void> _saveChanges() async {
    final updateData = {
      'title': _titleController.text.trim(),
      'notes': _notesController.text.trim(),
      'location': _locationController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate!),
    };
    
    if (_authorsController.text.trim().isNotEmpty) {
      updateData['authors'] = _authorsController.text.split(',').map((a) => a.trim()).toList();
    }
    if (_yearController.text.trim().isNotEmpty) {
      if (widget.momentData['type'] == 'book') {
        updateData['publishedDate'] = _yearController.text.trim();
      } else {
        updateData['year'] = _yearController.text.trim();
      }
    }
    if (_publisherController.text.trim().isNotEmpty) {
      updateData['publisher'] = _publisherController.text.trim();
    }
    if (_isbnController.text.trim().isNotEmpty) {
      updateData['isbn'] = _isbnController.text.trim();
    }
    if (_pageCountController.text.trim().isNotEmpty) {
      updateData['pageCount'] = int.tryParse(_pageCountController.text.trim()) as Object;
    }
    if (_creatorsController.text.trim().isNotEmpty) {
      updateData['creators'] = _creatorsController.text.split(',').map((a) => a.trim()).toList();
    }
    if (_directionController.text.trim().isNotEmpty) {
      updateData['director'] = _directionController.text.split(',').map((a) => a.trim()).toList();
    }
    if (_actorsController.text.trim().isNotEmpty) {
      updateData['actors'] = _actorsController.text.split(',').map((a) => a.trim()).toList();
    }
    if (_countryController.text.trim().isNotEmpty) {
      updateData['country'] = _countryController.text.trim();
    }
    
    updateData['subtype'] = _selectedSubtype;
    
    await DatabaseService().updateMoment(widget.momentId, updateData);
  }

  // Build the title section (read/edit mode)
  Widget _buildTitleSection() {
    if (isEditing) {
      return TextField(
        controller: _titleController,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );
    }
    return Text(
      _titleController.text.isEmpty ? 'Unknown' : _titleController.text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Build book details section
  Widget _buildBookDetails() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book type dropdown
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedSubtype,
            items: Moment.defaultSubtypes[MomentType.book]
                ?.map((subtype) => DropdownMenuItem(
                      value: subtype,
                      child: Text(subtype),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubtype = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              label: Text('Year'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authorsController,
            decoration: const InputDecoration(
              label: Text('Author/s'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pageCountController,
            decoration: const InputDecoration(
              label: Text('Pages'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _publisherController,
            decoration: const InputDecoration(
              label: Text('Publisher'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _isbnController,
            decoration: const InputDecoration(
              label: Text('ISBN'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDetailRow(_yearController.text.isEmpty ? null : _yearController.text, 'Year'),
        buildDetailRow(_authorsController.text.isEmpty ? null : _authorsController.text, 'Author/s'),
        buildDetailRow(_pageCountController.text.isEmpty ? null : _pageCountController.text, 'Pages'),
        buildDetailRow(_publisherController.text.isEmpty ? null : _publisherController.text, 'Publisher'),
        buildDetailRow(_isbnController.text.isEmpty ? null : _isbnController.text, 'ISBN'),
      ],
    );
  }

  // Build movie/TV details section
  Widget _buildMovieDetails() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media type dropdown
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedSubtype,
            items: Moment.defaultSubtypes[MomentType.audiovisual]
                ?.map((subtype) => DropdownMenuItem(
                      value: subtype,
                      child: Text(subtype),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubtype = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              label: Text('Year'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedSubtype.toLowerCase().contains('tv series')) ...[
            TextField(
              controller: _creatorsController,
              decoration: const InputDecoration(
                label: Text('Creator/s'),
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _directionController,
            decoration: const InputDecoration(
              label: Text('Direction'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _actorsController,
            decoration: const InputDecoration(
              label: Text('Cast'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _countryController,
            decoration: const InputDecoration(
              label: Text('Country'),
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDetailRow(_yearController.text.isEmpty ? null : _yearController.text, 'Year'),
        if (widget.momentData['subtype'] == 'TV Series') ...[
          buildDetailRow(_creatorsController.text.isEmpty ? null : _creatorsController.text, 'Creator/s'),
        ],
        buildDetailRow(_directionController.text.isEmpty ? null : _directionController.text, 'Direction'),
        buildDetailRow(_actorsController.text.isEmpty ? null : _actorsController.text, 'Cast'),
        buildDetailRow(_countryController.text.isEmpty ? null : _countryController.text, 'Country'),
      ],
    );
  }

  // Build type-specific details
  Widget _buildTypeSpecificDetails() {
    // Blue Uppercase label + details below (with edit mode support)
    if (widget.momentData['type'] == 'audiovisual') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedSubtype.toUpperCase(),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          _buildMovieDetails(),
        ],
      );
    } else if (widget.momentData['type'] == 'book') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedSubtype.toUpperCase(),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          _buildBookDetails(),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // Build date and location section
  Widget _buildDateAndLocationSection() {
    return Row(
      children: [
        // WHEN section
        Expanded(
          child: InkWell(
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
                      color: isEditing ? Colors.orange : Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isEditing ? Colors.orange : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // WHERE section
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
              if (isEditing)
                TextField(
                  controller: _locationController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.location_pin,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _locationController.text.isEmpty ? 'Unknown' : _locationController.text,
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
    );
  }

  // Build notes section
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  _notesController.text.trim().isEmpty ? 'No comments...' : _notesController.text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleController.text.isEmpty ? 'Detalle' : _titleController.text),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () async {
              if (isEditing) {
                await _saveChanges();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes saved successfully')),
                  );
                }
              }
              setState(() => isEditing = !isEditing);
            },
          ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DeleteConfirmDialog(
                    onConfirm: () async {
                      await DatabaseService().deleteMoment(widget.momentId);
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
            // Image section
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
            // Details section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 4),
                  _buildTypeSpecificDetails(),
                  const Divider(height: 40),
                  _buildDateAndLocationSection(),
                  const SizedBox(height: 30),
                  _buildNotesSection(),
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
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // 1. Carrousel of images with pinch-to-zoom
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: urls.length,
            itemBuilder: (context, index) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(urls[index], fit: BoxFit.contain),
            ),
          ),

          // 2. Close button fixed at the top (outside the PageView)
          Positioned(
            top: 10,
            right: 10,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
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
