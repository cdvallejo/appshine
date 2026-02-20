import 'package:appshine/data/database_service.dart';
import 'package:appshine/widgets_extra/delete_confirm_dialog.dart';
import 'package:appshine/widgets_extra/moment_detail_row.dart';
import 'package:appshine/widgets_extra/social_event_image_gallery.dart';
import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  
  // For editing social event images
  final GlobalKey _imageGalleryKey = GlobalKey();

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

  // Helper function to format list fields as comma-separated strings for editing
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
    List<String> finalImageNames = [];
    
    // 1. Upload new images first if any
    if (widget.momentData['type'] == 'socialEvent') {
      final galleryState = _imageGalleryKey.currentState;
      if (galleryState != null) {
        final newFiles = (galleryState as dynamic).getNewImageFiles() as List;
        if (newFiles.isNotEmpty) {
          try {
            finalImageNames = await (galleryState as dynamic).uploadNewImages() as List<String>;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving images: $e')),
              );
            }
            return;
          }
        } else {
          // No new images, get current ones
          finalImageNames = (galleryState as dynamic).getCurrentImageNames() as List<String>;
        }
      }
    }

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
    
    // 2. Update imageNames for social events
    if (widget.momentData['type'] == 'socialEvent' && finalImageNames.isNotEmpty) {
      updateData['imageNames'] = finalImageNames;
    }
    
    await DatabaseService().updateMoment(widget.momentId, updateData);
    
    // 3. Update local data with the same data that was saved to Firebase and exit edit mode
    setState(() {
      widget.momentData.addAll(updateData);
    });
  }

  // Build main image based on moment type
  Widget _buildMainImage() {
    if (widget.momentData['type'] == 'socialEvent') {
      final imageNames = widget.momentData['imageNames'] as List<dynamic>? ?? [];
      if (imageNames.isEmpty) {
        return Container(
          height: 300,
          width: double.infinity,
          color: Colors.cyan.withValues(alpha: 0.2),
          child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
        );
      }
      // Show first image as preview with image count badge
      return FutureBuilder<String>(
        future: _getImagePathForGallery(imageNames[0] as String),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 300,
              width: double.infinity,
              color: Colors.cyan.withValues(alpha: 0.2),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final imagePath = snapshot.data!;
          final imageFile = File(imagePath);
          
          if (!imageFile.existsSync()) {
            return Container(
              height: 300,
              width: double.infinity,
              color: Colors.cyan.withValues(alpha: 0.2),
              child: const Center(child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey)),
            );
          }
          
          return Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  image: DecorationImage(
                    image: FileImage(imageFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Image count badge
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${imageNames.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // For books, media, etc., show network image
      return Container(
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
      );
    }
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
            items: Book.subtypes
                .map((subtype) => DropdownMenuItem(
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
            items: Media.subtypes
                .map((subtype) => DropdownMenuItem(
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

  // Build social event details section
  Widget _buildSocialEventDetails() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event type dropdown
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedSubtype,
            items: SocialEvent.subtypes
                .map((subtype) => DropdownMenuItem(
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
          SocialEventImageGallery(
            key: _imageGalleryKey,
            initialImageNames: (widget.momentData['imageNames'] as List<dynamic>?)?.cast<String>() ?? [],
          ),
        ],
      );
    }

    // For social events, we currently only show the subtype blue label, maybe later we can add more details.
    return const SizedBox.shrink();
  }

  // Build type-specific details
  Widget _buildTypeSpecificDetails() {
    // Blue Uppercase label + details below (with edit mode support)
    if (widget.momentData['type'] == 'media') {
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
    } else if (widget.momentData['type'] == 'socialEvent') {
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
          _buildSocialEventDetails(),
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

  // MAIN build method with Scaffold, AppBar, and body containing image and details sections
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
                // For social events, show local images; for others, show network image
                if (widget.momentData['type'] == 'socialEvent') {
                  final imageNames = widget.momentData['imageNames'] as List<dynamic>? ?? [];
                  if (imageNames.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _ImageGalleryScreen(
                          imagePathsOrUrls: imageNames.cast<String>(),
                          initialIndex: 0,
                          localImageFileNames: imageNames.cast<String>(),
                        ),
                      ),
                    );
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _ImageGalleryScreen(
                        imagePathsOrUrls: [widget.momentData['imageUrl'] ?? ''],
                        initialIndex: 0,
                        localImageFileNames: null,
                      ),
                    ),
                  );
                }
              },
              child: _buildMainImage(),
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

/* Image gallery screen (full-screen image viewer). Before was a showDialog, 
now a full screen push for better UX and pinch-to-zoom support. */
class _ImageGalleryScreen extends StatefulWidget { // StatefulWidget to manage page controller for carousel
  final List<String> imagePathsOrUrls;
  final int initialIndex;
  final List<String>? localImageFileNames;

  const _ImageGalleryScreen({
    required this.imagePathsOrUrls,
    required this.initialIndex,
    this.localImageFileNames,
  });

  @override
  State<_ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<_ImageGalleryScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<String> _getImagePath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/social_events/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image carousel with pinch-to-zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePathsOrUrls.length,
            itemBuilder: (context, index) {
              final pathOrUrl = widget.imagePathsOrUrls[index];
              final isUrl = pathOrUrl.startsWith('http');

              if (isUrl) {
                // Network image
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(pathOrUrl, fit: BoxFit.contain),
                );
              } else if (widget.localImageFileNames != null && index < widget.localImageFileNames!.length) {
                // Local file image (social events)
                return FutureBuilder<String>(
                  future: _getImagePath(widget.localImageFileNames![index]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final imagePath = snapshot.data!;
                    final imageFile = File(imagePath);

                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: imageFile.existsSync()
                          ? Image.file(imageFile, fit: BoxFit.contain)
                          : const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.white),
                            ),
                    );
                  },
                );
              } else {
                // Fallback: try as local file directly
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(File(pathOrUrl), fit: BoxFit.contain),
                );
              }
            },
          ),

          // Close button at the top
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper method to get image path for gallery (accessible from global function)
Future<String> _getImagePathForGallery(String fileName) async {
  final appDir = await getApplicationDocumentsDirectory();
  return '${appDir.path}/social_events/$fileName';
}
