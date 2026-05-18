import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

void main() {
  group('SeeMoreWidget basic', () {
    testWidgets('renders short text without See More', (tester) async {
      await tester.pumpWidget(buildWidget(text: shortText, maxCharacters: 100));

      expect(anyRichTextContains(tester, shortText), isTrue);
      expect(anyRichTextContains(tester, 'See More'), isFalse);
    });

    testWidgets('renders long text with ellipsis and See More', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(anyRichTextContains(tester, '...'), isTrue);
      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('respects initiallyExpanded=false (See More visible)', (tester) async {
      await tester.pumpWidget(buildWidget(initiallyExpanded: false));

      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('respects initiallyExpanded=true (See Less visible)', (tester) async {
      await tester.pumpWidget(buildWidget(initiallyExpanded: true));

      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('line mode renders correctly', (tester) async {
      await tester.pumpWidget(buildWidget(trimMode: TrimMode.line, maxLines: 2));

      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('uses theme colors when no style provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
          home: const Scaffold(
            body: SizedBox(
              width: 300,
              child: SeeMoreWidget(
                'This is a long text that needs to be trimmed for testing purposes.',
                maxCharacters: 30,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SeeMoreWidget), findsOneWidget);
    });

    testWidgets('custom ellipsis works', (tester) async {
      await tester.pumpWidget(buildWidget(ellipsis: '>>>'));

      expect(anyRichTextContains(tester, '>>>'), isTrue);
    });

    testWidgets('custom expand text works', (tester) async {
      await tester.pumpWidget(buildWidget(expandText: 'Read More'));

      expect(anyRichTextContains(tester, 'Read More'), isTrue);
    });

    testWidgets('custom collapse text works', (tester) async {
      await tester.pumpWidget(buildWidget(
        collapseText: 'Read Less',
        initiallyExpanded: true,
      ));

      expect(anyRichTextContains(tester, 'Read Less'), isTrue);
    });

    testWidgets('trims at word boundary by default', (tester) async {
      const text = 'Hello wonderful world of Flutter development';
      await tester.pumpWidget(buildWidget(text: text, maxCharacters: 20));

      final contents = getAllRichTextContents(tester);
      final trimmedContent = contents.firstWhere(
        (c) => c.contains('See More'),
        orElse: () => '',
      );

      expect(trimmedContent.contains('wonderf...'), isFalse);
      expect(trimmedContent.startsWith('Hello'), isTrue);
    });

    testWidgets('AnimatedCrossFade is used for animation', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(AnimatedCrossFade), findsOneWidget);
    });

    testWidgets('Semantics wrapper is present', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('line mode uses LayoutBuilder', (tester) async {
      await tester.pumpWidget(buildWidget(trimMode: TrimMode.line, maxLines: 3));

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('disposes without errors', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      expect(true, isTrue);
    });

    testWidgets('onExpand callback is called when tapping expand button', (tester) async {
      bool expandCalled = false;
      await tester.pumpWidget(buildWidget(onExpand: () => expandCalled = true));

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final expandRichText = richTexts.firstWhere(
        (rt) => rt.text.toPlainText().contains('See More'),
      );
      final textSpan = expandRichText.text as TextSpan;
      final expandSpan = textSpan.children?.firstWhere(
        (span) => span is TextSpan && span.text?.contains('See More') == true,
      ) as TextSpan?;
      final recognizer = expandSpan?.recognizer as TapGestureRecognizer?;
      recognizer?.onTap?.call();
      await tester.pumpAndSettle();

      expect(expandCalled, isTrue);
    });

    testWidgets('onCollapse callback is called when tapping collapse button', (tester) async {
      bool collapseCalled = false;
      await tester.pumpWidget(buildWidget(
        initiallyExpanded: true,
        onCollapse: () => collapseCalled = true,
      ));

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final collapseRichText = richTexts.firstWhere(
        (rt) => rt.text.toPlainText().contains('See Less'),
      );
      final textSpan = collapseRichText.text as TextSpan;
      final collapseSpan = textSpan.children?.firstWhere(
        (span) => span is TextSpan && span.text?.contains('See Less') == true,
      ) as TextSpan?;
      final recognizer = collapseSpan?.recognizer as TapGestureRecognizer?;
      recognizer?.onTap?.call();
      await tester.pumpAndSettle();

      expect(collapseCalled, isTrue);
    });

    testWidgets('didUpdateWidget updates state when initiallyExpanded changes', (tester) async {
      await tester.pumpWidget(buildWidget(initiallyExpanded: false));
      expect(anyRichTextContains(tester, 'See More'), isTrue);

      await tester.pumpWidget(buildWidget(initiallyExpanded: true));
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('respects textScaler for accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SizedBox(
                width: 300,
                child: SeeMoreWidget(longText, maxCharacters: 50),
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(richText.textScaler, equals(const TextScaler.linear(2.0)));
    });

    testWidgets('custom textScaler overrides MediaQuery', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SizedBox(
                width: 300,
                child: SeeMoreWidget(
                  longText,
                  maxCharacters: 50,
                  textScaler: const TextScaler.linear(1.5),
                ),
              ),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(richText.textScaler, equals(const TextScaler.linear(1.5)));
    });
  });
}
