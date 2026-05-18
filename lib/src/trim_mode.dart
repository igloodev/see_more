/// Trim mode for text truncation
enum TrimMode {
  /// Trim by character count.
  /// Uses [SeeMoreWidget.maxCharacters] to determine truncation point.
  character,

  /// Trim by line count.
  /// Uses [SeeMoreWidget.maxLines] to determine truncation point.
  line,

  /// Trim by word count.
  /// Uses [SeeMoreWidget.maxWords] to determine truncation point.
  /// Splitting is whitespace-aware, so multi-space runs count as one separator.
  word,
}
