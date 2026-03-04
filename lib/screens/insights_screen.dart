import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:appshine/data/database_service.dart';
import 'package:appshine/l10n/app_localizations.dart';

/// InsightsScreen displays visual insights about the user's moments using charts and statistics.
/// It listens to real-time updates from Firestore and updates the UI accordingly.
/// 
/// **Features**
/// - Displays total count of moments and breakdown by type (media, book, social event).
/// - Shows a pie chart representing the distribution of moment types.
/// - Handles loading, error, and empty states with localized messages.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  /// Count moments by type from the snapshot
  /// 
  /// Parameters:
  ///  * [snapshot] - The QuerySnapshot containing moment documents
  /// 
  /// Returns:
  ///  A map with counts of moments by type (media, book, socialEvent)
  Map<String, int> _countMomentsByType(QuerySnapshot snapshot) {
    int mediaCount = 0;
    int bookCount = 0;
    int socialEventCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'media':
          mediaCount++;
          break;
        case 'book':
          bookCount++;
          break;
        case 'socialEvent':
          socialEventCount++;
          break;
      }
    }
    return {
      'media': mediaCount,
      'book': bookCount,
      'socialEvent': socialEventCount,
    };
  }

  /// Build pie chart data sections
  /// 
  /// Parameters:
  ///   * [counts] - A map containing the count of moments by type
  ///   * [context] - The build context
  /// 
  /// Returns:
  ///   A list of PieChartSectionData for the pie chart visualization
  List<PieChartSectionData> _buildPieChartSections(
    Map<String, int> counts,
    BuildContext context,
  ) {
    final loc = AppLocalizations.of(context);
    int total = 0;
    for (int count in counts.values) {
      total += count;
    }
    if (total == 0) return [];

    final colors = [
      const Color.fromARGB(255, 101, 121, 240), // Indigo
      const Color.fromARGB(255, 255, 152, 0), // Orange
      const Color.fromARGB(255, 76, 175, 80), // Green
    ];

    final typeLabels = {
      'media': loc.translate('movieOrTv'),
      'book': loc.translate('bookOrComic'),
      'socialEvent': loc.translate('socialEvent'),
    };

    final entries = counts.entries.toList();
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final percentage = (entry.value / total) * 100;
      final label = typeLabels[entry.key] ?? entry.key;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$label\n${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  /// Build method for InsightsScreen
  /// 
  /// Constructs a Scaffold that listens to the moments collection in Firestore and builds the UI based on the data.
  /// Handles different states (loading, error, empty) and displays insights using a pie chart and statistics cards.
  ///
  /// Parameters:
  ///   * [context] - The build context
  ///
  /// Returns:
  ///   * A Scaffold widget containing the insights screen layout within a SingleChildScrollView
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('insights'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getMomentsStream(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Text('${loc.translate('error')}: ${snapshot.error}'),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(loc.translate('noMoments')));
          }

          // Count moments by type
          final momentCounts = _countMomentsByType(snapshot.data!);
          int total = 0;
          for (int count in momentCounts.values) {
            total += count;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    loc.translate('myMoments'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${loc.translate('momentsTotal')}: $total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pie Chart
                  if (_buildPieChartSections(momentCounts, context).isNotEmpty)
                    Center(
                      child: Container(
                        height: 300,
                        padding: const EdgeInsets.all(16),
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(
                              momentCounts,
                              context,
                            ),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 40, thickness: 1.5),
                  const SizedBox(height: 16),

                  // Statistics by type
                  Text(
                    loc.translate('statisticsByType'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticCard(
                    context,
                    Icons.movie,
                    loc.translate('movieOrTv'),
                    momentCounts['media'] ?? 0,
                  ),
                  _buildStatisticCard(
                    context,
                    Icons.book,
                    loc.translate('bookOrComic'),
                    momentCounts['book'] ?? 0,
                  ),
                  _buildStatisticCard(
                    context,
                    Icons.people,
                    loc.translate('socialEvent'),
                    momentCounts['socialEvent'] ?? 0,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build individual statistic as a simple row
  /// 
  /// Parameters:
  ///  * [context] - The build context
  ///  * [icon] - The icon to display for the statistic
  ///  * [label] - The label describing the statistic
  ///  * [count] - The count value to display
  /// 
  /// Returns:
  ///   A widget representing a single statistic row with an icon, label, and count
  Widget _buildStatisticCard(
    BuildContext context,
    IconData icon,
    String label,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
