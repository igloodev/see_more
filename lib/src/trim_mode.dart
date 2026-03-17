/// Trim mode for text truncation
enum TrimMode {
  /// Trim by character count.
  /// Uses [SeeMoreWidget.maxCharacters] to determine truncation point.
  character,

  /// Trim by line count.
  /// Uses [SeeMoreWidget.maxLines] to determine truncation point.
  line,
}
