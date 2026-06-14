part of 'see_more_widget.dart';

// Record type used as a compound cache key for the line-based trim pass.
// Dart records have structural equality, so comparison is automatic.
//
// For string mode, [rootSpan] is null and [text] carries the content. For
// rich mode, [rootSpan] carries the content (TextSpan has value-based ==,
// so structurally equal trees hit the cache) and [text] is the empty string.
typedef _LineTrimKey = ({
  String text,
  InlineSpan? rootSpan,
  TextStyle textStyle,
  TextStyle expandTextStyle,
  double maxWidth,
  int maxLines,
  bool trimAtWordBoundary,
  bool useInline,
  String ellipsis,
  String expandText,
  TextAlign textAlign,
  TextDirection textDirection,
  TextScaler textScaler,
});

class _SeeMoreWidgetState extends State<SeeMoreWidget> {
  late bool _isExpanded;
  late final TapGestureRecognizer _expandRecognizer;
  late final TapGestureRecognizer _collapseRecognizer;

  // Cache for the expensive TextPainter layout pass in TrimMode.line.
  // Avoids re-running layout on every build when inputs are unchanged.
  _LineTrimKey? _lineTrimKey;
  bool _lineTrimIsTruncated = false;
  // For string mode: the trimmed substring.
  // For rich mode: ignored (use [_lineTrimSpanResult] instead).
  String _lineTrimResult = '';
  // For rich mode: the sliced span tree.
  InlineSpan? _lineTrimSpanResult;

  // Cached plain-text representation. For string mode it's [widget.text].
  // For rich mode it's computed once from [_effectiveRichSpan] and re-derived
  // when the span instance changes.
  String? _plainTextCache;
  InlineSpan? _plainTextCacheSpan;

  // Linkified content (only populated when [widget.linkify] is true).
  // Built eagerly in initState / didUpdateWidget so the trim builders see
  // a stable rich span to slice. Every TapGestureRecognizer created during
  // linkification is appended to [_linkRecognizers] and disposed on unmount.
  InlineSpan? _linkifiedSpan;
  final List<TapGestureRecognizer> _linkRecognizers = [];

  /// The rich span used by the trim/render pipeline.
  ///
  /// Priority: linkified content (when [widget.linkify] is true) →
  /// the user-supplied [widget.textSpan] → null (pure string mode).
  InlineSpan? get _effectiveRichSpan => _linkifiedSpan ?? widget.textSpan;

  /// The plain-text equivalent of the widget's content.
  ///
  /// For pure string mode this is `widget.text!`. Otherwise it's the
  /// concatenation of all [TextSpan.text] in [_effectiveRichSpan], with
  /// each [WidgetSpan] contributing one OBJECT REPLACEMENT CHARACTER.
  ///
  /// Cache strategy: first checks reference equality (fast path), then
  /// value equality (TextSpan implements structural `==`), so two
  /// structurally identical spans built across rebuilds hit the cache.
  String get _plainText {
    final span = _effectiveRichSpan;
    if (span == null) return widget.text!;
    if (_plainTextCache != null &&
        _plainTextCacheSpan != null &&
        (identical(_plainTextCacheSpan, span) || _plainTextCacheSpan == span)) {
      return _plainTextCache!;
    }
    final computed = _SpanUtils.plainText(span);
    _plainTextCache = computed;
    _plainTextCacheSpan = span;
    return computed;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.controller?.isExpanded ?? widget.initiallyExpanded;
    widget.controller?.addListener(_onControllerChanged);
    _expandRecognizer = TapGestureRecognizer()..onTap = _handleExpand;
    _collapseRecognizer = TapGestureRecognizer()..onTap = _handleCollapse;
    _rebuildLinkifiedSpan();
  }

  @override
  void didUpdateWidget(covariant SeeMoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Swap controller listeners when the controller instance changes.
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
      if (widget.controller != null) {
        _isExpanded = widget.controller!.isExpanded;
      }
    }
    // When no controller, react to initiallyExpanded flips from parent rebuilds.
    if (widget.controller == null &&
        widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
    // Rebuild the linkified span when any input that materially affects its
    // structure changes. Note: [widget.onLinkTap] is deliberately NOT in the
    // comparison — the link recognizers dereference [widget.onLinkTap] at tap
    // time via [_onLinkTapped], so closure-identity changes (very common with
    // anonymous callbacks created in [build]) do not force a recognizer churn.
    if (widget.linkify != oldWidget.linkify ||
        widget.text != oldWidget.text ||
        widget.textSpan != oldWidget.textSpan ||
        widget.urlPattern != oldWidget.urlPattern ||
        widget.linkStyle != oldWidget.linkStyle ||
        _annotationsDiffer(widget.annotations, oldWidget.annotations)) {
      _rebuildLinkifiedSpan();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _expandRecognizer.dispose();
    _collapseRecognizer.dispose();
    _disposeLinkRecognizers();
    super.dispose();
  }

  // ── Linkify ───────────────────────────────────────────────────────────────────

  void _disposeLinkRecognizers() {
    for (final r in _linkRecognizers) {
      r.dispose();
    }
    _linkRecognizers.clear();
  }

  /// The combined annotation list for the current widget: URL detection from
  /// [SeeMoreWidget.linkify] first (so URLs win ties), then the user's
  /// [SeeMoreWidget.annotations] in order. Recomputed cheaply on demand so tap
  /// handlers always read the latest callbacks.
  List<SeeMoreAnnotation> _combinedAnnotations() {
    final list = <SeeMoreAnnotation>[];
    if (widget.linkify) {
      list.add(SeeMoreAnnotation.url(
        pattern: widget.urlPattern,
        style: widget.linkStyle,
        onTap: widget.onLinkTap,
      ));
    }
    if (widget.annotations != null) list.addAll(widget.annotations!);
    return list;
  }

  /// Rebuilds [_linkifiedSpan] (the annotated span) from the current widget
  /// inputs, disposing every recognizer from the previous build first.
  void _rebuildLinkifiedSpan() {
    _disposeLinkRecognizers();
    final combined = _combinedAnnotations();
    if (combined.isEmpty) {
      _linkifiedSpan = null;
      return;
    }
    final source = widget.textSpan ??
        (widget.text != null ? TextSpan(text: widget.text!) : null);
    if (source == null) {
      _linkifiedSpan = null;
      return;
    }
    // Resolve each annotation: default its style and route onTap through an
    // index-keyed forwarder, so recognizers read the LATEST callback at tap
    // time and closure-identity churn between builds never forces a rebuild.
    final resolved = <_ResolvedAnnotation>[];
    for (var i = 0; i < combined.length; i++) {
      final index = i; // fresh binding per iteration for correct capture.
      resolved.add(_ResolvedAnnotation(
        pattern: combined[i].pattern,
        style: combined[i].style ?? _SeeMoreConstants.defaultTagStyle,
        onTap: (match) => _onAnnotationTapped(index, match),
        trimTrailing: combined[i].trimTrailingPunctuation,
      ));
    }
    _linkifiedSpan = _SpanUtils.annotate(
      source,
      annotations: resolved,
      recognizerSink: _linkRecognizers,
    );
  }

  /// Forwards a tap on the annotation at [index] to its current callback,
  /// resolved from the live widget so callback-identity changes between builds
  /// don't require rebuilding the span / recognizers.
  void _onAnnotationTapped(int index, String match) {
    final combined = _combinedAnnotations();
    if (index >= 0 && index < combined.length) {
      combined[index].onTap?.call(match);
    }
  }

  /// Whether two annotation lists differ structurally (pattern / style / trim
  /// flag / count). onTap differences are ignored — they resolve at tap time.
  bool _annotationsDiffer(
    List<SeeMoreAnnotation>? a,
    List<SeeMoreAnnotation>? b,
  ) {
    if (identical(a, b)) return false;
    final al = a ?? const <SeeMoreAnnotation>[];
    final bl = b ?? const <SeeMoreAnnotation>[];
    if (al.length != bl.length) return true;
    for (var i = 0; i < al.length; i++) {
      if (al[i].pattern.pattern != bl[i].pattern.pattern ||
          al[i].pattern.isCaseSensitive != bl[i].pattern.isCaseSensitive ||
          al[i].pattern.isMultiLine != bl[i].pattern.isMultiLine ||
          al[i].pattern.isUnicode != bl[i].pattern.isUnicode ||
          al[i].pattern.isDotAll != bl[i].pattern.isDotAll ||
          al[i].style != bl[i].style ||
          al[i].trimTrailingPunctuation != bl[i].trimTrailingPunctuation) {
        return true;
      }
    }
    return false;
  }

  // ── Controller sync ───────────────────────────────────────────────────────────

  void _onControllerChanged() {
    if (!mounted) return;
    final next = widget.controller!.isExpanded;
    if (_isExpanded == next) return; // already in sync — skip rebuild
    setState(() => _isExpanded = next);
    if (next) {
      widget.onExpand?.call();
    } else {
      widget.onCollapse?.call();
    }
  }

  void _handleExpand() {
    setState(() => _isExpanded = true);
    // Sync controller; the guard in _onControllerChanged prevents a double rebuild.
    widget.controller?.expand();
    widget.onExpand?.call();
  }

  void _handleCollapse() {
    setState(() => _isExpanded = false);
    widget.controller?.collapse();
    widget.onCollapse?.call();
  }

  // ── Style helpers ─────────────────────────────────────────────────────────────

  TextStyle _getTextStyle(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    if (widget.textStyle == null) return defaultStyle;
    return defaultStyle.merge(widget.textStyle);
  }

  TextStyle _getExpandTextStyle(BuildContext context) {
    final base = _getTextStyle(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final defaultStyle = base.copyWith(
      fontWeight: FontWeight.w600,
      color: primaryColor,
    );
    if (widget.expandTextStyle == null) return defaultStyle;
    return defaultStyle.merge(widget.expandTextStyle);
  }

  TextStyle _getCollapseTextStyle(BuildContext context) {
    if (widget.collapseTextStyle == null) return _getExpandTextStyle(context);
    return _getExpandTextStyle(context).merge(widget.collapseTextStyle);
  }

  // colorScheme.surface matches any container (Card, Dialog, etc.), unlike
  // scaffoldBackgroundColor which only matches the page background.
  Color _getFadeColor(BuildContext context) =>
      widget.fadeColor ?? Theme.of(context).colorScheme.surface;

  TextScaler _getTextScaler(BuildContext context) =>
      widget.textScaler ?? MediaQuery.textScalerOf(context);

  TextDirection _getTextDirection(BuildContext context) =>
      widget.textDirection ?? Directionality.of(context);

  // ── Trim helpers ──────────────────────────────────────────────────────────────

  /// Trims [text] to [maxLength] characters, optionally at a word boundary.
  String _trimByCharacter(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    String trimmed = text.substring(0, maxLength);
    if (widget.trimAtWordBoundary) {
      final lastSpace = trimmed.lastIndexOf(_SeeMoreConstants.whitespace);
      if (lastSpace > maxLength * _SeeMoreConstants.wordBoundaryMinRatio) {
        trimmed = trimmed.substring(0, lastSpace);
      }
    }
    return trimmed.trimRight();
  }

  /// Trims [text] to [maxWords] words. Always word-boundary safe by design.
  String _trimByWord(String text, int maxWords) {
    final words = text.trim().split(_SeeMoreConstants.whitespaces);
    if (words.length <= maxWords) return text;
    return words.take(maxWords).join(' ');
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle(context);
    final expandTextStyle = _getExpandTextStyle(context);
    final collapseTextStyle = _getCollapseTextStyle(context);

    Widget body = switch (widget.trimMode) {
      TrimMode.line => _buildLineBasedWidget(
          context, textStyle, expandTextStyle, collapseTextStyle),
      TrimMode.word => _buildWordBasedWidget(
          context, textStyle, expandTextStyle, collapseTextStyle),
      TrimMode.character => _buildCharacterBasedWidget(
          context, textStyle, expandTextStyle, collapseTextStyle),
    };
    if (widget.selectable) {
      body = SelectionArea(child: body);
    }

    return Semantics(
      expanded: _isExpanded,
      button: true,
      label: _isExpanded ? widget.collapseText : widget.expandText,
      child: body,
    );
  }
}
