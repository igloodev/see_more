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

  /// Renders an [InlineSpan] tree wrapped with the widget's base [style].
  ///
  /// Used by the rich-mode paths so a user-supplied span tree inherits the
  /// resolved [DefaultTextStyle]+[widget.textStyle] as its base while each
  /// nested span keeps its own overrides.
  Widget _buildRichTextFromSpan({
    required BuildContext context,
    required InlineSpan content,
    required TextStyle style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return RichText(
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textScaler: _getTextScaler(context),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(style: style, children: [content]),
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
    final richSpan = _effectiveRichSpan;

    if (widget.collapseButtonBuilder != null) {
      return Column(
        crossAxisAlignment: _textAlignToCrossAxis(widget.textAlign),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (richSpan != null)
            _buildRichTextFromSpan(
              context: context,
              content: richSpan,
              style: textStyle,
            )
          else
            _buildRichText(
                context: context, text: widget.text!, style: textStyle),
          widget.collapseButtonBuilder!(context, _handleCollapse),
        ],
      );
    }

    final collapseSpan = TextSpan(
      text: ' ${widget.collapseText}',
      style: collapseTextStyle,
      recognizer: _collapseRecognizer,
      semanticsLabel: widget.collapseText,
    );

    if (richSpan != null) {
      return _buildRichTextFromSpan(
        context: context,
        content: TextSpan(children: [richSpan, collapseSpan]),
        style: textStyle,
      );
    }

    return _buildRichText(
      context: context,
      text: widget.text!,
      style: textStyle,
      children: [collapseSpan],
    );
  }

  /// Rich-mode collapsed view: renders a pre-sliced [InlineSpan] with the
  /// ellipsis and (optionally) inline expand affordance appended.
  ///
  /// Mirrors [_buildCollapsedView] but operates on spans so the trimmed
  /// content retains its original nested styles and recognizers.
  Widget _buildCollapsedViewFromSpan({
    required BuildContext context,
    required InlineSpan slicedContent,
    required TextStyle textStyle,
    required TextStyle expandTextStyle,
    int? maxLines,
  }) {
    final isCustom = widget.expandButtonBuilder != null;
    final useInline = !widget.showFadeEffect && !isCustom;

    final children = <InlineSpan>[slicedContent];
    // Fade hides the ellipsis visually; inline + custom-button modes show it.
    if (!widget.showFadeEffect) {
      children.add(TextSpan(text: widget.ellipsis));
    }
    if (useInline) {
      children.add(TextSpan(
        text: ' ${widget.expandText}',
        style: expandTextStyle,
        recognizer: _expandRecognizer,
        semanticsLabel: widget.expandText,
      ));
    }

    return Column(
      crossAxisAlignment: _textAlignToCrossAxis(widget.textAlign),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRichTextFromSpan(
          context: context,
          content: TextSpan(children: children),
          style: textStyle,
          maxLines: maxLines,
        ),
        if (isCustom)
          widget.expandButtonBuilder!(context, _handleExpand)
        else if (widget.showFadeEffect)
          _buildDefaultExpandButton(expandTextStyle),
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
    final richSpan = _effectiveRichSpan;
    final plainLength = _plainText.length;

    if (plainLength <= widget.maxCharacters) {
      if (richSpan != null) {
        return _buildRichTextFromSpan(
            context: context, content: richSpan, style: textStyle);
      }
      return _buildRichText(
          context: context, text: widget.text!, style: textStyle);
    }

    final Widget collapsedView;
    if (richSpan != null) {
      final cutAt = _SpanUtils.charBoundaryIndex(
        _plainText,
        widget.maxCharacters,
        trimAtWordBoundary: widget.trimAtWordBoundary,
      );
      var sliced = _SpanUtils.slice(richSpan, cutAt);
      sliced = _SpanUtils.trimTrailingWhitespace(sliced);
      collapsedView = _buildCollapsedViewFromSpan(
        context: context,
        slicedContent: sliced,
        textStyle: textStyle,
        expandTextStyle: expandTextStyle,
      );
    } else {
      final trimmedText = _trimByCharacter(widget.text!, widget.maxCharacters);
      collapsedView = _buildCollapsedView(
        context: context,
        trimmedText: trimmedText,
        textStyle: textStyle,
        expandTextStyle: expandTextStyle,
      );
    }

    return AnimatedCrossFade(
      firstChild: _wrapWithFade(collapsedView, context, true),
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
    final richSpan = _effectiveRichSpan;
    final source = _plainText;
    final words = source.trim().split(_SeeMoreConstants.whitespaces);

    if (words.length <= widget.maxWords) {
      if (richSpan != null) {
        return _buildRichTextFromSpan(
            context: context, content: richSpan, style: textStyle);
      }
      return _buildRichText(
          context: context, text: widget.text!, style: textStyle);
    }

    final Widget collapsedView;
    if (richSpan != null) {
      final cutAt = _SpanUtils.charIndexAfterNthWord(source, widget.maxWords);
      var sliced = _SpanUtils.slice(richSpan, cutAt);
      sliced = _SpanUtils.trimTrailingWhitespace(sliced);
      collapsedView = _buildCollapsedViewFromSpan(
        context: context,
        slicedContent: sliced,
        textStyle: textStyle,
        expandTextStyle: expandTextStyle,
      );
    } else {
      final trimmedText = _trimByWord(widget.text!, widget.maxWords);
      collapsedView = _buildCollapsedView(
        context: context,
        trimmedText: trimmedText,
        textStyle: textStyle,
        expandTextStyle: expandTextStyle,
      );
    }

    return AnimatedCrossFade(
      firstChild: _wrapWithFade(collapsedView, context, true),
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
        final richSpan = _effectiveRichSpan;

        // Build a compound key from every input that affects the trim result.
        // When the key is unchanged we skip the TextPainter layout entirely.
        // Note: collapseTextStyle is intentionally excluded — it only affects
        // the expanded view and has no influence on where the text is cut.
        // For rich mode, rootSpan carries the content (TextSpan has value-
        // based ==) and text is empty; for string mode the inverse.
        final key = (
          text: richSpan == null ? widget.text! : '',
          rootSpan: richSpan,
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
          if (richSpan != null) {
            return _buildRichTextFromSpan(
                context: context, content: richSpan, style: textStyle);
          }
          return _buildRichText(
              context: context, text: widget.text!, style: textStyle);
        }

        final Widget collapsedView;
        if (richSpan != null) {
          collapsedView = _buildCollapsedViewFromSpan(
            context: context,
            slicedContent: _lineTrimSpanResult ?? const TextSpan(text: ''),
            textStyle: textStyle,
            expandTextStyle: expandTextStyle,
            maxLines: widget.maxLines,
          );
        } else {
          collapsedView = _buildCollapsedView(
            context: context,
            trimmedText: _lineTrimResult,
            textStyle: textStyle,
            expandTextStyle: expandTextStyle,
            maxLines: widget.maxLines,
          );
        }

        return AnimatedCrossFade(
          firstChild: _wrapWithFade(collapsedView, context, true),
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
  /// fields [_lineTrimIsTruncated], [_lineTrimResult] (string mode) and
  /// [_lineTrimSpanResult] (rich mode).
  /// Always called immediately before those fields are read, never from setState.
  void _computeLineTrim({
    required BoxConstraints constraints,
    required TextStyle textStyle,
    required TextStyle expandTextStyle,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required bool useInline,
  }) {
    final richSpan = _effectiveRichSpan;
    // For rich mode, lay out the user's span tree wrapped in the base style
    // so character offsets returned by the painter match the plain-text length.
    final TextSpan paintSpan = richSpan != null
        ? TextSpan(style: textStyle, children: [richSpan])
        : TextSpan(text: widget.text!, style: textStyle);

    final textPainter = TextPainter(
      text: paintSpan,
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
      _lineTrimSpanResult = null;
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

    final source = _plainText;
    endIndex = endIndex.clamp(0, source.length);

    if (widget.trimAtWordBoundary && endIndex > 0) {
      final prefix = source.substring(0, endIndex);
      final lastSpace = prefix.lastIndexOf(_SeeMoreConstants.whitespace);
      if (lastSpace > endIndex * _SeeMoreConstants.wordBoundaryMinRatio) {
        endIndex = lastSpace;
      }
    }

    _lineTrimIsTruncated = true;
    if (richSpan != null) {
      var sliced = _SpanUtils.slice(richSpan, endIndex);
      sliced = _SpanUtils.trimTrailingWhitespace(sliced);
      _lineTrimSpanResult = sliced;
      _lineTrimResult = '';
    } else {
      _lineTrimResult = source.substring(0, endIndex).trimRight();
      _lineTrimSpanResult = null;
    }
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
