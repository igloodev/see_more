part of 'see_more_widget.dart';

/// Internal utilities for [InlineSpan] tree manipulation.
///
/// Used by [SeeMoreWidget.rich] so character / word / line trim modes can
/// operate on a span tree and preserve nested styles, recognizers, and
/// semantics when the text is truncated.
abstract class _SpanUtils {
  /// Character used by Flutter for non-text inline placeholders (WidgetSpan).
  /// Matches the layout behavior of [TextPainter] where a placeholder
  /// occupies one position in the text-position stream.
  static const String _objectReplacement = '￼';

  /// Returns the plain-text representation of [root].
  ///
  /// Concatenates every [TextSpan.text] in document order and writes one
  /// OBJECT REPLACEMENT CHARACTER for each [WidgetSpan], so the resulting
  /// string's length matches what `TextPainter.getPositionForOffset(...).offset`
  /// would return for the same tree.
  static String plainText(InlineSpan root) {
    final buf = StringBuffer();
    root.visitChildren((span) {
      if (span is TextSpan) {
        if (span.text != null) buf.write(span.text);
      } else if (span is WidgetSpan) {
        buf.write(_objectReplacement);
      }
      return true;
    });
    return buf.toString();
  }

  /// Returns the prefix of [root] containing at most [maxChars] characters.
  ///
  /// Preserves [TextSpan.style], [TextSpan.recognizer], [TextSpan.semanticsLabel],
  /// and other span properties on every enclosing span. [WidgetSpan] counts
  /// as one character (matching Flutter's text-layout convention).
  ///
  /// Returns an empty [TextSpan] when [maxChars] is `<= 0`. Returns [root]
  /// unchanged when the budget exceeds the tree's total character count
  /// (no allocation, identity-preserving).
  static InlineSpan slice(InlineSpan root, int maxChars) {
    if (maxChars <= 0) return const TextSpan(text: '');
    if (maxChars >= plainText(root).length) return root;
    final budget = _Budget(maxChars);
    return _sliceTo(root, budget) ?? const TextSpan(text: '');
  }

  static InlineSpan? _sliceTo(InlineSpan span, _Budget budget) {
    if (budget.remaining <= 0) return null;

    if (span is TextSpan) {
      String? slicedText;
      if (span.text != null && span.text!.isNotEmpty) {
        final text = span.text!;
        if (text.length <= budget.remaining) {
          slicedText = text;
          budget.remaining -= text.length;
        } else {
          slicedText = text.substring(0, budget.remaining);
          budget.remaining = 0;
        }
      }

      List<InlineSpan>? slicedChildren;
      if (span.children != null) {
        for (final child in span.children!) {
          if (budget.remaining <= 0) break;
          final sliced = _sliceTo(child, budget);
          if (sliced != null) {
            slicedChildren ??= [];
            slicedChildren.add(sliced);
          }
        }
      }

      if (slicedText == null && slicedChildren == null) return null;

      return TextSpan(
        text: slicedText,
        children: slicedChildren,
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }

    if (span is WidgetSpan) {
      if (budget.remaining < 1) return null;
      budget.remaining -= 1;
      return span;
    }

    return null;
  }

  /// Strips trailing whitespace from the right edge of [root].
  ///
  /// Walks the tree right-to-left, trims whitespace off the last text run,
  /// drops fully-empty runs, and stops once it encounters any non-whitespace
  /// content or a non-[TextSpan] placeholder (e.g. [WidgetSpan]).
  static InlineSpan trimTrailingWhitespace(InlineSpan root) {
    return _trimRightR(root).span ?? const TextSpan(text: '');
  }

  static _TrimRightResult _trimRightR(InlineSpan span) {
    if (span is! TextSpan) {
      return _TrimRightResult(span: span, stop: true);
    }

    String? newText = span.text;
    List<InlineSpan>? newChildren;
    var stop = false;

    if (span.children != null && span.children!.isNotEmpty) {
      newChildren = List<InlineSpan>.from(span.children!);
      for (var i = newChildren.length - 1; i >= 0; i--) {
        if (stop) break;
        final r = _trimRightR(newChildren[i]);
        if (r.span == null) {
          newChildren.removeAt(i);
        } else {
          newChildren[i] = r.span!;
          if (r.stop) stop = true;
        }
      }
      if (newChildren.isEmpty) newChildren = null;
    }

    if (!stop && newText != null && newText.isNotEmpty) {
      final trimmed = newText.trimRight();
      if (trimmed.isEmpty) {
        newText = null;
      } else {
        newText = trimmed;
        stop = true;
      }
    }

    if (newText == null && newChildren == null) {
      return _TrimRightResult(span: null, stop: stop);
    }

    return _TrimRightResult(
      span: TextSpan(
        text: newText,
        children: newChildren,
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      ),
      stop: stop,
    );
  }

  /// Returns the char index in [plainText] one position past the end of the
  /// Nth whitespace-separated word. Returns `plainText.length` when there
  /// are fewer than [n] words.
  static int charIndexAfterNthWord(String plainText, int n) {
    if (n <= 0) return 0;
    var wordsSeen = 0;
    var inWord = false;
    for (var i = 0; i < plainText.length; i++) {
      final isWs = _SeeMoreConstants.whitespace.hasMatch(plainText[i]);
      if (isWs) {
        if (inWord) {
          inWord = false;
          if (wordsSeen == n) return i;
        }
      } else {
        if (!inWord) {
          inWord = true;
          wordsSeen++;
        }
      }
    }
    return plainText.length;
  }

  /// Returns a new span tree where every substring matching one of
  /// [annotations] becomes its own styled, tappable [TextSpan].
  ///
  /// When several annotations match overlapping text, the match that starts
  /// earliest wins; ties are resolved by the annotation's order in the list.
  /// Every recognizer created is appended to [recognizerSink] so the caller
  /// can dispose them on unmount. Non-[TextSpan] elements (e.g. [WidgetSpan])
  /// are passed through unchanged.
  static InlineSpan annotate(
    InlineSpan root, {
    required List<_ResolvedAnnotation> annotations,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    if (annotations.isEmpty || root is! TextSpan) return root;

    // Only rewrite this span when its own text contains a match. When there's
    // no match, leave [text] inline on the span so its original style /
    // recognizer continue to apply to that exact run.
    final hasMatchInText = root.text != null &&
        root.text!.isNotEmpty &&
        annotations.any((a) => a.pattern.hasMatch(root.text!));

    String? newText = root.text;
    List<InlineSpan>? newChildren;

    if (hasMatchInText) {
      newText = null;
      newChildren = <InlineSpan>[];
      _splitTextOnAnnotations(
        root.text!,
        annotations: annotations,
        recognizerSink: recognizerSink,
        out: newChildren,
      );
    }

    if (root.children != null) {
      newChildren ??= <InlineSpan>[];
      for (final child in root.children!) {
        newChildren.add(annotate(
          child,
          annotations: annotations,
          recognizerSink: recognizerSink,
        ));
      }
    }

    return TextSpan(
      text: newText,
      children: newChildren,
      style: root.style,
      recognizer: root.recognizer,
      mouseCursor: root.mouseCursor,
      onEnter: root.onEnter,
      onExit: root.onExit,
      semanticsLabel: root.semanticsLabel,
      locale: root.locale,
      spellOut: root.spellOut,
    );
  }

  /// Trailing characters stripped from a URL match before it becomes a
  /// recognized link. Common sentence punctuation that is almost certainly
  /// NOT part of the intended URL (e.g. "visit https://example.com.").
  static final RegExp _urlTrailingTrim = RegExp(r'[.,;:!?)\]\}>]+$');

  static void _splitTextOnAnnotations(
    String text, {
    required List<_ResolvedAnnotation> annotations,
    required List<TapGestureRecognizer> recognizerSink,
    required List<InlineSpan> out,
  }) {
    if (text.isEmpty) return;

    // Collect every match across all annotations.
    final matches = <_AnnMatch>[];
    for (var ai = 0; ai < annotations.length; ai++) {
      final ann = annotations[ai];
      for (final m in ann.pattern.allMatches(text)) {
        // Skip zero-width matches (e.g. RegExp('') or `\b`) — they would
        // otherwise create one recognizer per character.
        if (m.end <= m.start) continue;
        var end = m.end;
        if (ann.trimTrailing) {
          // Strip trailing sentence punctuation the regex greedily ate
          // (e.g. "https://example.com." → "https://example.com").
          final raw = text.substring(m.start, end);
          final trailing = _urlTrailingTrim.firstMatch(raw);
          if (trailing != null && trailing.start == 0) continue; // all punct.
          if (trailing != null) end = m.start + trailing.start;
        }
        matches.add(_AnnMatch(m.start, end, ai));
      }
    }
    // Earliest start wins; ties broken by annotation order.
    matches.sort((a, b) =>
        a.start != b.start ? a.start - b.start : a.annIndex - b.annIndex);

    var cursor = 0;
    for (final m in matches) {
      if (m.start < cursor) continue; // overlaps content already emitted.
      if (m.start > cursor) {
        out.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      final ann = annotations[m.annIndex];
      final matched = text.substring(m.start, m.end);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => ann.onTap(matched);
      recognizerSink.add(recognizer);
      out.add(TextSpan(
        text: matched,
        style: ann.style,
        recognizer: recognizer,
        semanticsLabel: matched,
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      out.add(TextSpan(text: text.substring(cursor)));
    }
  }

  /// Computes the char index where to cut [plainText] for [TrimMode.character].
  ///
  /// When [trimAtWordBoundary] is true and a whitespace falls within the
  /// last [_SeeMoreConstants.wordBoundaryMinRatio] portion of [maxChars],
  /// the cut backs up to that whitespace.
  static int charBoundaryIndex(
    String plainText,
    int maxChars, {
    required bool trimAtWordBoundary,
  }) {
    if (plainText.length <= maxChars) return plainText.length;
    if (!trimAtWordBoundary) return maxChars;
    final prefix = plainText.substring(0, maxChars);
    final lastSpace = prefix.lastIndexOf(_SeeMoreConstants.whitespace);
    if (lastSpace > maxChars * _SeeMoreConstants.wordBoundaryMinRatio) {
      return lastSpace;
    }
    return maxChars;
  }
}

class _Budget {
  _Budget(this.remaining);
  int remaining;
}

class _TrimRightResult {
  _TrimRightResult({required this.span, required this.stop});
  final InlineSpan? span;
  final bool stop;
}

/// Internal, fully-resolved annotation passed to [_SpanUtils.annotate]:
/// style defaulted and [onTap] wired to a non-null forwarder.
class _ResolvedAnnotation {
  const _ResolvedAnnotation({
    required this.pattern,
    required this.style,
    required this.onTap,
    required this.trimTrailing,
  });
  final RegExp pattern;
  final TextStyle style;
  final void Function(String match) onTap;
  final bool trimTrailing;
}

class _AnnMatch {
  const _AnnMatch(this.start, this.end, this.annIndex);
  final int start;
  final int end;
  final int annIndex;
}
