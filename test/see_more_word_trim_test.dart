import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

void main() {
  group('SeeMoreWidget TrimMode.word', () {
    const fiveWordText = 'one two three four five';
    const manyWordText =
        'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do '
        'eiusmod tempor incididunt ut labore et dolore magna aliqua ut enim '
        'ad minim veniam quis nostrud exercitation ullamco laboris';

    Widget buildWordWidget({
      String text = manyWordText,
      int maxWords = 10,
      bool initiallyExpanded = false,
      bool showFadeEffect = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              text,
              trimMode: TrimMode.word,
              maxWords: maxWords,
              initiallyExpanded: initiallyExpanded,
              showFadeEffect: showFadeEffect,
            ),
          ),
        ),
      );
    }

    testWidgets('short text (≤ maxWords) renders without button', (tester) async {
      await tester.pumpWidget(buildWordWidget(text: fiveWordText, maxWords: 10));

      expect(anyRichTextContains(tester, 'See More'), isFalse);
      expect(anyRichTextContains(tester, fiveWordText), isTrue);
    });

    testWidgets('long text renders See More button', (tester) async {
      await tester.pumpWidget(buildWordWidget());

      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('trimmed text ends at correct word boundary', (tester) async {
      await tester.pumpWidget(buildWordWidget(maxWords: 5));

      final contents = getAllRichTextContents(tester);
      final collapsed = contents.firstWhere(
        (c) => c.contains('See More'),
        orElse: () => '',
      );

      expect(collapsed.startsWith('Lorem'), isTrue);
      expect(collapsed.contains('consectetur'), isFalse);
    });

    testWidgets('expanding shows full text', (tester) async {
      await tester.pumpWidget(buildWordWidget());

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final expandRichText = richTexts.firstWhere(
        (rt) => rt.text.toPlainText().contains('See More'),
      );
      final textSpan = expandRichText.text as TextSpan;
      final expandSpan = textSpan.children?.firstWhere(
        (s) => s is TextSpan && s.text?.contains('See More') == true,
      ) as TextSpan?;
      final recognizer = expandSpan?.recognizer as TapGestureRecognizer?;
      recognizer?.onTap?.call();
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('works with fade effect', (tester) async {
      await tester.pumpWidget(buildWordWidget(showFadeEffect: true));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.gradient != null;
      });
      expect(hasGradient, isTrue);
    });

    testWidgets('works with controller', (tester) async {
      final ctrl = SeeMoreController();
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              manyWordText,
              trimMode: TrimMode.word,
              maxWords: 10,
              controller: ctrl,
            ),
          ),
        ),
      ));

      ctrl.expand();
      await tester.pumpAndSettle();
      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('exactly maxWords text renders without button', (tester) async {
      await tester.pumpWidget(buildWordWidget(text: fiveWordText, maxWords: 5));

      expect(anyRichTextContains(tester, 'See More'), isFalse);
    });
  });
}
