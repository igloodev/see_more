part of 'see_more_widget.dart';

/// A pattern-based annotation for [SeeMoreWidget].
///
/// Each annotation auto-detects substrings matching [pattern] in the content
/// and renders them as their own [style]d, tappable spans (calling [onTap]
/// with the matched text). Pass a list via [SeeMoreWidget.annotations] to
/// highlight hashtags, mentions, URLs, or any custom pattern — each
/// independently styled and tappable.
///
/// When several annotations (or [SeeMoreWidget.linkify]'s URL detection) match
/// overlapping text, the match that starts earliest wins; ties are resolved by
/// list order (URLs from [SeeMoreWidget.linkify] are considered first).
///
/// ```dart
/// SeeMoreWidget(
///   'Loved #flutter at the @flutterdev talk — see https://flutter.dev',
///   linkify: true, // URLs
///   annotations: [
///     SeeMoreAnnotation.hashtag(onTap: (t) => print(t)),
///     SeeMoreAnnotation.mention(onTap: (m) => print(m)),
///   ],
/// )
/// ```
class SeeMoreAnnotation {
  /// Creates an annotation that styles and links every match of [pattern].
  ///
  /// Zero-width matches are ignored. When [trimTrailingPunctuation] is true
  /// (used by [SeeMoreAnnotation.url]), trailing sentence punctuation is
  /// stripped from each match.
  const SeeMoreAnnotation({
    required this.pattern,
    this.style,
    this.onTap,
    this.trimTrailingPunctuation = false,
  });

  /// Detects URLs (`http(s)://…`), stripping trailing sentence punctuation.
  /// Defaults to a blue underlined style.
  factory SeeMoreAnnotation.url({
    RegExp? pattern,
    TextStyle? style,
    void Function(String url)? onTap,
  }) =>
      SeeMoreAnnotation(
        pattern: pattern ?? _SeeMoreConstants.defaultUrlPattern,
        style: style ?? _SeeMoreConstants.defaultLinkStyle,
        onTap: onTap,
        trimTrailingPunctuation: true,
      );

  /// Detects `#hashtags`. Defaults to a blue semibold style.
  factory SeeMoreAnnotation.hashtag({
    RegExp? pattern,
    TextStyle? style,
    void Function(String hashtag)? onTap,
  }) =>
      SeeMoreAnnotation(
        pattern: pattern ?? _SeeMoreConstants.defaultHashtagPattern,
        style: style ?? _SeeMoreConstants.defaultTagStyle,
        onTap: onTap,
      );

  /// Detects `@mentions`. Defaults to a blue semibold style.
  factory SeeMoreAnnotation.mention({
    RegExp? pattern,
    TextStyle? style,
    void Function(String mention)? onTap,
  }) =>
      SeeMoreAnnotation(
        pattern: pattern ?? _SeeMoreConstants.defaultMentionPattern,
        style: style ?? _SeeMoreConstants.defaultTagStyle,
        onTap: onTap,
      );

  /// The pattern matched against each text run.
  final RegExp pattern;

  /// Style applied to each match. When null, a blue semibold style is used.
  final TextStyle? style;

  /// Called with the matched text when the user taps a match.
  final void Function(String match)? onTap;

  /// Whether to strip trailing sentence punctuation (`. , ; : ! ? ) ] } >`)
  /// from each match. Enabled by [SeeMoreAnnotation.url].
  final bool trimTrailingPunctuation;
}
