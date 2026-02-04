// Helper method to safely convert values to string
String safeStringValue(dynamic value) {
  try {
    if (value == null) return 'Unknown';
    if (value is List) {
      if (value.isEmpty) return 'Unknown';
      final filtered = value.whereType<String>().toList();
      return filtered.isEmpty ? 'Unknown' : filtered.join(', ');
    }
    if (value is String && value.isNotEmpty) return value;
    return 'Unknown';
  } catch (e) {
    return 'Unknown';
  }
}
