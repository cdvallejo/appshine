import 'package:flutter/material.dart';
import 'package:appshine/l10n/app_localizations.dart';

/// Builds a detail row displaying a label and its corresponding value.
///
/// Safely renders null values, lists, and single values with theme-aware colors.
/// 
/// Parameters:
/// * [value] - The data to display (can be a single value, list, or null)
/// * [label] - Optional label for the value (displayed on the left side)
/// * [context] - Optional BuildContext for localization and theme access
///
/// Returns:
/// * A [Widget] containing the formatted label-value row with proper spacing and colors
Widget buildDetailRow(dynamic value, [String? label, BuildContext? context]) {
  final loc = context != null ? AppLocalizations.of(context) : null;
  String displayValue = loc?.translate('unknown') ?? 'Unknown';
  
  if (value != null) {
    if (value is List) {
      if (value.isNotEmpty) {
        displayValue = (value)
            .where((item) => item != null && item.toString().isNotEmpty)
            .map((item) => item.toString())
            .join(', ');
        if (displayValue.isEmpty) {
          displayValue = loc?.translate('unknown') ?? 'Unknown';
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