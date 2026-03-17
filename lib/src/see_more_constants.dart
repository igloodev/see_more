part of 'see_more_widget.dart';

/// Constants for SeeMoreWidget
abstract class _SeeMoreConstants {
  /// Minimum ratio for word boundary trimming.
  /// If last space is before this ratio of max length, ignore word boundary.
  static const double wordBoundaryMinRatio = 0.5;

  /// Padding between text and "See More" button in line mode.
  static const double seeMorePadding = 8.0;

  /// Gradient stops for fade effect.
  static const List<double> fadeGradientStops = [0.0, 0.6, 1.0];

  /// Default spacing between text and See More button when fade is enabled.
  static const double fadeButtonSpacing = 4.0;
}
