import 'package:appshine/data/database_service.dart';
import 'package:appshine/widgets/delete_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MomentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> momentData;
  final String momentId;

  const MomentDetailScreen({
    super.key,
    required this.momentData,
    required this.momentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(momentData['title'] ?? 'Detalle'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DeleteConfirmDialog(
                  onConfirm: () async {
                    // 1. Delete the moment from Firestore
                    await DatabaseService().deleteMoment(momentId);

                    // 2. Close the detail screen (the dialog closes itself because of the widget POP)
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
            // 1. Cabecera con el póster
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.2),
                image: momentData['posterUrl'] != null
                    ? DecorationImage(
                        image: NetworkImage(momentData['posterUrl']),
                        fit: BoxFit.fitHeight,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Título e Info técnica
                  Text(
                    momentData['title'] ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Year: ${momentData['year'] ?? 'Desconocido'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Country: ${momentData['country'] ?? 'Desconocido'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Direction: ${momentData['director'] ?? 'Desconocido'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Actors: ${momentData['actors'] ?? 'Desconocido'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const Divider(height: 40),
                  // 3. Sección de Detalles (Ubicación y Fecha)
                  Row(
                    children: [
                      // COLUMNA IZQUIERDA: CUÁNDO
                      Expanded(
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
                                const Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${(momentData['date'] as Timestamp).toDate().day}/"
                                  "${(momentData['date'] as Timestamp).toDate().month}/"
                                  "${(momentData['date'] as Timestamp).toDate().year}",
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
                      // COLUMNA DERECHA: DÓNDE
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_pin,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  momentData['location'] ?? 'Unknown',
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
                  const SizedBox(
                    height: 30,
                  ), // Espacio extra arriba de la línea
                  // 4. Tus Notas
                  const Text(
                    'MIS NOTAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      // Comprobamos si es nulo o si la cadena no tiene caracteres
                      (momentData['notes'] == null ||
                              momentData['notes'].toString().trim().isEmpty)
                          ? 'No escribiste notas para este momento.'
                          : momentData['notes'],
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
