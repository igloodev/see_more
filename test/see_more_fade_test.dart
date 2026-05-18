import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

void main() {
  group('SeeMoreWidget fade effect', () {
    testWidgets('renders gradient container when enabled', (tester) async {
      await tester.pumpWidget(buildWidget(showFadeEffect: true));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.gradient != null;
      });

      expect(hasGradient, isTrue);
    });

    testWidgets('not present when disabled', (tester) async {
      await tester.pumpWidget(buildWidget(showFadeEffect: false));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.gradient is LinearGradient;
      });

      expect(hasGradient, isFalse);
    });

    testWidgets('shows expand text as separate Text widget', (tester) async {
      await tester.pumpWidget(buildWidget(showFadeEffect: true));

      expect(find.text('See More'), findsWidgets);
    });

    testWidgets('works with line mode', (tester) async {
      await tester.pumpWidget(buildWidget(
        showFadeEffect: true,
        trimMode: TrimMode.line,
        maxLines: 2,
      ));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.gradient != null;
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
        expect(gradient.colors.any((c) => (c.r * 255).round() >= 244), isTrue);
      }
    });

    testWidgets('not shown when text is short', (tester) async {
      await tester.pumpWidget(buildWidget(
        text: shortText,
        maxCharacters: 100,
        showFadeEffect: true,
      ));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.gradient is LinearGradient;
      });

      expect(hasGradient, isFalse);
    });

    testWidgets('custom fadeHeight is applied to gradient container', (tester) async {
      const customHeight = 90.0;
      await tester.pumpWidget(buildWidget(
        showFadeEffect: true,
        fadeHeight: customHeight,
      ));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final fadeContainer = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).gradient is LinearGradient,
        orElse: () => Container(),
      );

      expect(fadeContainer.constraints?.maxHeight, customHeight);
    });

    testWidgets('expandButtonSpacing is applied as top padding in fade mode', (tester) async {
      const spacing = 16.0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              showFadeEffect: true,
              expandButtonSpacing: spacing,
            ),
          ),
        ),
      ));

      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      final hasSpacing = paddings.any(
        (p) => p.padding == const EdgeInsets.only(top: spacing),
      );
      expect(hasSpacing, isTrue);
    });

    testWidgets('gradient is hidden when widget is expanded', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              showFadeEffect: true,
              fadeColor: Colors.white,
              initiallyExpanded: true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.gradient is LinearGradient;
      });
      expect(hasGradient, isFalse);
    });
  });
}
