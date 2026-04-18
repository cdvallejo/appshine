import 'package:flutter/material.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// About page of the app.
///
/// This screen presents:
/// 1. A branded title.
/// 2. A short project description.
/// 3. API attribution content and logos (TMDB and Open Library).
///
/// The content is wrapped in a [SingleChildScrollView] to keep it usable on small screens and avoid overflow.
class AboutScreen extends StatelessWidget {
  /// Creates the About screen.
  const AboutScreen({super.key});

  /// Builds the About UI with localized text and API attribution logos.
  ///
  /// Text styles are derived from the active theme using `copyWith` to keep
  /// visual consistency with the rest of the application.
  /// 
  /// Returns: 
  ///  A [Scaffold] containing the structured content of the About page.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontSize: 16);
    final sectionTitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
    final sectionLabelStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontSize: 14);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('about'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: titleStyle,
                children: const [
                  TextSpan(text: 'Eternal '),
                  TextSpan(
                    text: 'Appshine',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(text: ' of the Spotless Mind'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('aboutDescription'),
              style: bodyStyle,
              textAlign: TextAlign.justify,
            ),
            const Divider(height: 32),
            Text(loc.translate('aboutAPIs'), style: sectionTitleStyle),
            const SizedBox(height: 16),
            Text(loc.translate('movieOrTvs'), style: sectionLabelStyle),
            const SizedBox(height: 26),
            Center(
              child: SvgPicture.asset(
                'assets/images/tmdb_logo.svg',
                height: 100,
              ),
            ),
            const SizedBox(height: 32),
            Text(loc.translate('bookOrComics'), style: sectionLabelStyle),
            const SizedBox(height: 26),
            Center(
              child: Image.asset(
                'assets/images/open_library_logo.png',
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
