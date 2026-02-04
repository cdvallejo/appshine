import 'package:flutter/material.dart';
import 'package:appshine/utils/string_utils.dart';

Widget buildDetailRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Text(
      '$label: ${safeStringValue(value)}',
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
    ),
  );
}