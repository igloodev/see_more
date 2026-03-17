import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'trim_mode.dart';

part 'see_more_constants.dart';

/// A widget that displays text with expandable/collapsible "See More" functionality.
///
/// Supports both character-based and line-based trimming with smooth animations.
///
/// Example:
/// ```dart
/// SeeMoreWidget(
///   "Long text here...",
///   trimMode: TrimMode.line,
///   maxLines: 3,
///   showFadeEffect: true,
/// )
/// ```
class SeeMoreWidget extends StatefulWidget {
  /// Creates a SeeMoreWidget.
  ///
  /// The [text] parameter must not be empty.
  ///
  /// When [trimMode] is [TrimMode.character], [maxCharacters] must be greater than 0.
  /// When [trimMode] is [TrimMode.line], [maxLines] must be greater than 0.
  ///
  /// [fadeHeight] must be greater than 0 when [showFadeEffect] is true.
  const SeeMoreWidget(
    this.text, {
    super.key,
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.expandText = "See More",
    this.expandTextStyle,
    this.collapseText = "See Less",
    this.collapseTextStyle,
    this.maxCharacters = 240,
    this.maxLines = 3,
    this.trimMode = TrimMode.character,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.initiallyExpanded = false,
    this.ellipsis = "...",
    this.onExpand,
    this.onCollapse,
    this.trimAtWordBoundary = true,
    this.showFadeEffect = false,
    this.fadeHeight = 60.0,
    this.fadeColor,
    this.textScaler,
    this.expandButtonSpacing = _SeeMoreConstants.fadeButtonSpacing,
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
          !showFadeEffect || fadeHeight > 0,
          'fadeHeight must be greater than 0 when showFadeEffect is true',
        ),
        assert(
          expandText != '',
          'expandText must not be empty',
        ),
        assert(
          collapseText != '',
          'collapseText must not be empty',
        );

  /// The text content to display
  final String text;

  /// Style for the main text content.
  /// If null, uses [DefaultTextStyle] from context.
  final TextStyle? textStyle;

  /// Duration for expand/collapse animation
  final Duration animationDuration;

  /// Curve for expand/collapse animation
  final Curve animationCurve;

  /// Text shown for expand action (e.g., "See More", "Read More")
  final String expandText;

  /// Style for expand button text.
  /// If null, uses [textStyle] with bold and primary color.
  final TextStyle? expandTextStyle;

  /// Text shown for collapse action (e.g., "See Less", "Read Less")
  final String collapseText;

  /// Style for collapse button text.
  /// If null, uses [expandTextStyle].
  final TextStyle? collapseTextStyle;

  /// Maximum characters before truncation (when [trimMode] is [TrimMode.character])
  final int maxCharacters;

  /// Maximum lines before truncation (when [trimMode] is [TrimMode.line])
  final int maxLines;

  /// How to trim the text
  final TrimMode trimMode;

  /// Text alignment
  final TextAlign textAlign;

  /// Text direction for RTL support
  final TextDirection? textDirection;

  /// Whether to start in expanded state
  final bool initiallyExpanded;

  /// Ellipsis text shown before expand button
  final String ellipsis;

  /// Callback when text is expanded
  final VoidCallback? onExpand;

  /// Callback when text is collapsed
  final VoidCallback? onCollapse;

  /// Whether to trim at word boundary (avoids cutting words in half)
  final bool trimAtWordBoundary;

  /// Whether to show a fade effect at the end of truncated text.
  /// Creates a gradient fade from text color to transparent.
  final bool showFadeEffect;

  /// Height of the fade gradient in pixels.
  /// Only used when [showFadeEffect] is true.
  final double fadeHeight;

  /// Color for the fade gradient end.
  /// If null, uses the scaffold/card background color.
  /// Set this to match your container's background.
  final Color? fadeColor;

  /// Text scaler for accessibility support.
  /// If null, uses [MediaQuery.textScalerOf] from context.
  final TextScaler? textScaler;

  /// Spacing between text and expand button when [showFadeEffect] is true.
  /// Defaults to 4.0 pixels.
  final double expandButtonSpacing;

  @override
  State<SeeMoreWidget> createState() => _SeeMoreWidgetState();
}

class _SeeMoreWidgetState extends State<SeeMoreWidget> {
  late bool _isExpanded;
  late TapGestureRecognizer _expandRecognizer;
  late TapGestureRecognizer _collapseRecognizer;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _expandRecognizer = TapGestureRecognizer()..onTap = _handleExpand;
    _collapseRecognizer = TapGestureRecognizer()..onTap = _handleCollapse;
  }

  @override
  void didUpdateWidget(covariant SeeMoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update expanded state if initiallyExpanded changed and widget was rebuilt
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  void dispose() {
    _expandRecognizer.dispose();
    _collapseRecognizer.dispose();
    super.dispose();
  }

  void _handleExpand() {
    setState(() => _isExpanded = true);
    widget.onExpand?.call();
  }

  void _handleCollapse() {
    setState(() => _isExpanded = false);
    widget.onCollapse?.call();
  }

  /// Get effective text style from widget or theme.
  /// Merges provided style with default to ensure color is always set.
  TextStyle _getTextStyle(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;

    if (widget.textStyle == null) {
      return defaultStyle;
    }

    // Merge with default style to ensure color is set
    return defaultStyle.merge(widget.textStyle);
  }

  /// Get effective expand button style.
  /// Ensures color is always set even when custom style is provided.
  TextStyle _getExpandTextStyle(BuildContext context) {
    final baseStyle = _getTextStyle(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final defaultExpandStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: primaryColor,
    );

    if (widget.expandTextStyle == null) {
      return defaultExpandStyle;
    }

    // Merge to ensure color is set
    return defaultExpandStyle.merge(widget.expandTextStyle);
  }

  /// Get effective collapse button style.
  /// Ensures color is always set even when custom style is provided.
  TextStyle _getCollapseTextStyle(BuildContext context) {
    if (widget.collapseTextStyle == null) {
      return _getExpandTextStyle(context);
    }

    final baseStyle = _getExpandTextStyle(context);
    return baseStyle.merge(widget.collapseTextStyle);
  }

  /// Get the fade color (background color to fade to)
  Color _getFadeColor(BuildContext context) {
    if (widget.fadeColor != null) return widget.fadeColor!;

    // Default to scaffold background, which works for most cases
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Get text scaler for accessibility support
  TextScaler _getTextScaler(BuildContext context) {
    return widget.textScaler ?? MediaQuery.textScalerOf(context);
  }

  /// Get effective text direction, respecting widget override or context
  TextDirection _getTextDirection(BuildContext context) {
    return widget.textDirection ?? Directionality.of(context);
  }

  /// Trim text at word boundary
  String _trimAtWordBoundary(String text, int maxLength) {
    if (text.length <= maxLength) return text;

    String trimmed = text.substring(0, maxLength);

    if (widget.trimAtWordBoundary) {
      // Find last space to avoid cutting words
      final lastSpace = trimmed.lastIndexOf(RegExp(r'\s'));
      if (lastSpace > maxLength * _SeeMoreConstants.wordBoundaryMinRatio) {
        // Only use word boundary if it's not too far back
        trimmed = trimmed.substring(0, lastSpace);
      }
    }

    return trimmed.trimRight();
  }

  /// Build the expand button for fade mode
  Widget _buildExpandButton(TextStyle expandTextStyle) {
    return Padding(
      padding: EdgeInsets.only(top: widget.expandButtonSpacing),
      child: GestureDetector(
        onTap: _handleExpand,
        child: Text(
          widget.expandText,
          style: expandTextStyle,
        ),
      ),
    );
  }

  /// Build RichText with common properties
  Widget _buildRichText({
    required BuildContext context,
    required String text,
    required TextStyle style,
    List<InlineSpan>? children,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return RichText(
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textScaler: _getTextScaler(context),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        text: text,
        style: style,
        children: children,
      ),
    );
  }

  /// Build the collapsed view (truncated text with expand button)
  Widget _buildCollapsedView({
    required BuildContext context,
    required String trimmedText,
    required TextStyle textStyle,
    required TextStyle expandTextStyle,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: _textAlignToCrossAxis(widget.textAlign),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRichText(
          context: context,
          text: widget.showFadeEffect
              ? trimmedText
              : "$trimmedText${widget.ellipsis}",
          style: textStyle,
          maxLines: maxLines,
          children: widget.showFadeEffect
              ? null
              : [
                  TextSpan(
                    text: " ${widget.expandText}",
                    style: expandTextStyle,
                    recognizer: _expandRecognizer,
                  ),
                ],
        ),
        if (widget.showFadeEffect) _buildExpandButton(expandTextStyle),
      ],
    );
  }

  /// Build the expanded view (full text with collapse button)
  Widget _buildExpandedView({
    required BuildContext context,
    required TextStyle textStyle,
    required TextStyle collapseTextStyle,
  }) {
    return _buildRichText(
      context: context,
      text: widget.text,
      style: textStyle,
      children: [
        TextSpan(
          text: " ${widget.collapseText}",
          style: collapseTextStyle,
          recognizer: _collapseRecognizer,
        ),
      ],
    );
  }

  /// Wrap widget with fade effect if enabled
  Widget _wrapWithFade(Widget child, BuildContext context, bool isTruncated) {
    if (!widget.showFadeEffect || !isTruncated || _isExpanded) {
      return child;
    }

    final fadeColor = _getFadeColor(context);

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: widget.fadeHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fadeColor.withValues(alpha: 0.0),
                    fadeColor.withValues(alpha: 0.8),
                    fadeColor,
                  ],
                  stops: _SeeMoreConstants.fadeGradientStops,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle(context);
    final expandTextStyle = _getExpandTextStyle(context);
    final collapseTextStyle = _getCollapseTextStyle(context);

    return Semantics(
      expanded: _isExpanded,
      button: true,
      label: _isExpanded ? widget.collapseText : widget.expandText,
      child: widget.trimMode == TrimMode.line
          ? _buildLineBasedWidget(context, textStyle, expandTextStyle, collapseTextStyle)
          : _buildCharacterBasedWidget(context, textStyle, expandTextStyle, collapseTextStyle),
    );
  }

  /// Build widget with character-based trimming
  Widget _buildCharacterBasedWidget(
    BuildContext context,
    TextStyle textStyle,
    TextStyle expandTextStyle,
    TextStyle collapseTextStyle,
  ) {
    // If text is shorter than max characters, just show it
    if (widget.text.length <= widget.maxCharacters) {
      return _buildRichText(
        context: context,
        text: widget.text,
        style: textStyle,
      );
    }

    final trimmedText = _trimAtWordBoundary(widget.text, widget.maxCharacters);

    return AnimatedCrossFade(
      firstChild: _wrapWithFade(
        _buildCollapsedView(
          context: context,
          trimmedText: trimmedText,
          textStyle: textStyle,
          expandTextStyle: expandTextStyle,
        ),
        context,
        true,
      ),
      secondChild: _buildExpandedView(
        context: context,
        textStyle: textStyle,
        collapseTextStyle: collapseTextStyle,
      ),
      crossFadeState:
          _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: widget.animationDuration,
      firstCurve: widget.animationCurve,
      secondCurve: widget.animationCurve,
    );
  }

  /// Build widget with line-based trimming
  Widget _buildLineBasedWidget(
    BuildContext parentContext,
    TextStyle textStyle,
    TextStyle expandTextStyle,
    TextStyle collapseTextStyle,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Create text painter to measure lines
        final textDirection = _getTextDirection(context);
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: textStyle),
          textAlign: widget.textAlign,
          textDirection: textDirection,
          textScaler: _getTextScaler(context),
          maxLines: null,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        // Check if text exceeds max lines
        final lineMetrics = textPainter.computeLineMetrics();
        final totalLines = lineMetrics.length;

        if (totalLines <= widget.maxLines) {
          // Text fits within max lines, no truncation needed
          textPainter.dispose();
          return _buildRichText(
            context: context,
            text: widget.text,
            style: textStyle,
          );
        }

        // Calculate total height of trimmed lines (computed once, reused)
        final trimLinesHeight = lineMetrics.take(widget.maxLines).fold<double>(
          0,
          (sum, metric) => sum + metric.height,
        );

        // Calculate position at end of maxLines
        final positionAtTrimLine = textPainter.getPositionForOffset(
          Offset(constraints.maxWidth, trimLinesHeight),
        );

        // Get character index at that position
        int endIndex = positionAtTrimLine.offset;

        // Reserve space for ellipsis and expand text (only if no fade)
        if (!widget.showFadeEffect) {
          final expandFullText = "${widget.ellipsis} ${widget.expandText}";
          final expandPainter = TextPainter(
            text: TextSpan(text: expandFullText, style: expandTextStyle),
            textDirection: textDirection,
            textScaler: _getTextScaler(context),
          );
          expandPainter.layout();
          final expandWidth = expandPainter.width;
          expandPainter.dispose();

          // Find position that leaves room for expand text
          final targetX =
              constraints.maxWidth - expandWidth - _SeeMoreConstants.seeMorePadding;
          if (targetX > 0) {
            final lastLineHeight = lineMetrics.length >= widget.maxLines
                ? lineMetrics[widget.maxLines - 1].height / 2
                : 0.0;
            final adjustedPosition = textPainter.getPositionForOffset(
              Offset(targetX, trimLinesHeight - lastLineHeight),
            );
            endIndex = adjustedPosition.offset;
          }
        }

        // Dispose text painter after use
        textPainter.dispose();

        // Ensure we don't exceed text length
        endIndex = endIndex.clamp(0, widget.text.length);

        // Trim at word boundary if enabled
        String trimmedText = widget.text.substring(0, endIndex);
        if (widget.trimAtWordBoundary && endIndex > 0) {
          final lastSpace = trimmedText.lastIndexOf(RegExp(r'\s'));
          if (lastSpace > endIndex * _SeeMoreConstants.wordBoundaryMinRatio) {
            trimmedText = trimmedText.substring(0, lastSpace);
          }
        }
        trimmedText = trimmedText.trimRight();

        return AnimatedCrossFade(
          firstChild: _wrapWithFade(
            _buildCollapsedView(
              context: context,
              trimmedText: trimmedText,
              textStyle: textStyle,
              expandTextStyle: expandTextStyle,
              maxLines: widget.maxLines,
            ),
            context,
            true,
          ),
          secondChild: _buildExpandedView(
            context: context,
            textStyle: textStyle,
            collapseTextStyle: collapseTextStyle,
          ),
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: widget.animationDuration,
          firstCurve: widget.animationCurve,
          secondCurve: widget.animationCurve,
        );
      },
    );
  }

  /// Convert TextAlign to CrossAxisAlignment
  CrossAxisAlignment _textAlignToCrossAxis(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.justify:
        return CrossAxisAlignment.stretch;
    }
  }
}
