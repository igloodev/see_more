import 'package:flutter/foundation.dart';

/// Controls the expand/collapse state of a [SeeMoreWidget] programmatically.
///
/// Attach a controller to a widget via [SeeMoreWidget.controller] and call
/// [expand], [collapse], or [toggle] from anywhere in your tree.
///
/// Multiple widgets can share the same controller — they will all react to
/// state changes simultaneously.
///
/// **Always [dispose] the controller** to avoid memory leaks:
///
/// ```dart
/// class _MyWidgetState extends State<MyWidget> {
///   final _seeMoreCtrl = SeeMoreController();
///
///   @override
///   void dispose() {
///     _seeMoreCtrl.dispose();
///     super.dispose();
///   }
/// }
/// ```
class SeeMoreController extends ChangeNotifier {
  /// Creates a [SeeMoreController].
  ///
  /// [initiallyExpanded] sets the starting state. Defaults to `false`.
  SeeMoreController({bool initiallyExpanded = false})
      : _isExpanded = initiallyExpanded;

  bool _isExpanded;

  /// Whether the controlled widget is currently expanded.
  bool get isExpanded => _isExpanded;

  /// Expands the widget. No-op if already expanded.
  void expand() {
    if (_isExpanded) return;
    _isExpanded = true;
    notifyListeners();
  }

  /// Collapses the widget. No-op if already collapsed.
  void collapse() {
    if (!_isExpanded) return;
    _isExpanded = false;
    notifyListeners();
  }

  /// Toggles between expanded and collapsed.
  void toggle() => _isExpanded ? collapse() : expand();
}
