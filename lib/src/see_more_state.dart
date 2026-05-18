part of 'see_more_widget.dart';

// Record type used as a compound cache key for the line-based trim pass.
// Dart records have structural equality, so comparison is automatic.
typedef _LineTrimKey = ({
  String text,
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
  String _lineTrimResult = '';

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.controller?.isExpanded ?? widget.initiallyExpanded;
    widget.controller?.addListener(_onControllerChanged);
    _expandRecognizer = TapGestureRecognizer()..onTap = _handleExpand;
    _collapseRecognizer = TapGestureRecognizer()..onTap = _handleCollapse;
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
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _expandRecognizer.dispose();
    _collapseRecognizer.dispose();
    super.dispose();
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

    return Semantics(
      expanded: _isExpanded,
      button: true,
      label: _isExpanded ? widget.collapseText : widget.expandText,
      child: switch (widget.trimMode) {
        TrimMode.line => _buildLineBasedWidget(
            context, textStyle, expandTextStyle, collapseTextStyle),
        TrimMode.word => _buildWordBasedWidget(
            context, textStyle, expandTextStyle, collapseTextStyle),
        TrimMode.character => _buildCharacterBasedWidget(
            context, textStyle, expandTextStyle, collapseTextStyle),
      },
    );
  }
}
