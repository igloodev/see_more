import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

const _longText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim '
    'veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex.';

Widget _host({
  String? text,
  InlineSpan? span,
  bool selectable = false,
  bool linkify = false,
  void Function(String url)? onLinkTap,
  int maxCharacters = 50,
}) {
  final child = span != null
      ? SeeMoreWidget.rich(
          span,
          maxCharacters: maxCharacters,
          selectable: selectable,
          linkify: linkify,
          onLinkTap: onLinkTap,
        )
      : SeeMoreWidget(
          text ?? _longText,
          maxCharacters: maxCharacters,
          selectable: selectable,
          linkify: linkify,
          onLinkTap: onLinkTap,
        );
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, child: child)),
  );
}

bool _anyRichTextContains(WidgetTester tester, String needle) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    if (r.text.toPlainText(includeSemanticsLabels: false).contains(needle)) {
      return true;
    }
  }
  return false;
}

/// Walk every RichText and trigger the inline "See More" recognizer.
void _tapExpandRecognizer(WidgetTester tester) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    TapGestureRecognizer? found;
    r.text.visitChildren((s) {
      if (s is TextSpan &&
          (s.text?.contains('See More') ?? false) &&
          s.recognizer is TapGestureRecognizer) {
        found = s.recognizer as TapGestureRecognizer;
        return false;
      }
      return true;
    });
    if (found != null) {
      found!.onTap?.call();
      return;
    }
  }
  throw StateError('No expand recognizer found');
}

void _tapLinkContaining(WidgetTester tester, String contains) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    var done = false;
    r.text.visitChildren((s) {
      if (done) return false;
      if (s is TextSpan &&
          s.text != null &&
          s.text!.contains(contains) &&
          s.recognizer is TapGestureRecognizer) {
        (s.recognizer as TapGestureRecognizer).onTap?.call();
        done = true;
        return false;
      }
      return true;
    });
    if (done) return;
  }
  throw StateError('No link span containing "$contains" found');
}

void main() {
  group('selectable=false (default)', () {
    testWidgets('does not wrap content in SelectionArea', (tester) async {
      await tester.pumpWidget(_host());
      expect(find.byType(SelectionArea), findsNothing);
    });
  });

  group('selectable=true', () {
    testWidgets('wraps the rendered content in a SelectionArea',
        (tester) async {
      await tester.pumpWidget(_host(selectable: true));
      expect(find.byType(SelectionArea), findsOneWidget);
      // RichText is still present underneath — selection didn't replace it.
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('inline See More recognizer still expands the text',
        (tester) async {
      await tester.pumpWidget(_host(selectable: true));
      // Before tap: "See More" is in some RichText span tree.
      expect(_anyRichTextContains(tester, 'See More'), isTrue);

      _tapExpandRecognizer(tester);
      await tester.pumpAndSettle();

      // After tap: "See Less" is the visible affordance.
      expect(_anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('link tap fires onLinkTap when both selectable and linkify on',
        (tester) async {
      String? tapped;
      await tester.pumpWidget(_host(
        text: 'Visit https://flutter.dev to learn more about Flutter.',
        selectable: true,
        linkify: true,
        onLinkTap: (url) => tapped = url,
        maxCharacters: 100,
      ));
      _tapLinkContaining(tester, 'flutter.dev');
      expect(tapped, 'https://flutter.dev');
    });

    testWidgets('inner SelectableRegion is present (selection machinery wired)',
        (tester) async {
      await tester.pumpWidget(_host(selectable: true));
      // SelectionArea wraps its child in a SelectableRegion configured with
      // platform defaults — it must exist in the tree for selection gestures
      // to be processed.
      expect(find.byType(SelectableRegion), findsOneWidget);
    });

    testWidgets('long-press on selectable content does not throw',
        (tester) async {
      await tester.pumpWidget(_host(selectable: true));
      // A real long-press exercises the selection gesture pipeline end-to-end.
      // We don't assert a specific selection range (the Selection API is
      // platform-sensitive), only that the gesture completes cleanly.
      await tester.longPress(find.byType(SelectionArea));
      await tester.pumpAndSettle();
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets(
        'custom expandButtonBuilder still receives taps inside SelectionArea',
        (tester) async {
      var tapped = 0;
      final button = TextButton(
        key: const Key('custom-expand'),
        onPressed: () => tapped++,
        child: const Text('Custom More'),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              _longText,
              maxCharacters: 50,
              selectable: true,
              expandButtonBuilder: (ctx, onTap) => GestureDetector(
                onTap: onTap,
                child: button,
              ),
            ),
          ),
        ),
      ));

      // The custom button must render below the text — SelectionArea must
      // not swallow the tap.
      expect(find.byKey(const Key('custom-expand')), findsOneWidget);

      await tester.tap(find.byKey(const Key('custom-expand')));
      await tester.pumpAndSettle();

      // The widget should now be expanded — "See Less" affordance present
      // (the default collapse button is inline, since collapseButtonBuilder
      // wasn't overridden).
      expect(_anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('works with rich constructor', (tester) async {
      const span = TextSpan(children: [
        TextSpan(text: 'before '),
        TextSpan(
          text: 'styled',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: ' rest of the long content goes here at length.'),
      ]);
      await tester.pumpWidget(_host(span: span, selectable: true));
      expect(find.byType(SelectionArea), findsOneWidget);
      // Bold style on "styled" should still be present in some leaf.
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      var foundBold = false;
      for (final r in richTexts) {
        r.text.visitChildren((s) {
          if (s is TextSpan &&
              s.text == 'styled' &&
              s.style?.fontWeight == FontWeight.bold) {
            foundBold = true;
            return false;
          }
          return true;
        });
        if (foundBold) break;
      }
      expect(foundBold, isTrue);
    });
  });
}
