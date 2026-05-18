import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

void main() {
  group('SeeMoreWidget style parameters', () {
    testWidgets('textStyle is applied to main RichText', (tester) async {
      const customColor = Color(0xFFAB1234);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              textStyle: const TextStyle(fontSize: 22, color: customColor),
            ),
          ),
        ),
      ));

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(richText.text.style?.fontSize, 22.0);
      expect(richText.text.style?.color, customColor);
    });

    testWidgets('expandTextStyle is applied to expand button span', (tester) async {
      const customColor = Color(0xFF123456);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              expandTextStyle: const TextStyle(color: customColor, fontSize: 18),
            ),
          ),
        ),
      ));

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final expandRichText = richTexts.firstWhere(
        (rt) => rt.text.toPlainText().contains('See More'),
      );
      final textSpan = expandRichText.text as TextSpan;
      final expandSpan = textSpan.children?.firstWhere(
        (s) => s is TextSpan && s.text?.contains('See More') == true,
      ) as TextSpan?;

      expect(expandSpan?.style?.color, customColor);
      expect(expandSpan?.style?.fontSize, 18.0);
    });

    testWidgets('collapseTextStyle is applied to collapse button span', (tester) async {
      const customColor = Color(0xFF654321);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              initiallyExpanded: true,
              collapseTextStyle: const TextStyle(color: customColor, fontSize: 16),
            ),
          ),
        ),
      ));

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final collapseRichText = richTexts.firstWhere(
        (rt) => rt.text.toPlainText().contains('See Less'),
      );
      final textSpan = collapseRichText.text as TextSpan;
      final collapseSpan = textSpan.children?.firstWhere(
        (s) => s is TextSpan && s.text?.contains('See Less') == true,
      ) as TextSpan?;

      expect(collapseSpan?.style?.color, customColor);
      expect(collapseSpan?.style?.fontSize, 16.0);
    });

    testWidgets('textAlign is propagated to all RichTexts', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ));

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      expect(richTexts.every((rt) => rt.textAlign == TextAlign.center), isTrue);
    });

    testWidgets('textDirection RTL is propagated to all RichTexts', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ));

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      expect(richTexts.every((rt) => rt.textDirection == TextDirection.rtl), isTrue);
    });
  });

  group('SeeMoreWidget animation parameters', () {
    testWidgets('custom animationDuration is set on AnimatedCrossFade', (tester) async {
      const customDuration = Duration(milliseconds: 800);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              animationDuration: customDuration,
            ),
          ),
        ),
      ));

      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.duration, customDuration);
    });

    testWidgets('custom animationCurve is set on AnimatedCrossFade', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              animationCurve: Curves.bounceIn,
            ),
          ),
        ),
      ));

      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.firstCurve, Curves.bounceIn);
      expect(crossFade.secondCurve, Curves.bounceIn);
    });
  });
}
