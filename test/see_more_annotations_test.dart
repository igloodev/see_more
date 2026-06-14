import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_more/see_more.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: 320, child: child)));

/// Invokes the tap recognizer of the first rendered span containing [contains].
void _tapSpanContaining(WidgetTester tester, String contains) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    var hit = false;
    r.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text != null &&
          span.text!.contains(contains) &&
          span.recognizer is TapGestureRecognizer) {
        (span.recognizer as TapGestureRecognizer).onTap?.call();
        hit = true;
        return false;
      }
      return true;
    });
    if (hit) return;
  }
  throw StateError('No tappable span containing "$contains" found');
}

({String text, TextStyle? style})? _findLeaf(WidgetTester tester, String c) {
  for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
    ({String text, TextStyle? style})? found;
    r.text.visitChildren((span) {
      if (span is TextSpan && span.text != null && span.text!.contains(c)) {
        found = (text: span.text!, style: span.style);
        return false;
      }
      return true;
    });
    if (found != null) return found;
  }
  return null;
}

void main() {
  testWidgets('detects and taps a #hashtag', (WidgetTester tester) async {
    String? tapped;
    await tester.pumpWidget(_host(SeeMoreWidget(
      'Loving #flutter today',
      initiallyExpanded: true,
      annotations: [SeeMoreAnnotation.hashtag(onTap: (t) => tapped = t)],
    )));
    _tapSpanContaining(tester, '#flutter');
    expect(tapped, '#flutter');
  });

  testWidgets('detects and taps an @mention', (WidgetTester tester) async {
    String? tapped;
    await tester.pumpWidget(_host(SeeMoreWidget(
      'Thanks @flutterdev for the talk',
      initiallyExpanded: true,
      annotations: [SeeMoreAnnotation.mention(onTap: (m) => tapped = m)],
    )));
    _tapSpanContaining(tester, '@flutterdev');
    expect(tapped, '@flutterdev');
  });

  testWidgets('supports a custom annotation pattern', (
    WidgetTester tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(_host(SeeMoreWidget(
      r'Buy $AAPL now',
      initiallyExpanded: true,
      annotations: [
        SeeMoreAnnotation(
            pattern: RegExp(r'\$[A-Z]+'), onTap: (t) => tapped = t),
      ],
    )));
    _tapSpanContaining(tester, r'$AAPL');
    expect(tapped, r'$AAPL');
  });

  testWidgets('composes linkify (URL) + hashtag + mention together', (
    WidgetTester tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(_host(SeeMoreWidget(
      'See https://flutter.dev about #flutter by @team',
      initiallyExpanded: true,
      linkify: true,
      onLinkTap: (u) => taps.add('url:$u'),
      annotations: [
        SeeMoreAnnotation.hashtag(onTap: (t) => taps.add('tag:$t')),
        SeeMoreAnnotation.mention(onTap: (m) => taps.add('mention:$m')),
      ],
    )));
    _tapSpanContaining(tester, 'https://flutter.dev');
    _tapSpanContaining(tester, '#flutter');
    _tapSpanContaining(tester, '@team');
    expect(taps, ['url:https://flutter.dev', 'tag:#flutter', 'mention:@team']);
  });

  testWidgets('applies the annotation style', (WidgetTester tester) async {
    await tester.pumpWidget(_host(SeeMoreWidget(
      'Hello #world',
      initiallyExpanded: true,
      annotations: [
        SeeMoreAnnotation.hashtag(style: const TextStyle(color: Colors.red)),
      ],
    )));
    final leaf = _findLeaf(tester, '#world');
    expect(leaf?.style?.color, Colors.red);
  });

  testWidgets('a hashtag in the visible prefix stays tappable after truncation',
      (WidgetTester tester) async {
    String? tapped;
    await tester.pumpWidget(_host(SeeMoreWidget(
      'Start #early then a lot more text that overflows the limit by a wide '
      'margin indeed so it must truncate',
      maxCharacters: 20,
      annotations: [SeeMoreAnnotation.hashtag(onTap: (t) => tapped = t)],
    )));
    _tapSpanContaining(tester, '#early');
    expect(tapped, '#early');
  });

  testWidgets('a URL wins over a hashtag nested inside it (overlap)', (
    WidgetTester tester,
  ) async {
    String? url;
    String? tag;
    await tester.pumpWidget(_host(SeeMoreWidget(
      'visit https://ex.com/#abc here',
      initiallyExpanded: true,
      linkify: true,
      onLinkTap: (u) => url = u,
      annotations: [SeeMoreAnnotation.hashtag(onTap: (t) => tag = t)],
    )));
    _tapSpanContaining(tester, 'https://ex.com/#abc');
    expect(url, 'https://ex.com/#abc');
    expect(tag, isNull); // the '#abc' inside the URL was suppressed.
  });

  testWidgets('trimTrailingPunctuation strips punctuation on a custom pattern',
      (
    WidgetTester tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(_host(SeeMoreWidget(
      'ref CODE123. end',
      initiallyExpanded: true,
      annotations: [
        SeeMoreAnnotation(
          pattern: RegExp(r'CODE\d+\.?'),
          trimTrailingPunctuation: true,
          onTap: (t) => tapped = t,
        ),
      ],
    )));
    _tapSpanContaining(tester, 'CODE123');
    expect(tapped, 'CODE123'); // trailing '.' stripped.
  });

  testWidgets('latest onTap fires without recognizer rebuild (freshness)', (
    WidgetTester tester,
  ) async {
    String? tapped;
    Widget build(int n) => _host(SeeMoreWidget(
          'tap #x here',
          initiallyExpanded: true,
          annotations: [
            SeeMoreAnnotation.hashtag(onTap: (t) => tapped = 'build$n:$t'),
          ],
        ));
    await tester.pumpWidget(build(1));
    await tester.pumpWidget(build(2)); // new closures, identical structure
    _tapSpanContaining(tester, '#x');
    expect(tapped, 'build2:#x');
  });
}
