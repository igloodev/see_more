import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

void main() {
  group('SeeMoreWidget', () {
    const longText =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
        'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, '
        'quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.';

    const shortText = 'Short text';

    /// Helper to check if any RichText contains specific text
    bool anyRichTextContains(WidgetTester tester, String text) {
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      for (final richText in richTexts) {
        if (richText.text.toPlainText().contains(text)) {
          return true;
        }
      }
      return false;
    }

    /// Get all text content from all RichText widgets
    List<String> getAllRichTextContents(WidgetTester tester) {
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      return richTexts.map((r) => r.text.toPlainText()).toList();
    }

    Widget buildWidget({
      String text = longText,
      TrimMode trimMode = TrimMode.character,
      int maxCharacters = 50,
      int maxLines = 2,
      bool initiallyExpanded = false,
      VoidCallback? onExpand,
      VoidCallback? onCollapse,
      String ellipsis = '...',
      String expandText = 'See More',
      String collapseText = 'See Less',
      bool showFadeEffect = false,
      double fadeHeight = 60.0,
      Color? fadeColor,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              text,
              trimMode: trimMode,
              maxCharacters: maxCharacters,
              maxLines: maxLines,
              initiallyExpanded: initiallyExpanded,
              onExpand: onExpand,
              onCollapse: onCollapse,
              ellipsis: ellipsis,
              expandText: expandText,
              collapseText: collapseText,
              showFadeEffect: showFadeEffect,
              fadeHeight: fadeHeight,
              fadeColor: fadeColor,
            ),
          ),
        ),
      );
    }

    testWidgets('renders short text without See More', (tester) async {
      await tester.pumpWidget(buildWidget(text: shortText, maxCharacters: 100));

      expect(anyRichTextContains(tester, shortText), isTrue);
      expect(anyRichTextContains(tester, 'See More'), isFalse);
    });

    testWidgets('renders long text with ellipsis and See More', (tester) async {
      await tester.pumpWidget(buildWidget());

      // AnimatedCrossFade has both children, we should find both "See More" and "See Less"
      expect(anyRichTextContains(tester, '...'), isTrue);
      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('respects initiallyExpanded=false (See More visible)', (tester) async {
      await tester.pumpWidget(buildWidget(initiallyExpanded: false));

      // Both are rendered but crossfade shows first child
      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('respects initiallyExpanded=true (See Less visible)', (tester) async {
      await tester.pumpWidget(buildWidget(initiallyExpanded: true));

      // Both are rendered but crossfade shows second child
      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('line mode renders correctly', (tester) async {
      await tester.pumpWidget(buildWidget(
        trimMode: TrimMode.line,
        maxLines: 2,
      ));

      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('uses theme colors when no style provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
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

      // Widget should render without errors
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
      // Text that would be cut mid-word at exactly 20 chars: "Hello wonderful worl"
      const text = 'Hello wonderful world of Flutter development';
      await tester.pumpWidget(buildWidget(
        text: text,
        maxCharacters: 20,
      ));

      final contents = getAllRichTextContents(tester);
      final trimmedContent = contents.firstWhere(
        (c) => c.contains('See More'),
        orElse: () => '',
      );

      // Should not cut in the middle of "wonderful" to "wonderf"
      expect(trimmedContent.contains('wonderf...'), isFalse);
      // Should start with Hello
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
      await tester.pumpWidget(buildWidget(
        trimMode: TrimMode.line,
        maxLines: 3,
      ));

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('disposes without errors', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Remove widget - should not throw errors
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      // If we get here without errors, dispose worked properly
      expect(true, isTrue);
    });

    testWidgets('onExpand callback is called when tapping expand button', (tester) async {
      bool expandCalled = false;
      await tester.pumpWidget(buildWidget(
        onExpand: () => expandCalled = true,
      ));

      // Find the expand text in the RichText
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final expandRichText = richTexts.firstWhere(
        (rt) => rt.text.toPlainText().contains('See More'),
      );

      // Get the TextSpan and simulate tap
      final textSpan = expandRichText.text as TextSpan;
      final expandSpan = textSpan.children?.firstWhere(
        (span) => span is TextSpan && span.text?.contains('See More') == true,
      ) as TextSpan?;

      // Cast to TapGestureRecognizer to access onTap
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

      // Find and tap the collapse text in the RichText
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final collapseRichText = richTexts.firstWhere(
        (rt) => rt.text.toPlainText().contains('See Less'),
      );

      // Get the TextSpan and simulate tap
      final textSpan = collapseRichText.text as TextSpan;
      final collapseSpan = textSpan.children?.firstWhere(
        (span) => span is TextSpan && span.text?.contains('See Less') == true,
      ) as TextSpan?;

      // Cast to TapGestureRecognizer to access onTap
      final recognizer = collapseSpan?.recognizer as TapGestureRecognizer?;
      recognizer?.onTap?.call();
      await tester.pumpAndSettle();

      expect(collapseCalled, isTrue);
    });

    testWidgets('didUpdateWidget updates state when initiallyExpanded changes', (tester) async {
      // Start collapsed
      await tester.pumpWidget(buildWidget(initiallyExpanded: false));
      expect(anyRichTextContains(tester, 'See More'), isTrue);

      // Update to expanded
      await tester.pumpWidget(buildWidget(initiallyExpanded: true));
      await tester.pumpAndSettle();

      // Should now show See Less (both are rendered due to AnimatedCrossFade)
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
                child: SeeMoreWidget(
                  longText,
                  maxCharacters: 50,
                ),
              ),
            ),
          ),
        ),
      );

      // Find RichText and verify it has the textScaler applied
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

      // Find RichText and verify it has the custom textScaler
      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(richText.textScaler, equals(const TextScaler.linear(1.5)));
    });

    // Fade effect tests
    group('Fade Effect', () {
      testWidgets('fade effect renders gradient container when enabled',
          (tester) async {
        await tester.pumpWidget(buildWidget(showFadeEffect: true));

        // Should have a Container with gradient decoration
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasGradient = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.gradient != null;
          }
          return false;
        });

        expect(hasGradient, isTrue);
      });

      testWidgets('fade effect not present when disabled', (tester) async {
        await tester.pumpWidget(buildWidget(showFadeEffect: false));

        // Should not have gradient decoration for fade
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasGradient = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.gradient is LinearGradient;
          }
          return false;
        });

        expect(hasGradient, isFalse);
      });

      testWidgets('fade effect shows expand text as separate text', (tester) async {
        await tester.pumpWidget(buildWidget(showFadeEffect: true));

        // Should find a Text widget with "See More" (not in RichText)
        expect(find.text('See More'), findsWidgets);
      });

      testWidgets('fade effect works with line mode', (tester) async {
        await tester.pumpWidget(buildWidget(
          showFadeEffect: true,
          trimMode: TrimMode.line,
          maxLines: 2,
        ));

        // Should have gradient
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasGradient = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.gradient != null;
          }
          return false;
        });

        expect(hasGradient, isTrue);
      });

      testWidgets('custom fade color is applied', (tester) async {
        await tester.pumpWidget(buildWidget(
          showFadeEffect: true,
          fadeColor: Colors.red,
        ));

        final containers = tester.widgetList<Container>(find.byType(Container));
        final gradientContainer = containers.firstWhere(
          (c) {
            final decoration = c.decoration;
            return decoration is BoxDecoration && decoration.gradient != null;
          },
          orElse: () => Container(),
        );

        final decoration = gradientContainer.decoration as BoxDecoration?;
        if (decoration?.gradient != null) {
          final gradient = decoration!.gradient as LinearGradient;
          // Check that the gradient uses red color (r component is high)
          expect(
            gradient.colors.any((c) => (c.r * 255).round() >= 244),
            isTrue,
          );
        }
      });

      testWidgets('fade not shown when text is short', (tester) async {
        await tester.pumpWidget(buildWidget(
          text: shortText,
          maxCharacters: 100,
          showFadeEffect: true,
        ));

        // Short text should not show fade gradient
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasGradient = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.gradient is LinearGradient;
          }
          return false;
        });

        expect(hasGradient, isFalse);
      });
    });
  });
}
