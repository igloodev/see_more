import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

const longText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, '
    'quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.';

const shortText = 'Short text';

bool anyRichTextContains(WidgetTester tester, String text) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  for (final richText in richTexts) {
    // includeSemanticsLabels: false so we match the visible text, not the
    // accessibility label (which omits leading spaces on inline button spans).
    if (richText.text.toPlainText(includeSemanticsLabels: false).contains(text)) {
      return true;
    }
  }
  return false;
}

List<String> getAllRichTextContents(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  return richTexts
      .map((r) => r.text.toPlainText(includeSemanticsLabels: false))
      .toList();
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
