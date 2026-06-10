## 2.1.1

* Shortened `pubspec.yaml` description to fit pub.dev's 60–180 character
  limit (was 230 characters in 2.1.0 — restored the 10/10 "valid pubspec"
  pana score).
* Added 6 feature screenshots (character trim, fade, rich text, linkify,
  selectable, custom button) and an animated demo GIF showing the expand /
  collapse cycle. Embedded inline at the top of the README via raw GitHub
  URLs. The image files are kept in the repo but excluded from the
  published archive via `.pubignore` to keep the package size small.

## 2.1.0

### New Features

* **`SeeMoreWidget.rich(InlineSpan)`** — new constructor for rich content.
  Styles, tap recognizers, semantics, and `WidgetSpan` icons are preserved
  when the text is truncated mid-span. `WidgetSpan` counts as one character.
* **`linkify: true`** — auto-detect URLs and render each as a tappable styled
  span. Customise via `urlPattern`, `linkStyle`, `onLinkTap`. Works with both
  constructors. Default pattern matches `http(s)://...`; trailing sentence
  punctuation is stripped from each match.
* **`selectable: true`** — wraps the rendered content in a `SelectionArea`
  for long-press selection and platform copy. Inline expand/collapse and
  link taps continue to work inside the selection region.

### Note

* `SeeMoreWidget.text` is now `String?` (was `String`) to accommodate the
  new `.rich` constructor. The default constructor still requires a non-null
  `text` argument — behaviour for existing callers is unchanged, but external
  code reading `widget.text` must now handle the nullable type.

### Limitations

* `linkify` scans each `TextSpan.text` in isolation; URLs split across
  multiple child spans are not detected.

---

## 2.0.0

### Breaking Changes
* `TrimMode` enum now has three values: `character`, `line`, and `word`.
  Any exhaustive `switch` on `TrimMode` in consumer code must add a `word` case.

### New Features
* **`SeeMoreController`** — programmatic expand/collapse from outside the widget.
  Supports `expand()`, `collapse()`, and `toggle()`. Keeps the widget in sync
  with tap-based interactions and fires `onExpand`/`onCollapse` callbacks.
  ```dart
  final ctrl = SeeMoreController();
  SeeMoreWidget("...", controller: ctrl)
  ctrl.expand();
  ```
* **`TrimMode.word`** — trim by word count instead of characters or lines.
  Controlled by the new `maxWords` parameter (default `50`).
  ```dart
  SeeMoreWidget("...", trimMode: TrimMode.word, maxWords: 30)
  ```
* **`expandButtonBuilder`** — replace the default "See More" span with any widget.
  The builder receives `(BuildContext context, VoidCallback onTap)`.
* **`collapseButtonBuilder`** — same for the "See Less" affordance.
  Can be set independently of `expandButtonBuilder`.

### Improvements
* Line-mode TextPainter result is now cached on a `_LineTrimKey` record.
  Repeated builds that don't change text, style, or constraints skip the
  layout pass entirely.
* `fadeColor` default changed from `scaffoldBackgroundColor` to
  `colorScheme.surface`, matching the visible container background in Cards,
  Dialogs, and other surfaces.
* Inline "See More" / "See Less" `TextSpan`s now carry `semanticsLabel` so
  screen readers announce the label without the leading visual-spacing space.
* Default expand button (fade mode) is now wrapped in `Semantics(button: true)`
  so assistive technologies identify it as an interactive control.
* `expandButtonSpacing` is now validated to be `>= 0`.
* Regex patterns used in trim helpers are compiled once as `static final`
  constants instead of on every call.
* Source split into focused `part` files:
  `see_more_state.dart`, `see_more_builders.dart`, `see_more_constants.dart`.
* Tests reorganised into focused files under `test/` (74 tests total).

## 1.0.0

### Breaking Changes
* Complete rewrite with new API
* Renamed parameters for clarity:
  - `trimLength` → `maxCharacters`
  - `trimLines` → `maxLines`
  - `seeMoreText` → `expandText`
  - `seeLessText` → `collapseText`
  - `seeMoreStyle` → `expandTextStyle`
  - `seeLessStyle` → `collapseTextStyle`
  - `enableFade` → `showFadeEffect`
  - `fadeLength` → `fadeHeight`
  - `seeMoreButtonSpacing` → `expandButtonSpacing`

### New Features
* **Fade effect** - Gradient fade at text end like Instagram/Twitter (`showFadeEffect: true`)
* **Line-based trimming** - Trim by number of lines using `trimMode: TrimMode.line`
* **Word boundary trimming** - No more cutting words in half (`trimAtWordBoundary: true`)
* **Ellipsis support** - Customizable ellipsis before expand button (`ellipsis: "..."`)
* **Callbacks** - `onExpand` and `onCollapse` callbacks for state tracking
* **Initial state** - `initiallyExpanded` parameter
* **Theme integration** - Uses theme colors when no style provided
* **Text alignment** - `textAlign` parameter
* **RTL support** - `textDirection` parameter (uses `Directionality.of(context)`)
* **Animation curve** - `animationCurve` parameter
* **Accessibility** - Semantics wrapper and `textScaler` parameter for font scaling
* **Button spacing** - `expandButtonSpacing` parameter for fade mode

### Bug Fixes
* Fixed memory leak - TapGestureRecognizer now properly disposed
* Fixed memory leak - TextPainter now properly disposed
* Fixed text cutting mid-word

### Other
* 25 comprehensive unit tests
* Code organized with `part`/`part of` for better maintainability
* Requires Flutter `>=3.16.0`

## 0.0.5

* added video

## 0.0.4

* minor bug fixes with more attribute

## 0.0.3

* minor bug fixes

## 0.0.2

* Readme updated.

## 0.0.1

* Initial release.
