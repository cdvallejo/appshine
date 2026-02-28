import 'package:flutter/material.dart';

/* A reusable widget to display a label and its corresponding value in a row.
Safe data rendering for lists and null values. */
Widget buildDetailRow(dynamic value, [String? label, BuildContext? context]) {
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

  final textColor = context != null 
      ? (Theme.of(context).brightness == Brightness.light
          ? Colors.grey[600]
          : Colors.grey[400])
      : Colors.grey[600];
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 1.0),
    child: label != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '$label:',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          )
        : Text(
            displayValue,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
  );
}