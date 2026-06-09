part of 'see_more_widget.dart';

/// Constants for SeeMoreWidget
abstract class _SeeMoreConstants {
  /// When [trimAtWordBoundary] is true, the trim point only backs up to the
  /// nearest space if that space falls within the last 50 % of the allowed
  /// length.  Below that threshold the cut stays at the character limit to
  /// avoid trimming too aggressively (e.g. a 5-char word near the start of a
  /// 10-char window would otherwise eat half the visible text).
  static const double wordBoundaryMinRatio = 0.5;

  /// Padding between text and "See More" button in line mode.
  static const double seeMorePadding = 8.0;

  /// Gradient stops for fade effect.
  static const List<double> fadeGradientStops = [0.0, 0.6, 1.0];

  /// Default spacing between text and See More button when fade is enabled.
  static const double fadeButtonSpacing = 4.0;

  // Compiled once and reused across all trim calls.
  static final RegExp whitespace = RegExp(r'\s');
  static final RegExp whitespaces = RegExp(r'\s+');

  /// Default URL detection pattern used when [SeeMoreWidget.linkify] is `true`
  /// and no custom [SeeMoreWidget.urlPattern] is supplied. Matches `http(s)://`
  /// followed by any non-whitespace, non-bracket character. Common sentence
  /// punctuation (`. , ; : ! ? ) ] } >`) is stripped from the end of each
  /// match *after* the regex runs, so a URL at the end of a sentence isn't
  /// swallowed by the period.
  static final RegExp defaultUrlPattern = RegExp(
    r'https?://[^\s<>"]+',
    caseSensitive: false,
  );

  /// Fallback style applied to detected links when no [SeeMoreWidget.linkStyle]
  /// is provided. Material Blue 700 + underline reads as a link without
  /// pulling in Theme.of(context) (linkification runs outside build()).
  static const TextStyle defaultLinkStyle = TextStyle(
    color: Color(0xFF1976D2),
    decoration: TextDecoration.underline,
  );
}
