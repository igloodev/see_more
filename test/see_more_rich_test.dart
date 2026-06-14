import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

Widget _hostRich(
  InlineSpan span, {
  TrimMode trimMode = TrimMode.character,
  int maxCharacters = 50,
  int maxLines = 2,
  int maxWords = 50,
  bool initiallyExpanded = false,
  bool trimAtWordBoundary = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 300,
        child: SeeMoreWidget.rich(
          span,
          trimMode: trimMode,
          maxCharacters: maxCharacters,
          maxLines: maxLines,
          maxWords: maxWords,
          initiallyExpanded: initiallyExpanded,
          trimAtWordBoundary: trimAtWordBoundary,
        ),
      ),
    ),
  );
}

/// The plain text of the collapsed RichText (the one containing [marker]
/// inline). Used to assert what's visible *before* the user expands —
/// AnimatedCrossFade keeps both views mounted so a blanket scan of all
/// RichTexts also picks up the hidden expanded view.
///
/// [marker] is the widget's `expandText` for that test; it's required (no
/// default) so tests that customise `expandText` cannot silently degenerate
/// to an empty-string match.
///
/// Returns an empty string when no RichText contains the marker.
String _collapsedRichTextPlain(WidgetTester tester, String marker) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    final plain = r.text.toPlainText(includeSemanticsLabels: false);
    if (plain.contains(marker)) return plain;
  }
  return '';
}

/// Finds the inline "See More" [TapGestureRecognizer] in the collapsed
/// RichText and invokes it directly. Avoids hit-testing fragility caused
/// by nested span wrappers.
void _tapExpandRecognizer(WidgetTester tester) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    TapGestureRecognizer? found;
    r.text.visitChildren((span) {
      if (span is TextSpan &&
          (span.text?.contains('See More') ?? false) &&
          span.recognizer is TapGestureRecognizer) {
        found = span.recognizer as TapGestureRecognizer;
        return false;
      }
      return true;
    });
    if (found != null) {
      found!.onTap?.call();
      return;
    }
  }
  throw StateError('No expand recognizer found in any RichText');
}

/// Like [_collapsedRichTextPlain] but returns the (text, style) leaves of
/// the collapsed RichText so callers can assert per-substring styles.
/// [marker] is the active `expandText` (required).
List<({String text, TextStyle? style})> _collapsedRichTextLeaves(
    WidgetTester tester, String marker) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    final plain = r.text.toPlainText(includeSemanticsLabels: false);
    if (!plain.contains(marker)) continue;
    final leaves = <({String text, TextStyle? style})>[];
    r.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        leaves.add((text: span.text!, style: span.style));
      }
      return true;
    });
    return leaves;
  }
  return const [];
}

void main() {
  group('SeeMoreWidget.rich basic rendering', () {
    testWidgets('renders short rich span without See More', (tester) async {
      const span = TextSpan(text: 'hi there');
      await tester.pumpWidget(_hostRich(span, maxCharacters: 100));

      expect(anyRichTextContains(tester, 'hi there'), isTrue);
      expect(anyRichTextContains(tester, 'See More'), isFalse);
    });

    testWidgets('renders long rich span with See More', (tester) async {
      final span = TextSpan(text: 'a' * 200);
      await tester.pumpWidget(_hostRich(span, maxCharacters: 20));

      expect(anyRichTextContains(tester, 'See More'), isTrue);
      expect(anyRichTextContains(tester, '...'), isTrue);
    });

    testWidgets('preserves child-span styles in collapsed view',
        (tester) async {
      // Build "Hello, world! This is a longer trailing tail." with the
      // middle word "world" in red. maxCharacters=12 cuts inside "world"
      // (after "Hello, world") so the styled run survives in the
      // collapsed view.
      const redStyle = TextStyle(color: Color(0xFFFF0000));
      const span = TextSpan(children: [
        TextSpan(text: 'Hello, '),
        TextSpan(text: 'world', style: redStyle),
        TextSpan(text: '! This is a longer trailing tail.'),
      ]);
      await tester.pumpWidget(_hostRich(span, maxCharacters: 12));

      final leaves = _collapsedRichTextLeaves(tester, 'See More');
      // Find the "world" leaf — must still carry the red style.
      final worldLeaf = leaves.firstWhere((l) => l.text.contains('world'));
      expect(worldLeaf.style?.color, const Color(0xFFFF0000));
      // The expand button text must also be present.
      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });
  });

  group('SeeMoreWidget.rich tap recognizers', () {
    testWidgets('inline recognizer in surviving prefix is still tappable',
        (tester) async {
      var taps = 0;
      final recognizer = TapGestureRecognizer()..onTap = () => taps++;
      final span = TextSpan(children: [
        TextSpan(
          text: 'tap-me',
          style: const TextStyle(color: Colors.blue),
          recognizer: recognizer,
        ),
        const TextSpan(text: ' then ignore the long rest of the content here'),
      ]);

      addTearDown(recognizer.dispose);
      await tester.pumpWidget(_hostRich(span, maxCharacters: 6));

      // Tap on the styled "tap-me" run. Use find.byType to grab the RichText
      // and dispatch a tap at its top-left where "tap-me" lives.
      final richTextFinder = find.byType(RichText).first;
      final box = tester.renderObject<RenderBox>(richTextFinder);
      final tapAt = box.localToGlobal(const Offset(8, 8));
      await tester.tapAt(tapAt);
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('SeeMoreWidget.rich character trim', () {
    testWidgets('cuts at maxCharacters when no word boundary backup',
        (tester) async {
      // 30 chars, no whitespace → wordBoundary backup can't apply.
      const span = TextSpan(text: 'abcdefghijabcdefghijabcdefghij');
      await tester.pumpWidget(
        _hostRich(span, maxCharacters: 10, trimAtWordBoundary: false),
      );

      final collapsed = _collapsedRichTextPlain(tester, 'See More');
      // Collapsed view = "abcdefghij" + "..." + " See More"
      expect(collapsed.startsWith('abcdefghij...'), isTrue,
          reason: 'collapsed view: $collapsed');
      // The 11th char ('a' from next block) must NOT appear before "...".
      expect(collapsed.contains('abcdefghija'), isFalse);
    });

    testWidgets('word boundary backs up to last space within ratio',
        (tester) async {
      const span = TextSpan(text: 'one two three four five six seven');
      await tester.pumpWidget(
        _hostRich(span, maxCharacters: 12, trimAtWordBoundary: true),
      );

      // Cut at 12 = "one two thre". lastIndexOf(' ') = 7, which is >
      // 12*0.5=6, so back up to 7. Trim trailing whitespace → "one two".
      final collapsed = _collapsedRichTextPlain(tester, 'See More');
      expect(collapsed, contains('one two'));
      // "three" must not appear in the collapsed prefix.
      expect(collapsed.contains('three'), isFalse,
          reason:
              'wordBoundary should back up before "three". got: $collapsed');
    });
  });

  group('SeeMoreWidget.rich word trim', () {
    testWidgets('cuts after Nth word, preserves styles across words',
        (tester) async {
      const redStyle = TextStyle(color: Color(0xFFFF0000));
      const span = TextSpan(children: [
        TextSpan(text: 'alpha bravo '),
        TextSpan(text: 'charlie', style: redStyle),
        TextSpan(text: ' delta echo foxtrot golf hotel'),
      ]);
      await tester.pumpWidget(
        _hostRich(span, trimMode: TrimMode.word, maxWords: 3),
      );

      final leaves = _collapsedRichTextLeaves(tester, 'See More');
      final charlieLeaf = leaves.firstWhere((l) => l.text.contains('charlie'));
      expect(charlieLeaf.style?.color, const Color(0xFFFF0000));
      // 4th word "delta" should not be in the collapsed prefix.
      final collapsed = _collapsedRichTextPlain(tester, 'See More');
      expect(collapsed.contains('delta'), isFalse,
          reason: 'collapsed: $collapsed');
    });

    testWidgets('does not render See More when words <= maxWords',
        (tester) async {
      const span = TextSpan(text: 'one two three');
      await tester.pumpWidget(
        _hostRich(span, trimMode: TrimMode.word, maxWords: 10),
      );
      expect(anyRichTextContains(tester, 'See More'), isFalse);
    });
  });

  group('SeeMoreWidget.rich line trim', () {
    testWidgets('truncates long rich content in line mode', (tester) async {
      const span = TextSpan(children: [
        TextSpan(
          text:
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
              'eiusmod tempor incididunt ut labore et dolore magna aliqua. ',
        ),
        TextSpan(
          text: 'Highlighted phrase ',
          style: TextStyle(color: Color(0xFF008000)),
        ),
        TextSpan(text: 'continues with even more trailing content here.'),
      ]);
      await tester.pumpWidget(
        _hostRich(span, trimMode: TrimMode.line, maxLines: 2),
      );
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });
  });

  group('SeeMoreWidget.rich WidgetSpan accounting', () {
    testWidgets('WidgetSpan counts as 1 character in trim — boundary include',
        (tester) async {
      // 5 + 1 (WidgetSpan) + 5 = 11 total chars. maxCharacters=6 should
      // include the WidgetSpan (5 + 1 = 6 fits exactly), then "bbbbb" is cut.
      const span = TextSpan(children: [
        TextSpan(text: 'aaaaa'),
        WidgetSpan(child: Icon(Icons.star, size: 12)),
        TextSpan(text: 'bbbbb'),
      ]);
      await tester.pumpWidget(_hostRich(
        span,
        maxCharacters: 6,
        trimAtWordBoundary: false,
      ));

      // After trim: the icon must still render in the collapsed view.
      expect(find.byIcon(Icons.star), findsWidgets);
      // The "bbbbb" run must NOT be present in the collapsed (first) RichText.
      final collapsed = _collapsedRichTextPlain(tester, 'See More');
      expect(collapsed.contains('bbbbb'), isFalse,
          reason:
              'cut at 6 chars should drop the "bbbbb" tail. got: $collapsed');
    });

    testWidgets('WidgetSpan counts as 1 character in trim — boundary exclude',
        (tester) async {
      // Same content but maxCharacters=5 — WidgetSpan should be dropped
      // (slice ran out of budget after the 5 'a' chars).
      const span = TextSpan(children: [
        TextSpan(text: 'aaaaa'),
        WidgetSpan(child: Icon(Icons.star, size: 12)),
        TextSpan(text: 'bbbbb'),
      ]);
      await tester.pumpWidget(_hostRich(
        span,
        maxCharacters: 5,
        trimAtWordBoundary: false,
      ));

      // The collapsed view should not render the star icon — it's cut.
      // (The hidden expanded view still has it, so we check the collapsed
      // RichText's span tree directly via the marker.)
      final leaves = _collapsedRichTextLeaves(tester, 'See More');
      // Sum text content from leaves up to ellipsis to count chars visible.
      final concatenated = leaves.map((l) => l.text).join();
      expect(concatenated.startsWith('aaaaa...'), isTrue,
          reason: 'first 5 chars then ellipsis. got: $concatenated');
    });

    testWidgets('span tree with only WidgetSpans counts correctly',
        (tester) async {
      const span = TextSpan(children: [
        WidgetSpan(child: Icon(Icons.star, size: 12)),
        WidgetSpan(child: Icon(Icons.favorite, size: 12)),
        WidgetSpan(child: Icon(Icons.home, size: 12)),
        WidgetSpan(child: Icon(Icons.settings, size: 12)),
      ]);
      // 4 WidgetSpans = 4 chars. maxCharacters=10 → no trim needed.
      await tester.pumpWidget(_hostRich(span, maxCharacters: 10));
      expect(anyRichTextContains(tester, 'See More'), isFalse);
    });
  });

  group('SeeMoreWidget.rich ellipsis style isolation', () {
    testWidgets('ellipsis renders in base style, not the rich root style',
        (tester) async {
      // User passes a top-level styled span (aggressive red + huge font).
      // The ellipsis after the slice should NOT inherit this style — it's
      // a sibling of the sliced content, not a child of it.
      const aggressive = TextStyle(
        color: Color(0xFFFF0000),
        fontSize: 30,
      );
      const span = TextSpan(text: 'aaaaaaaaaaaaaaaaaaaa', style: aggressive);

      await tester.pumpWidget(_hostRich(
        span,
        maxCharacters: 5,
        trimAtWordBoundary: false,
      ));

      // Find the ellipsis leaf in the collapsed view.
      final leaves = _collapsedRichTextLeaves(tester, 'See More');
      final ellipsisLeaf = leaves.firstWhere(
        (l) => l.text == '...',
        orElse: () => (text: '', style: null),
      );
      expect(ellipsisLeaf.text, '...',
          reason: 'expected an ellipsis leaf in collapsed view');
      // The ellipsis leaf must NOT carry the aggressive color or font size
      // directly. Style is null because the TextSpan was created with no
      // style — base textStyle applies via the outer wrapper.
      expect(ellipsisLeaf.style, isNull,
          reason: 'ellipsis must not inherit rich-root aggressive style');
    });
  });

  group('SeeMoreWidget.rich expand', () {
    testWidgets('tapping See More reveals full content', (tester) async {
      const span = TextSpan(children: [
        TextSpan(text: 'before '),
        TextSpan(
          text: 'styled',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text:
              ' and a long trailing remainder that should only appear after expanding',
        ),
      ]);
      await tester.pumpWidget(_hostRich(span, maxCharacters: 10));
      // Before tap: collapsed RichText must NOT include the trailing tail.
      final collapsedBefore = _collapsedRichTextPlain(tester, 'See More');
      expect(collapsedBefore.contains('trailing'), isFalse,
          reason: 'collapsed: $collapsedBefore');
      expect(anyRichTextContains(tester, 'See More'), isTrue);

      // Trigger the inline expand recognizer (works regardless of how the
      // span tree is nested under the outer base-style wrapper).
      _tapExpandRecognizer(tester);
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'trailing remainder'), isTrue);
      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });
  });
}
