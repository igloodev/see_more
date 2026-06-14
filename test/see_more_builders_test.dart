import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

import 'helpers/see_more_test_helpers.dart';

void main() {
  group('SeeMoreWidget custom button builders', () {
    Widget buildCustomWidget({
      Widget Function(BuildContext, VoidCallback)? expandBuilder,
      Widget Function(BuildContext, VoidCallback)? collapseBuilder,
      bool initiallyExpanded = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              initiallyExpanded: initiallyExpanded,
              expandButtonBuilder: expandBuilder,
              collapseButtonBuilder: collapseBuilder,
            ),
          ),
        ),
      );
    }

    testWidgets('expandButtonBuilder is rendered when collapsed',
        (tester) async {
      await tester.pumpWidget(buildCustomWidget(
        expandBuilder: (_, __) =>
            const Text('CUSTOM_EXPAND', key: Key('custom_expand')),
      ));

      expect(find.byKey(const Key('custom_expand')), findsOneWidget);
    });

    testWidgets('collapseButtonBuilder is rendered when expanded',
        (tester) async {
      await tester.pumpWidget(buildCustomWidget(
        initiallyExpanded: true,
        collapseBuilder: (_, __) =>
            const Text('CUSTOM_COLLAPSE', key: Key('custom_collapse')),
      ));

      expect(find.byKey(const Key('custom_collapse')), findsOneWidget);
    });

    testWidgets('tapping custom expand button expands widget', (tester) async {
      await tester.pumpWidget(buildCustomWidget(
        expandBuilder: (_, onTap) => GestureDetector(
          onTap: onTap,
          child: const Text('CUSTOM_EXPAND', key: Key('custom_expand')),
        ),
      ));

      await tester.tap(find.byKey(const Key('custom_expand')));
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See Less'), isTrue);
    });

    testWidgets('tapping custom collapse button collapses widget',
        (tester) async {
      await tester.pumpWidget(buildCustomWidget(
        initiallyExpanded: true,
        collapseBuilder: (_, onTap) => GestureDetector(
          onTap: onTap,
          child: const Text('CUSTOM_COLLAPSE', key: Key('custom_collapse')),
        ),
      ));

      await tester.tap(find.byKey(const Key('custom_collapse')));
      await tester.pumpAndSettle();

      expect(anyRichTextContains(tester, 'See More'), isTrue);
    });

    testWidgets('custom expand does not show inline See More text',
        (tester) async {
      await tester.pumpWidget(buildCustomWidget(
        expandBuilder: (_, __) => const SizedBox(),
      ));

      final contents = getAllRichTextContents(tester);
      final hasInlineSeeMore = contents.any(
        (c) => c.contains('...') && c.contains('See More'),
      );
      expect(hasInlineSeeMore, isFalse);
    });

    testWidgets('works with TrimMode.line', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              trimMode: TrimMode.line,
              maxLines: 2,
              expandButtonBuilder: (_, __) =>
                  const Text('CUSTOM_EXPAND', key: Key('custom_expand')),
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('custom_expand')), findsOneWidget);
    });

    testWidgets('works with TrimMode.word', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              trimMode: TrimMode.word,
              maxWords: 5,
              expandButtonBuilder: (_, __) =>
                  const Text('CUSTOM_EXPAND', key: Key('custom_expand')),
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('custom_expand')), findsOneWidget);
    });

    testWidgets('expand builder fires onExpand callback', (tester) async {
      bool expandCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              onExpand: () => expandCalled = true,
              expandButtonBuilder: (_, onTap) => GestureDetector(
                onTap: onTap,
                child: const Text('GO', key: Key('go')),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('go')));
      await tester.pumpAndSettle();

      expect(expandCalled, isTrue);
    });

    testWidgets('both builders work together', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeeMoreWidget(
              longText,
              maxCharacters: 50,
              expandButtonBuilder: (_, onTap) => GestureDetector(
                onTap: onTap,
                child: const Text('EXPAND', key: Key('btn_expand')),
              ),
              collapseButtonBuilder: (_, onTap) => GestureDetector(
                onTap: onTap,
                child: const Text('COLLAPSE', key: Key('btn_collapse')),
              ),
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('btn_expand')), findsWidgets);

      await tester.tap(find.byKey(const Key('btn_expand')).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_collapse')), findsWidgets);

      await tester.tap(find.byKey(const Key('btn_collapse')).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_expand')), findsWidgets);
    });
  });
}
