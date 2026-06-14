import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'see_more_controller.dart';
import 'trim_mode.dart';

part 'see_more_constants.dart';
part 'see_more_state.dart';
part 'see_more_builders.dart';
part 'span_utils.dart';
part 'see_more_annotation.dart';

/// A widget that displays text with expandable/collapsible "See More" functionality.
///
/// Supports character-based, line-based, and word-based trimming with smooth
/// animations, an optional Instagram-style fade gradient, a programmatic
/// [controller], and fully custom expand/collapse button builders.
///
/// ## Basic usage
/// ```dart
/// SeeMoreWidget(
///   "Long text here...",
///   trimMode: TrimMode.line,
///   maxLines: 3,
///   showFadeEffect: true,
/// )
/// ```
///
/// ## Programmatic control
/// ```dart
/// final _ctrl = SeeMoreController();
///
/// SeeMoreWidget("...", controller: _ctrl)
///
/// // Elsewhere:
/// _ctrl.expand();
/// _ctrl.toggle();
/// ```
///
/// ## Custom button builder
/// ```dart
/// SeeMoreWidget(
///   "...",
///   expandButtonBuilder: (context, onTap) => TextButton(
///     onPressed: onTap,
///     child: const Text('Show more'),
///   ),
/// )
/// ```
class SeeMoreWidget extends StatefulWidget {
  /// Creates a SeeMoreWidget from a plain [String].
  ///
  /// The [text] parameter must not be empty.
  ///
  /// When [trimMode] is [TrimMode.character], [maxCharacters] must be > 0.
  /// When [trimMode] is [TrimMode.line],      [maxLines]      must be > 0.
  /// When [trimMode] is [TrimMode.word],      [maxWords]      must be > 0.
  ///
  /// [fadeHeight] must be > 0 when [showFadeEffect] is true.
  ///
  /// For mixed-style text, hyperlinks, mentions, or hashtags use
  /// [SeeMoreWidget.rich] instead.
  const SeeMoreWidget(
    String this.text, {
    super.key,
    this.controller,
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.expandText = 'See More',
    this.expandTextStyle,
    this.collapseText = 'See Less',
    this.collapseTextStyle,
    this.maxCharacters = 240,
    this.maxLines = 3,
    this.maxWords = 50,
    this.trimMode = TrimMode.character,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.initiallyExpanded = false,
    this.ellipsis = '...',
    this.onExpand,
    this.onCollapse,
    this.trimAtWordBoundary = true,
    this.showFadeEffect = false,
    this.fadeHeight = 60.0,
    this.fadeColor,
    this.textScaler,
    this.expandButtonSpacing = _SeeMoreConstants.fadeButtonSpacing,
    this.expandButtonBuilder,
    this.collapseButtonBuilder,
    this.linkify = false,
    this.urlPattern,
    this.linkStyle,
    this.onLinkTap,
    this.annotations,
    this.selectable = false,
  })  : textSpan = null,
        assert(text != '', 'text must not be empty'),
        assert(
          trimMode != TrimMode.character || maxCharacters > 0,
          'maxCharacters must be greater than 0 when trimMode is TrimMode.character',
        ),
        assert(
          trimMode != TrimMode.line || maxLines > 0,
          'maxLines must be greater than 0 when trimMode is TrimMode.line',
        ),
        assert(
          trimMode != TrimMode.word || maxWords > 0,
          'maxWords must be greater than 0 when trimMode is TrimMode.word',
        ),
        assert(
          !showFadeEffect || fadeHeight > 0,
          'fadeHeight must be greater than 0 when showFadeEffect is true',
        ),
        assert(expandText != '', 'expandText must not be empty'),
        assert(collapseText != '', 'collapseText must not be empty'),
        assert(
          expandButtonSpacing >= 0,
          'expandButtonSpacing must be >= 0',
        );

  /// Creates a SeeMoreWidget from a rich [InlineSpan] tree.
  ///
  /// Use this constructor when the content needs mixed styles, hyperlinks,
  /// inline icons via [WidgetSpan], or tappable mentions/hashtags. Styles,
  /// recognizers, and semantics are preserved across truncation — when the
  /// text is trimmed mid-span the resulting prefix still wears the original
  /// style and remains tappable.
  ///
  /// [WidgetSpan] counts as one character for all trim modes (matching
  /// Flutter's text-layout convention).
  ///
  /// Example:
  /// ```dart
  /// SeeMoreWidget.rich(
  ///   TextSpan(children: [
  ///     const TextSpan(text: 'Check out '),
  ///     TextSpan(
  ///       text: 'flutter.dev',
  ///       style: const TextStyle(color: Colors.blue),
  ///       recognizer: TapGestureRecognizer()..onTap = _openLink,
  ///     ),
  ///     const TextSpan(text: ' for more.'),
  ///   ]),
  ///   trimMode: TrimMode.character,
  ///   maxCharacters: 20,
  /// )
  /// ```
  const SeeMoreWidget.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.controller,
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.expandText = 'See More',
    this.expandTextStyle,
    this.collapseText = 'See Less',
    this.collapseTextStyle,
    this.maxCharacters = 240,
    this.maxLines = 3,
    this.maxWords = 50,
    this.trimMode = TrimMode.character,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.initiallyExpanded = false,
    this.ellipsis = '...',
    this.onExpand,
    this.onCollapse,
    this.trimAtWordBoundary = true,
    this.showFadeEffect = false,
    this.fadeHeight = 60.0,
    this.fadeColor,
    this.textScaler,
    this.expandButtonSpacing = _SeeMoreConstants.fadeButtonSpacing,
    this.expandButtonBuilder,
    this.collapseButtonBuilder,
    this.linkify = false,
    this.urlPattern,
    this.linkStyle,
    this.onLinkTap,
    this.annotations,
    this.selectable = false,
  })  : text = null,
        assert(
          trimMode != TrimMode.character || maxCharacters > 0,
          'maxCharacters must be greater than 0 when trimMode is TrimMode.character',
        ),
        assert(
          trimMode != TrimMode.line || maxLines > 0,
          'maxLines must be greater than 0 when trimMode is TrimMode.line',
        ),
        assert(
          trimMode != TrimMode.word || maxWords > 0,
          'maxWords must be greater than 0 when trimMode is TrimMode.word',
        ),
        assert(
          !showFadeEffect || fadeHeight > 0,
          'fadeHeight must be greater than 0 when showFadeEffect is true',
        ),
        assert(expandText != '', 'expandText must not be empty'),
        assert(collapseText != '', 'collapseText must not be empty'),
        assert(
          expandButtonSpacing >= 0,
          'expandButtonSpacing must be >= 0',
        );

  // ── Core ─────────────────────────────────────────────────────────────────────

  /// The plain-text content. Non-null when constructed via [SeeMoreWidget.new];
  /// null when constructed via [SeeMoreWidget.rich].
  final String? text;

  /// The rich span tree. Non-null when constructed via [SeeMoreWidget.rich];
  /// null when constructed via [SeeMoreWidget.new].
  final InlineSpan? textSpan;

  // ── Programmatic control ──────────────────────────────────────────────────────

  /// Optional controller for programmatic expand/collapse.
  ///
  /// When provided, the controller's state takes precedence over
  /// [initiallyExpanded]. Tapping the widget's built-in buttons also keeps
  /// the controller in sync so external listeners stay accurate.
  ///
  /// The controller is **not** disposed by the widget — dispose it yourself.
  final SeeMoreController? controller;

  // ── Trimming ──────────────────────────────────────────────────────────────────

  /// How to trim the text. Defaults to [TrimMode.character].
  final TrimMode trimMode;

  /// Maximum characters before truncation ([TrimMode.character]).
  final int maxCharacters;

  /// Maximum lines before truncation ([TrimMode.line]).
  final int maxLines;

  /// Maximum words before truncation ([TrimMode.word]).
  /// Splitting is whitespace-aware — consecutive whitespace counts as one separator.
  final int maxWords;

  /// Whether to trim at a word boundary to avoid cutting words in half.
  /// Applies to [TrimMode.character] and [TrimMode.line].
  /// [TrimMode.word] is inherently word-boundary trimmed.
  final bool trimAtWordBoundary;

  // ── Text styling ──────────────────────────────────────────────────────────────

  /// Style for the main text. If null, uses [DefaultTextStyle] from context.
  final TextStyle? textStyle;

  /// Text alignment.
  final TextAlign textAlign;

  /// Text direction for RTL support.
  final TextDirection? textDirection;

  /// Text scaler for accessibility. If null, uses [MediaQuery.textScalerOf].
  final TextScaler? textScaler;

  // ── Expand / collapse buttons (text-based) ────────────────────────────────────

  /// Text shown for the expand action. Also used as the Semantics label
  /// regardless of whether [expandButtonBuilder] is provided.
  final String expandText;

  /// Style for the expand button text.
  /// Has no effect when [expandButtonBuilder] is set — style the custom
  /// widget directly inside the builder instead.
  final TextStyle? expandTextStyle;

  /// Text shown for the collapse action. Also used as the Semantics label
  /// regardless of whether [collapseButtonBuilder] is provided.
  final String collapseText;

  /// Style for the collapse button text.
  /// Has no effect when [collapseButtonBuilder] is set — style the custom
  /// widget directly inside the builder instead.
  final TextStyle? collapseTextStyle;

  // ── Custom button builders ────────────────────────────────────────────────────

  /// Custom widget builder for the expand button.
  ///
  /// When provided, the button is rendered **below the text** (never inline).
  ///
  /// ```dart
  /// expandButtonBuilder: (context, onTap) => TextButton.icon(
  ///   onPressed: onTap,
  ///   icon: const Icon(Icons.expand_more),
  ///   label: const Text('Show more'),
  /// ),
  /// ```
  final Widget Function(BuildContext context, VoidCallback onTap)?
      expandButtonBuilder;

  /// Custom widget builder for the collapse button.
  ///
  /// When provided, the button is rendered **below the text** (never inline).
  /// Can be set independently of [expandButtonBuilder].
  final Widget Function(BuildContext context, VoidCallback onTap)?
      collapseButtonBuilder;

  // ── Ellipsis ──────────────────────────────────────────────────────────────────

  /// Ellipsis shown before the inline expand button.
  /// Not shown when [showFadeEffect] is true (the fade replaces it visually).
  final String ellipsis;

  // ── Animation ─────────────────────────────────────────────────────────────────

  /// Duration for expand/collapse animation.
  final Duration animationDuration;

  /// Curve for expand/collapse animation.
  final Curve animationCurve;

  // ── Fade effect ───────────────────────────────────────────────────────────────

  /// Whether to show a gradient fade at the end of truncated text.
  final bool showFadeEffect;

  /// Height of the fade gradient in pixels. Used only when [showFadeEffect] is true.
  final double fadeHeight;

  /// Color for the fade gradient end. If null, uses scaffold background color.
  final Color? fadeColor;

  /// Spacing between truncated text and the expand button when [showFadeEffect]
  /// is true or when [expandButtonBuilder] is set. Defaults to 4.0 px.
  final double expandButtonSpacing;

  // ── Callbacks ─────────────────────────────────────────────────────────────────

  /// Whether to start in expanded state. Ignored when [controller] is provided.
  final bool initiallyExpanded;

  /// Called when the text is expanded (by user tap or controller).
  final VoidCallback? onExpand;

  /// Called when the text is collapsed (by user tap or controller).
  final VoidCallback? onCollapse;

  // ── Linkify ───────────────────────────────────────────────────────────────────

  /// Whether to auto-detect URLs in the content and render each as a
  /// tappable span. Works with both the default and [SeeMoreWidget.rich]
  /// constructors. When `true`, the content is converted into a rich span
  /// tree internally and styles / recognizers from the original tree are
  /// preserved across detected URLs.
  ///
  /// **Limitation — URLs split across child spans are not detected.**
  /// Detection runs per-[TextSpan]: each span's `text` is scanned in
  /// isolation, so a URL written as
  /// `TextSpan(children: [TextSpan('https://'), TextSpan('flutter.dev')])`
  /// is silently skipped. To linkify such content, either pass the URL as
  /// contiguous text in a single span, or pre-process the content before
  /// passing it to [SeeMoreWidget.rich].
  final bool linkify;

  /// Pattern used to detect URLs when [linkify] is `true`. Defaults to
  /// [_SeeMoreConstants.defaultUrlPattern] (case-insensitive `http(s)://...`
  /// with trailing sentence punctuation stripped after the match).
  ///
  /// Set this to support custom schemes (e.g. `mailto:`) or stricter
  /// matching. Zero-width patterns (e.g. `RegExp('')`, `RegExp(r'\b')`) are
  /// silently skipped — they would otherwise produce one recognizer per
  /// character.
  final RegExp? urlPattern;

  /// Style applied to detected URLs. Defaults to Material Blue 700 with an
  /// underline. Pass an explicit [TextStyle] to integrate with your theme.
  final TextStyle? linkStyle;

  /// Called with the matched URL string when the user taps a detected link.
  /// Wire this to `url_launcher` or any custom handler — the package itself
  /// has no networking dependency.
  final void Function(String url)? onLinkTap;

  // ── Annotations ───────────────────────────────────────────────────────────────

  /// Pattern-based annotations to auto-detect, style, and make tappable —
  /// e.g. hashtags, mentions, or any custom [RegExp]. See [SeeMoreAnnotation]
  /// and its [SeeMoreAnnotation.hashtag] / [SeeMoreAnnotation.mention] /
  /// [SeeMoreAnnotation.url] helpers.
  ///
  /// Works with both constructors and composes with [linkify]: detected URLs
  /// (from [linkify]) take precedence, then these annotations in list order.
  /// Styles and recognizers are preserved across truncation.
  final List<SeeMoreAnnotation>? annotations;

  // ── Selection ─────────────────────────────────────────────────────────────────

  /// Whether to make the rendered text user-selectable (long-press / drag to
  /// select, then copy via the platform menu). Wraps the rendered content in
  /// a [SelectionArea], so inline tap recognizers used for expand / collapse
  /// and link taps continue to work.
  final bool selectable;

  @override
  State<SeeMoreWidget> createState() => _SeeMoreWidgetState();
}
