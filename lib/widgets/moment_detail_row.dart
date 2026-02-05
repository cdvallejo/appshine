import 'package:flutter/material.dart';

/* A reusable widget to display a label and its corresponding value in a row.
Safe data rendering for lists and null values. */
Widget buildDetailRow(String label, dynamic value) {
  String displayValue = 'Unknown';
  
  if (value != null) {
    if (value is List) {
      if (value.isNotEmpty) {
        displayValue = (value)
            .where((item) => item != null && item.toString().isNotEmpty)
            .map((item) => item.toString())
            .join(', ');
        if (displayValue.isEmpty) {
          displayValue = 'Unknown';
        }
      }
    } else {
      displayValue = value.toString();
    }
  }
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Text(
      '$label: $displayValue',
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
    ),
  );
}