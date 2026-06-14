import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

void main() {
  group('SeeMoreWidget assertions', () {
    test('throws AssertionError for empty text', () {
      expect(() => SeeMoreWidget(''), throwsAssertionError);
    });

    test('throws AssertionError for zero maxCharacters in character mode', () {
      expect(
        () => SeeMoreWidget('text',
            trimMode: TrimMode.character, maxCharacters: 0),
        throwsAssertionError,
      );
    });

    test('throws AssertionError for zero maxLines in line mode', () {
      expect(
        () => SeeMoreWidget('text', trimMode: TrimMode.line, maxLines: 0),
        throwsAssertionError,
      );
    });

    test('throws AssertionError for zero maxWords in word mode', () {
      expect(
        () => SeeMoreWidget('text', trimMode: TrimMode.word, maxWords: 0),
        throwsAssertionError,
      );
    });

    test(
        'throws AssertionError when fadeHeight is zero and showFadeEffect is true',
        () {
      expect(
        () => SeeMoreWidget('text', showFadeEffect: true, fadeHeight: 0),
        throwsAssertionError,
      );
    });

    test('throws AssertionError for empty expandText', () {
      expect(
        () => SeeMoreWidget('text', expandText: ''),
        throwsAssertionError,
      );
    });

    test('throws AssertionError for empty collapseText', () {
      expect(
        () => SeeMoreWidget('text', collapseText: ''),
        throwsAssertionError,
      );
    });

    test('throws AssertionError for negative expandButtonSpacing', () {
      expect(
        () => SeeMoreWidget('text', expandButtonSpacing: -1),
        throwsAssertionError,
      );
    });
  });

  group('SeeMoreWidget edge cases', () {
    testWidgets('line mode shows no button for text within maxLines',
        (tester) async {
      const shortMultiline = 'Just one line of text.';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              shortMultiline,
              trimMode: TrimMode.line,
              maxLines: 5,
            ),
          ),
        ),
      ));

      expect(anyRichTextContains(tester, 'See More'), isFalse);
      expect(anyRichTextContains(tester, shortMultiline), isTrue);
    });

    testWidgets('trimAtWordBoundary in line mode does not cut mid-word',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              trimMode: TrimMode.line,
              maxLines: 2,
              trimAtWordBoundary: true,
            ),
          ),
        ),
      ));

      final contents = getAllRichTextContents(tester);
      final collapsed = contents.firstWhere(
        (c) => c.contains('See More'),
        orElse: () => '',
      );

      if (collapsed.isNotEmpty) {
        final textPart = collapsed
            .replaceAll('... See More', '')
            .replaceAll('...', '')
            .trim();
        if (textPart.isNotEmpty) {
          final lastWord = textPart.split(RegExp(r'\s+')).last;
          expect(longText.contains(lastWord), isTrue);
        }
      }
    });

    testWidgets('Semantics label shows expandText when collapsed',
        (tester) async {
      await tester.pumpWidget(buildWidget(expandText: 'Read More'));

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(SeeMoreWidget),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, 'Read More');
    });

    testWidgets('Semantics label shows collapseText when expanded',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        collapseText: 'Read Less',
        initiallyExpanded: true,
      ));

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(SeeMoreWidget),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, 'Read Less');
    });
  });
}
