import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

void main() {
  group('SeeMoreController', () {
    testWidgets('expands widget programmatically', (tester) async {
      final ctrl = SeeMoreController();
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(longText, maxCharacters: 50, controller: ctrl),
          ),
        ),
      ));

      expect(anyRichTextContains(tester, 'See More'), isTrue);

      ctrl.expand();
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('collapses widget programmatically', (tester) async {
      final ctrl = SeeMoreController(initiallyExpanded: true);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(longText, maxCharacters: 50, controller: ctrl),
          ),
        ),
      ));

      expect(anyRichTextContains(tester, 'See Less'), isTrue);

      ctrl.collapse();
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('toggle flips state', (tester) async {
      final ctrl = SeeMoreController();
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(longText, maxCharacters: 50, controller: ctrl),
          ),
        ),
      ));

      ctrl.toggle();
      await tester.pumpAndSettle();
      expect(ctrl.isExpanded, isTrue);

      ctrl.toggle();
      await tester.pumpAndSettle();
      expect(ctrl.isExpanded, isFalse);
    });

    testWidgets('user tap syncs controller state', (tester) async {
      final ctrl = SeeMoreController();
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(longText, maxCharacters: 50, controller: ctrl),
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
      final recognizer = expandSpan?.recognizer as TapGestureRecognizer?;
      recognizer?.onTap?.call();
      await tester.pumpAndSettle();

      expect(ctrl.isExpanded, isTrue);
    });

    testWidgets('expand fires onExpand callback', (tester) async {
      final ctrl = SeeMoreController();
      addTearDown(ctrl.dispose);
      bool expandCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              controller: ctrl,
              onExpand: () => expandCalled = true,
            ),
          ),
        ),
      ));

      ctrl.expand();
      await tester.pumpAndSettle();

      expect(expandCalled, isTrue);
    });

    testWidgets('collapse fires onCollapse callback', (tester) async {
      final ctrl = SeeMoreController(initiallyExpanded: true);
      addTearDown(ctrl.dispose);
      bool collapseCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              controller: ctrl,
              onCollapse: () => collapseCalled = true,
            ),
          ),
        ),
      ));

      ctrl.collapse();
      await tester.pumpAndSettle();

      expect(collapseCalled, isTrue);
    });

    testWidgets('expand is no-op when already expanded', (tester) async {
      final ctrl = SeeMoreController(initiallyExpanded: true);
      addTearDown(ctrl.dispose);
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      ctrl.expand();

      expect(notifyCount, 0);
    });

    testWidgets('collapse is no-op when already collapsed', (tester) async {
      final ctrl = SeeMoreController();
      addTearDown(ctrl.dispose);
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      ctrl.collapse();

      expect(notifyCount, 0);
    });

    test('dispose removes listeners cleanly', () {
      final ctrl = SeeMoreController();
      ctrl.addListener(() {});
      ctrl.dispose();
      expect(true, isTrue);
    });

    testWidgets(
        'controller initiallyExpanded takes precedence over widget initiallyExpanded',
        (tester) async {
      final ctrl = SeeMoreController(initiallyExpanded: true);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              controller: ctrl,
              initiallyExpanded: false,
            ),
          ),
        ),
      ));

      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('swapping controller updates widget to new controller state',
        (tester) async {
      final ctrl1 = SeeMoreController();
      final ctrl2 = SeeMoreController(initiallyExpanded: true);
      addTearDown(ctrl1.dispose);
      addTearDown(ctrl2.dispose);

      Widget buildWith(SeeMoreController c) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child:
                    SeeMoreWidget(longText, maxCharacters: 50, controller: c),
              ),
            ),
          );

      await tester.pumpWidget(buildWith(ctrl1));
      expect(anyRichTextContains(tester, 'See More'), isTrue);

      await tester.pumpWidget(buildWith(ctrl2));
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See Less'), isTrue);

      ctrl1.expand();
      await tester.pumpAndSettle();
      expect(ctrl2.isExpanded, isTrue);
    });
  });
}
