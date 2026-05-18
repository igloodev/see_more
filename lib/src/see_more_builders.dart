part of 'see_more_widget.dart';

/// Build helpers for [_SeeMoreWidgetState].
///
/// Kept in a separate part file to reduce the size of the main state file.
/// All members share the same library scope, so private fields such as
/// [_isExpanded], [_expandRecognizer] and [_collapseRecognizer] are fully
/// accessible here.
extension _SeeMoreBuilders on _SeeMoreWidgetState {
  // ── Primitive builders ────────────────────────────────────────────────────────

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
      text: TextSpan(text: text, style: style, children: children),
    );
  }

  /// Default expand button used in fade mode when no [expandButtonBuilder] is set.
  Widget _buildDefaultExpandButton(TextStyle expandTextStyle) {
    return Padding(
      padding: EdgeInsets.only(top: widget.expandButtonSpacing),
      child: Semantics(
        button: true,
        label: widget.expandText,
        child: GestureDetector(
          onTap: _handleExpand,
          child: Text(widget.expandText, style: expandTextStyle),
        ),
      ),
    );
  }

  // ── Collapsed / expanded views ────────────────────────────────────────────────

  /// Builds the collapsed view (truncated text + expand affordance).
  ///
  /// Routing:
  ///   • Custom builder  → separate widget below text (ellipsis still shown)
  ///   • Fade mode       → separate default button below text (no ellipsis)
  ///   • Default         → inline "...See More" inside [RichText]
  Widget _buildCollapsedView({
    required BuildContext context,
    required String trimmedText,
    required TextStyle textStyle,
    required TextStyle expandTextStyle,
    int? maxLines,
  }) {
    final isCustom = widget.expandButtonBuilder != null;
    // Fade hides the ellipsis visually; both inline and custom-button modes show it.
    final displayText =
        widget.showFadeEffect ? trimmedText : '$trimmedText${widget.ellipsis}';

    return Column(
      crossAxisAlignment: _textAlignToCrossAxis(widget.textAlign),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRichText(
          context: context,
          text: displayText,
          style: textStyle,
          maxLines: maxLines,
          // Only inline when neither fade nor a custom builder is active.
          children: (widget.showFadeEffect || isCustom)
              ? null
              : [
                  TextSpan(
                    text: ' ${widget.expandText}',
                    style: expandTextStyle,
                    recognizer: _expandRecognizer,
                    // Announce without the leading space on screen readers.
                    semanticsLabel: widget.expandText,
                  ),
                ],
        ),
        if (isCustom)
          widget.expandButtonBuilder!(context, _handleExpand)
        else if (widget.showFadeEffect)
          _buildDefaultExpandButton(expandTextStyle),
      ],
    );
  }

  /// Builds the expanded view (full text + collapse affordance).
  ///
  /// Routing:
  ///   • Custom builder  → separate widget below text
  ///   • Default         → inline "See Less" inside [RichText]
  Widget _buildExpandedView({
    required BuildContext context,
    required TextStyle textStyle,
    required TextStyle collapseTextStyle,
  }) {
    if (widget.collapseButtonBuilder != null) {
      return Column(
        crossAxisAlignment: _textAlignToCrossAxis(widget.textAlign),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRichText(context: context, text: widget.text, style: textStyle),
          widget.collapseButtonBuilder!(context, _handleCollapse),
        ],
      );
    }

    return _buildRichText(
      context: context,
      text: widget.text,
      style: textStyle,
      children: [
        TextSpan(
          text: ' ${widget.collapseText}',
          style: collapseTextStyle,
          recognizer: _collapseRecognizer,
          semanticsLabel: widget.collapseText,
        ),
      ],
    );
  }

  /// Wraps [child] with an Instagram-style fade gradient when applicable.
  Widget _wrapWithFade(Widget child, BuildContext context, bool isTruncated) {
    if (!widget.showFadeEffect || !isTruncated || _isExpanded) return child;

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

  // ── Trim-mode implementations ─────────────────────────────────────────────────

  Widget _buildCharacterBasedWidget(
    BuildContext context,
    TextStyle textStyle,
    TextStyle expandTextStyle,
    TextStyle collapseTextStyle,
  ) {
    if (widget.text.length <= widget.maxCharacters) {
      return _buildRichText(
          context: context, text: widget.text, style: textStyle);
    }

    final trimmedText = _trimByCharacter(widget.text, widget.maxCharacters);

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

  Widget _buildWordBasedWidget(
    BuildContext context,
    TextStyle textStyle,
    TextStyle expandTextStyle,
    TextStyle collapseTextStyle,
  ) {
    final words = widget.text.trim().split(_SeeMoreConstants.whitespaces);

    if (words.length <= widget.maxWords) {
      return _buildRichText(
          context: context, text: widget.text, style: textStyle);
    }

    final trimmedText = _trimByWord(widget.text, widget.maxWords);

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

  Widget _buildLineBasedWidget(
    BuildContext context,
    TextStyle textStyle,
    TextStyle expandTextStyle,
    TextStyle collapseTextStyle,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = _getTextDirection(context);
        final textScaler = _getTextScaler(context);
        final useInline =
            !widget.showFadeEffect && widget.expandButtonBuilder == null;

        // Build a compound key from every input that affects the trim result.
        // When the key is unchanged we skip the TextPainter layout entirely.
        // Note: collapseTextStyle is intentionally excluded — it only affects
        // the expanded view and has no influence on where the text is cut.
        final key = (
          text: widget.text,
          textStyle: textStyle,
          expandTextStyle: expandTextStyle,
          maxWidth: constraints.maxWidth,
          maxLines: widget.maxLines,
          trimAtWordBoundary: widget.trimAtWordBoundary,
          useInline: useInline,
          ellipsis: widget.ellipsis,
          expandText: widget.expandText,
          textAlign: widget.textAlign,
          textDirection: textDirection,
          textScaler: textScaler,
        );

        if (_lineTrimKey != key) {
          _lineTrimKey = key;
          _computeLineTrim(
            constraints: constraints,
            textStyle: textStyle,
            expandTextStyle: expandTextStyle,
            textDirection: textDirection,
            textScaler: textScaler,
            useInline: useInline,
          );
        }

        if (!_lineTrimIsTruncated) {
          return _buildRichText(
              context: context, text: widget.text, style: textStyle);
        }

        return AnimatedCrossFade(
          firstChild: _wrapWithFade(
            _buildCollapsedView(
              context: context,
              trimmedText: _lineTrimResult,
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

  /// Runs the TextPainter layout pass and writes the result into the cache
  /// fields [_lineTrimIsTruncated] and [_lineTrimResult].
  /// Always called immediately before those fields are read, never from setState.
  void _computeLineTrim({
    required BoxConstraints constraints,
    required TextStyle textStyle,
    required TextStyle expandTextStyle,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required bool useInline,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: textStyle),
      textAlign: widget.textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: null,
    );
    textPainter.layout(maxWidth: constraints.maxWidth);

    final lineMetrics = textPainter.computeLineMetrics();

    if (lineMetrics.length <= widget.maxLines) {
      textPainter.dispose();
      _lineTrimIsTruncated = false;
      _lineTrimResult = '';
      return;
    }

    final trimLinesHeight = lineMetrics
        .take(widget.maxLines)
        .fold<double>(0, (sum, m) => sum + m.height);

    final positionAtTrimLine = textPainter.getPositionForOffset(
      Offset(constraints.maxWidth, trimLinesHeight),
    );
    int endIndex = positionAtTrimLine.offset;

    if (useInline) {
      final expandFullText = '${widget.ellipsis} ${widget.expandText}';
      final expandPainter = TextPainter(
        text: TextSpan(text: expandFullText, style: expandTextStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      );
      expandPainter.layout();
      final expandWidth = expandPainter.width;
      expandPainter.dispose();

      final targetX = constraints.maxWidth -
          expandWidth -
          _SeeMoreConstants.seeMorePadding;
      if (targetX > 0) {
        final lastLineHalfHeight = lineMetrics.length >= widget.maxLines
            ? lineMetrics[widget.maxLines - 1].height / 2
            : 0.0;
        final adjustedPos = textPainter.getPositionForOffset(
          Offset(targetX, trimLinesHeight - lastLineHalfHeight),
        );
        endIndex = adjustedPos.offset;
      }
    }

    textPainter.dispose();

    endIndex = endIndex.clamp(0, widget.text.length);

    String trimmedText = widget.text.substring(0, endIndex);
    if (widget.trimAtWordBoundary && endIndex > 0) {
      final lastSpace = trimmedText.lastIndexOf(_SeeMoreConstants.whitespace);
      if (lastSpace > endIndex * _SeeMoreConstants.wordBoundaryMinRatio) {
        trimmedText = trimmedText.substring(0, lastSpace);
      }
    }

    _lineTrimIsTruncated = true;
    _lineTrimResult = trimmedText.trimRight();
  }

  // ── Utilities ─────────────────────────────────────────────────────────────────

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
      // justify is a text-layout concept; for button alignment below the text
      // stretch is the closest Column equivalent (fills available width).
      case TextAlign.justify:
        return CrossAxisAlignment.stretch;
    }
  }
}
