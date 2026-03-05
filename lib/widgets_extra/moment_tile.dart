import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/screens/moment_detail_screen.dart';

/// TODO: Refactor into separate MediaMomentTile and BookMomentTile if logic becomes too complex
/// This is transitory until we check the new data model is working well.
/// A tile widget that displays a moment with its associated media/book data.
/// Handles enrichment of moment data with media/book information from separate collections
class MomentTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Function buildMomentImage;
  final Function getMomentIcon;
  final Function capitalize;

  const MomentTile({
    super.key,
    required this.doc,
    required this.buildMomentImage,
    required this.getMomentIcon,
    required this.capitalize,
  });

  /// Enriches moment data with media or book information
  /// Returns a Future that resolves to the enriched moment data
  Future<Map<String, dynamic>> _enrichMomentData(
      Map<String, dynamic> momentData) async {
    final enrichedData = {...momentData};

    try {
      if (momentData['type'] == 'media' && momentData['mediaId'] != null) {
        final mediaDoc = await FirebaseFirestore.instance
            .collection('media')
            .doc(momentData['mediaId'].toString())
            .get();

        if (mediaDoc.exists) {
          enrichedData.addAll({
            'title': mediaDoc['title'],
            'imageUrl': mediaDoc['imageUrl'],
            'directors': mediaDoc['directors'],
            'creators': mediaDoc['creators'],
            'cast': mediaDoc['cast'],
            'country': mediaDoc['country'],
            'year': mediaDoc['releaseDate']?.toString().substring(0, 4) ?? 'N/A',
          });
        }
      } else if (momentData['type'] == 'book' && momentData['bookId'] != null) {
        final bookDoc = await FirebaseFirestore.instance
            .collection('books')
            .doc(momentData['bookId'])
            .get();

        if (bookDoc.exists) {
          enrichedData.addAll({
            'title': bookDoc['title'],
            'imageUrl': bookDoc['imageUrl'],
            'authors': bookDoc['authors'],
            'publishedDate': bookDoc['publishedDate'],
            'isbn': bookDoc['isbn'],
            'publisher': bookDoc['publisher'],
            'pageCount': bookDoc['pageCount'],
          });
        }
      }
    } catch (e) {
      // If enrichment fails, just use the basic moment data
      debugPrint('Error enriching moment data: $e');
    }

    return enrichedData;
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final loc = AppLocalizations.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _enrichMomentData(data),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: const ListTile(
              title: CircularProgressIndicator(),
            ),
          );
        }

        final enrichedData = snapshot.data ?? data;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: ListTile(
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: buildMomentImage(
              enrichedData['type'],
              enrichedData['imageNames'],
              enrichedData['imageUrl'],
              enrichedData['subtype'],
            ),
            title: Text(
              enrichedData['title'] ?? loc.translate('untitled'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 1),
                Text(
                  capitalize(enrichedData['subtype']),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
            trailing: Icon(
              getMomentIcon(enrichedData['type'], enrichedData['subtype']),
              size: 20,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MomentDetailScreen(
                    momentData: enrichedData,
                    momentId: doc.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
