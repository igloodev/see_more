import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

Widget _host({
  String? text,
  InlineSpan? span,
  TrimMode trimMode = TrimMode.character,
  int maxCharacters = 200,
  int maxLines = 3,
  int maxWords = 50,
  bool initiallyExpanded = false,
  bool linkify = true,
  TextStyle? linkStyle,
  RegExp? urlPattern,
  void Function(String url)? onLinkTap,
}) {
  final child = span != null
      ? SeeMoreWidget.rich(
          span,
          trimMode: trimMode,
          maxCharacters: maxCharacters,
          maxLines: maxLines,
          maxWords: maxWords,
          initiallyExpanded: initiallyExpanded,
          linkify: linkify,
          linkStyle: linkStyle,
          urlPattern: urlPattern,
          onLinkTap: onLinkTap,
        )
      : SeeMoreWidget(
          text!,
          trimMode: trimMode,
          maxCharacters: maxCharacters,
          maxLines: maxLines,
          maxWords: maxWords,
          initiallyExpanded: initiallyExpanded,
          linkify: linkify,
          linkStyle: linkStyle,
          urlPattern: urlPattern,
          onLinkTap: onLinkTap,
        );
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, child: child)),
  );
}

/// Walk every RichText on screen and find the first span whose text contains
/// [contains] and which carries a TapGestureRecognizer. Invoke its onTap.
/// Returns the URL string that was tapped.
String _tapLinkContaining(WidgetTester tester, String contains) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    String? hit;
    r.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text != null &&
          span.text!.contains(contains) &&
          span.recognizer is TapGestureRecognizer) {
        (span.recognizer as TapGestureRecognizer).onTap?.call();
        hit = span.text;
        return false;
      }
      return true;
    });
    if (hit != null) return hit!;
  }
  throw StateError('No link span containing "$contains" found');
}

/// Returns every leaf (text, style) pair under any RichText currently rendered.
List<({String text, TextStyle? style})> _allLeaves(WidgetTester tester) {
  final out = <({String text, TextStyle? style})>[];
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    r.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        out.add((text: span.text!, style: span.style));
      }
      return true;
    });
  }
  return out;
}

void main() {
  group('linkify with string constructor', () {
    testWidgets('detects URL and wraps it in tappable styled span',
        (tester) async {
      String? tapped;
      await tester.pumpWidget(_host(
        text: 'Visit https://flutter.dev for details.',
        linkify: true,
        onLinkTap: (url) => tapped = url,
      ));

      // The URL substring should appear as a styled span with the default
      // link style (blue + underline) and a tap recognizer.
      final leaves = _allLeaves(tester);
      final urlLeaf = leaves.firstWhere((l) => l.text == 'https://flutter.dev');
      expect(urlLeaf.style?.decoration, TextDecoration.underline);
      expect(urlLeaf.style?.color, const Color(0xFF1976D2));

      _tapLinkContaining(tester, 'flutter.dev');
      expect(tapped, 'https://flutter.dev');
    });

    testWidgets('passes through unchanged when content has no URL',
        (tester) async {
      await tester.pumpWidget(_host(
        text: 'Plain text, no URLs to detect.',
        linkify: true,
      ));
      // No leaf should carry the link style.
      final leaves = _allLeaves(tester);
      final styledLikeLink = leaves.where((l) =>
          l.style?.color == const Color(0xFF1976D2) &&
          l.style?.decoration == TextDecoration.underline);
      expect(styledLikeLink.isEmpty, isTrue);
    });

    testWidgets('uses custom linkStyle when provided', (tester) async {
      const custom = TextStyle(color: Color(0xFF00AA00), fontWeight: FontWeight.bold);
      await tester.pumpWidget(_host(
        text: 'Go to https://example.com now.',
        linkify: true,
        linkStyle: custom,
      ));
      final leaves = _allLeaves(tester);
      final urlLeaf = leaves.firstWhere((l) => l.text == 'https://example.com');
      expect(urlLeaf.style?.color, const Color(0xFF00AA00));
      expect(urlLeaf.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('zero-width urlPattern does not loop or explode',
        (tester) async {
      // A pathological pattern that matches every position with zero width.
      // Without the loop guard this would create one recognizer per char.
      final zeroWidth = RegExp(r'\b');
      await tester.pumpWidget(_host(
        text: 'hello world',
        linkify: true,
        urlPattern: zeroWidth,
      ));
      // Widget mounts successfully; pump completes — no infinite loop.
      // The plain text is rendered with no link styling (no real URL).
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('strips trailing sentence punctuation from detected URL',
        (tester) async {
      String? tapped;
      await tester.pumpWidget(_host(
        text: 'Visit https://flutter.dev. Or https://example.com, maybe.',
        linkify: true,
        onLinkTap: (url) => tapped = url,
      ));

      // The detected URL must not include the trailing period.
      final leaves = _allLeaves(tester);
      final firstLink = leaves.firstWhere((l) => l.text.startsWith('https://'));
      expect(firstLink.text, 'https://flutter.dev');

      // The period must remain visible as plain text immediately after.
      final periodLeaf =
          leaves.firstWhere((l) => l.text.startsWith('. Or') || l.text == '.');
      expect(periodLeaf.style?.decoration, isNot(TextDecoration.underline));

      _tapLinkContaining(tester, 'flutter.dev');
      expect(tapped, 'https://flutter.dev');
    });

    testWidgets('honors custom urlPattern', (tester) async {
      String? tapped;
      final mailPattern = RegExp(r'mailto:\S+');
      await tester.pumpWidget(_host(
        text: 'Email me at mailto:user@example.com please.',
        linkify: true,
        urlPattern: mailPattern,
        onLinkTap: (url) => tapped = url,
      ));
      _tapLinkContaining(tester, 'mailto:');
      expect(tapped, 'mailto:user@example.com');
    });
  });

  group('linkify with rich constructor', () {
    testWidgets('preserves outer styles and adds link styling for URL',
        (tester) async {
      String? tapped;
      const boldStyle = TextStyle(fontWeight: FontWeight.bold);
      const span = TextSpan(children: [
        TextSpan(text: 'Check '),
        TextSpan(text: 'this', style: boldStyle),
        TextSpan(text: ' link https://flutter.dev for info.'),
      ]);

      await tester.pumpWidget(_host(
        span: span,
        linkify: true,
        onLinkTap: (url) => tapped = url,
      ));

      final leaves = _allLeaves(tester);
      // Bold style on "this" survives.
      final thisLeaf = leaves.firstWhere((l) => l.text == 'this');
      expect(thisLeaf.style?.fontWeight, FontWeight.bold);
      // URL gets link style.
      final urlLeaf = leaves.firstWhere((l) => l.text == 'https://flutter.dev');
      expect(urlLeaf.style?.decoration, TextDecoration.underline);

      _tapLinkContaining(tester, 'flutter.dev');
      expect(tapped, 'https://flutter.dev');
    });

    testWidgets('linkify survives character trim — sliced URL stays styled',
        (tester) async {
      String? tapped;
      const fullUrl = 'https://flutter.dev/very/long/path/to/page';
      const span = TextSpan(
        text: 'A short prefix $fullUrl is here.',
      );
      // 25 chars cuts inside the URL ("A short prefix https://fl..."). The
      // URL-prefix span should still carry the link style.
      await tester.pumpWidget(_host(
        span: span,
        linkify: true,
        maxCharacters: 25,
        onLinkTap: (url) => tapped = url,
      ));

      final leaves = _allLeaves(tester);
      // A leaf starting with "https://" must still wear the link style.
      // No orElse fallback — the test fails loudly if the prefix is missing.
      final urlPrefix =
          leaves.firstWhere((l) => l.text.startsWith('https://'));
      expect(urlPrefix.style?.decoration, TextDecoration.underline);

      // Tapping the visible URL prefix invokes onLinkTap with the FULL URL
      // (the recognizer was registered with the full match before slicing).
      _tapLinkContaining(tester, 'https://');
      expect(tapped, fullUrl);
    });
  });

  group('linkify lifecycle', () {
    testWidgets('rebuilds linkified span when text changes', (tester) async {
      String? lastTapped;
      Widget build(String t) => _host(
            text: t,
            linkify: true,
            onLinkTap: (url) => lastTapped = url,
          );

      await tester.pumpWidget(build('Visit https://first.com'));
      _tapLinkContaining(tester, 'first.com');
      expect(lastTapped, 'https://first.com');

      await tester.pumpWidget(build('Now go to https://second.com here.'));
      _tapLinkContaining(tester, 'second.com');
      expect(lastTapped, 'https://second.com');
    });

    testWidgets(
        'latest onLinkTap fires even when only closure identity changes',
        (tester) async {
      String? tapped;
      // Builder takes a counter so each build provides a fresh anonymous
      // closure — simulating the common "callback created inline" pattern.
      Widget build(int n) => _host(
            text: 'visit https://example.com here',
            linkify: true,
            onLinkTap: (url) => tapped = 'build-$n:$url',
          );

      await tester.pumpWidget(build(1));
      _tapLinkContaining(tester, 'example.com');
      expect(tapped, 'build-1:https://example.com');

      // Rebuild with a NEW closure (different identity). With the old code
      // this triggered a full linkify rebuild + recognizer disposal/re-create.
      // With the fix, the same recognizer instance fires the new callback.
      await tester.pumpWidget(build(2));
      _tapLinkContaining(tester, 'example.com');
      expect(tapped, 'build-2:https://example.com');

      await tester.pumpWidget(build(3));
      _tapLinkContaining(tester, 'example.com');
      expect(tapped, 'build-3:https://example.com');
    });

    testWidgets('material change replaces recognizers; closure-only change keeps them',
        (tester) async {
      // Collect every TapGestureRecognizer attached to a link span in the
      // current frame's rendered RichTexts.
      Set<TapGestureRecognizer> linkRecognizers() {
        final out = <TapGestureRecognizer>{};
        for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
          r.text.visitChildren((s) {
            if (s is TextSpan &&
                s.recognizer is TapGestureRecognizer &&
                s.text != null &&
                s.text!.startsWith('https://')) {
              out.add(s.recognizer as TapGestureRecognizer);
            }
            return true;
          });
        }
        return out;
      }

      // Initial build with two URLs.
      await tester.pumpWidget(_host(
        text: 'one https://a.com and two https://b.com here',
        linkify: true,
      ));
      final initial = linkRecognizers();
      expect(initial.length, greaterThanOrEqualTo(2));

      // Closure-only rebuild (different onLinkTap closure, same text).
      // Recognizers must be preserved — this is the A2 regression guard.
      await tester.pumpWidget(_host(
        text: 'one https://a.com and two https://b.com here',
        linkify: true,
        onLinkTap: (_) {},
      ));
      final afterClosureChange = linkRecognizers();
      expect(afterClosureChange.intersection(initial).length, initial.length,
          reason:
              'closure-only rebuild must not churn recognizers (A2 fix)');

      // Material content change → recognizers should be replaced.
      await tester.pumpWidget(_host(
        text: 'now https://c.com is the only URL',
        linkify: true,
      ));
      final afterContentChange = linkRecognizers();
      expect(afterContentChange.intersection(initial), isEmpty,
          reason:
              'material change must replace recognizers (old set disposed)');
    });

    testWidgets('disposing widget unmounts cleanly with active recognizers',
        (tester) async {
      await tester.pumpWidget(_host(
        text: 'one https://a.com and two https://b.com here.',
        linkify: true,
      ));
      // Replace with an empty scaffold to trigger unmount.
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())));
      // Reaching this line means dispose() ran on every link recognizer
      // without throwing (TapGestureRecognizer.dispose asserts when called
      // multiple times or in invalid state).
      expect(find.byType(SeeMoreWidget), findsNothing);
    });
  });
}
