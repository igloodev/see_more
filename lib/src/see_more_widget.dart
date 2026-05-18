import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'see_more_controller.dart';
import 'trim_mode.dart';

part 'see_more_constants.dart';
part 'see_more_state.dart';
part 'see_more_builders.dart';

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
  /// Creates a SeeMoreWidget.
  ///
  /// The [text] parameter must not be empty.
  ///
  /// When [trimMode] is [TrimMode.character], [maxCharacters] must be > 0.
  /// When [trimMode] is [TrimMode.line],      [maxLines]      must be > 0.
  /// When [trimMode] is [TrimMode.word],      [maxWords]      must be > 0.
  ///
  /// [fadeHeight] must be > 0 when [showFadeEffect] is true.
  const SeeMoreWidget(
    this.text, {
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
  })  : assert(text != '', 'text must not be empty'),
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

  /// The text content to display.
  final String text;

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

  @override
  State<SeeMoreWidget> createState() => _SeeMoreWidgetState();
}
