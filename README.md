# See More

An expandable text widget for Flutter with smooth animations, programmatic control, and rich customisation.

<p align="center">
  <img src="https://raw.githubusercontent.com/igloodev/see_more/master/screenshots/demo.gif" alt="Expand / collapse animation" width="60%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/igloodev/see_more/master/screenshots/03_rich.png" alt="Rich text" width="46%">
  &nbsp;
  <img src="https://raw.githubusercontent.com/igloodev/see_more/master/screenshots/04_linkify.png" alt="Auto linkify" width="46%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/igloodev/see_more/master/screenshots/02_fade.png" alt="Fade effect" width="46%">
  &nbsp;
  <img src="https://raw.githubusercontent.com/igloodev/see_more/master/screenshots/06_custom_button.png" alt="Custom expand button" width="46%">
</p>

## Features

- **Three trim modes** — character-based, line-based, or word-count-based trimming
- **Rich text support** — `SeeMoreWidget.rich(InlineSpan)` preserves nested styles, recognizers, and `WidgetSpan` icons across truncation
- **Auto URL linkification** — `linkify: true` detects `http(s)://` URLs and renders each as a tappable styled span; wire `onLinkTap` to any handler
- **Selectable text** — `selectable: true` wraps content in `SelectionArea` so users can long-press to select and copy
- **`SeeMoreController`** — expand, collapse, or toggle from anywhere in your code
- **Custom button builders** — replace the default "See More" / "See Less" with any widget
- **Fade effect** — gradient fade at text end (like Instagram / Twitter)
- **Word boundary trimming** — never cuts a word in half
- **Customisable ellipsis** — configure the `"..."` text
- **Callbacks** — `onExpand` and `onCollapse` for state tracking
- **Theme integration** — uses theme colours by default
- **RTL support** — respects `Directionality.of(context)`
- **Accessibility** — `Semantics` wrapper, `semanticsLabel` on inline buttons, and `textScaler` support
- **Smooth animations** — configurable duration and curve

## Installation

```yaml
dependencies:
  see_more: ^2.1.0
```

## Usage

### Basic — character-based trimming

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  maxCharacters: 100,
)
```

### Line-based trimming

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  trimMode: TrimMode.line,
  maxLines: 3,
)
```

### Word-based trimming

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  trimMode: TrimMode.word,
  maxWords: 30,
)
```

### Fade effect

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  trimMode: TrimMode.line,
  maxLines: 3,
  showFadeEffect: true,
  fadeHeight: 60,
  fadeColor: Colors.white, // match your container background
)
```

```
┌─────────────────────────────────────┐
│ Lorem ipsum dolor sit amet,        │
│ consectetur adipiscing elit...     │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │  ← gradient fade
│              See More               │
└─────────────────────────────────────┘
```

### Programmatic control with `SeeMoreController`

```dart
final _ctrl = SeeMoreController();

@override
void dispose() {
  _ctrl.dispose();
  super.dispose();
}

// In your widget tree:
SeeMoreWidget("...", controller: _ctrl)

// Anywhere else:
_ctrl.expand();
_ctrl.collapse();
_ctrl.toggle();
print(_ctrl.isExpanded); // true / false
```

The controller stays in sync with user taps — tapping "See More" updates
`_ctrl.isExpanded` and fires `onExpand`, and vice versa.

### Custom button builders

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet...",
  maxLines: 3,
  trimMode: TrimMode.line,
  expandButtonBuilder: (context, onTap) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.expand_more),
    label: const Text('Show more'),
  ),
  collapseButtonBuilder: (context, onTap) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.expand_less),
    label: const Text('Show less'),
  ),
)
```

Custom builders are rendered **below the text** (never inline). They can be
set independently — e.g. a custom expand button with the default collapse span.

### Rich text (mixed styles, inline icons, tappable mentions)

```dart
SeeMoreWidget.rich(
  TextSpan(children: [
    const TextSpan(text: 'Hello, '),
    TextSpan(
      text: 'world',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    const TextSpan(text: '! Visit '),
    TextSpan(
      text: 'flutter.dev',
      style: const TextStyle(color: Colors.blue),
      recognizer: TapGestureRecognizer()..onTap = _openLink,
    ),
    const TextSpan(text: ' for more info.'),
  ]),
  trimMode: TrimMode.character,
  maxCharacters: 30,
)
```

Styles, tap recognizers, and `WidgetSpan` icons are preserved when the text
is truncated mid-span — the visible prefix keeps its formatting.

### Auto URL detection

```dart
SeeMoreWidget(
  'Visit https://flutter.dev to learn more about Flutter.',
  linkify: true,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),  // wire your url_launcher
)
```

Customise the link style or detection pattern:

```dart
SeeMoreWidget(
  'Email me at mailto:hello@example.com please.',
  linkify: true,
  urlPattern: RegExp(r'mailto:\S+'),
  linkStyle: const TextStyle(color: Colors.green, decoration: TextDecoration.underline),
  onLinkTap: (url) => /* ... */,
)
```

`linkify` works equally well with `SeeMoreWidget.rich`. URLs that span across
multiple child spans are not detected — keep each URL contiguous in a single
`TextSpan.text`.

### Selectable text

```dart
SeeMoreWidget(
  "Long content that users may want to copy...",
  selectable: true,
)
```

Wraps the rendered content in a `SelectionArea`. Long-press to select, then
copy via the platform menu. Inline expand/collapse and link taps remain
fully functional inside the selection region.

### Full customisation

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet...",

  // Trim settings
  trimMode: TrimMode.line,
  maxLines: 3,
  trimAtWordBoundary: true,
  ellipsis: "...",

  // Programmatic control
  controller: _ctrl,

  // Fade effect
  showFadeEffect: true,
  fadeHeight: 60,
  fadeColor: Colors.white,
  expandButtonSpacing: 8,

  // Text styles
  textStyle: const TextStyle(fontSize: 16, color: Colors.black87),
  textAlign: TextAlign.start,

  // Expand / collapse button text
  expandText: "Read More",
  expandTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
  collapseText: "Read Less",
  collapseTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),

  // Animation
  animationDuration: const Duration(milliseconds: 300),
  animationCurve: Curves.easeInOut,

  // Initial state (ignored when controller is provided)
  initiallyExpanded: false,

  // Callbacks
  onExpand: () => debugPrint("Expanded"),
  onCollapse: () => debugPrint("Collapsed"),
)
```

## Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `text` | `String?` | required (default ctor) | Plain-text content. Required by the default `SeeMoreWidget(...)` constructor; `null` when using `SeeMoreWidget.rich(...)` |
| `textSpan` | `InlineSpan?` | required (`.rich`) | Rich span tree. Required by `SeeMoreWidget.rich(...)`; `null` when using the default constructor |
| `linkify` | `bool` | `false` | Auto-detect URLs in the content and render each as a tappable styled span |
| `urlPattern` | `RegExp?` | `https?://...` | Custom URL detection pattern for `linkify` (e.g. for `mailto:` support) |
| `linkStyle` | `TextStyle?` | Material Blue 700 + underline | Style applied to detected URLs |
| `onLinkTap` | `void Function(String url)?` | `null` | Called with the matched URL when the user taps a detected link. Wire to `url_launcher` or any custom handler |
| `selectable` | `bool` | `false` | Wraps the content in `SelectionArea` so users can long-press to select and copy |
| `trimMode` | `TrimMode` | `character` | `character`, `line`, or `word` |
| `maxCharacters` | `int` | `240` | Max characters before truncation (`character` mode) |
| `maxLines` | `int` | `3` | Max lines before truncation (`line` mode) |
| `maxWords` | `int` | `50` | Max words before truncation (`word` mode) |
| `trimAtWordBoundary` | `bool` | `true` | Avoid cutting words in half (`character` and `line` modes) |
| `ellipsis` | `String` | `"..."` | Text shown before the inline expand button |
| `controller` | `SeeMoreController?` | `null` | Programmatic expand / collapse control |
| `initiallyExpanded` | `bool` | `false` | Start expanded (ignored when `controller` is provided) |
| `showFadeEffect` | `bool` | `false` | Gradient fade at truncated text end |
| `fadeHeight` | `double` | `60.0` | Height of the fade gradient in pixels |
| `fadeColor` | `Color?` | surface colour | Gradient end colour — match your container background |
| `expandButtonSpacing` | `double` | `4.0` | Gap between text and expand button (fade / custom builder mode) |
| `expandButtonBuilder` | `Widget Function(BuildContext, VoidCallback)?` | `null` | Custom expand button widget |
| `collapseButtonBuilder` | `Widget Function(BuildContext, VoidCallback)?` | `null` | Custom collapse button widget |
| `textStyle` | `TextStyle?` | theme default | Style for the main text |
| `textAlign` | `TextAlign` | `start` | Text alignment |
| `textDirection` | `TextDirection?` | context | RTL support (falls back to `Directionality.of(context)`) |
| `textScaler` | `TextScaler?` | MediaQuery | Accessibility text scaling (falls back to `MediaQuery`) |
| `expandText` | `String` | `"See More"` | Expand button label (also used as Semantics label) |
| `expandTextStyle` | `TextStyle?` | primary colour | Style for expand button (ignored when `expandButtonBuilder` is set) |
| `collapseText` | `String` | `"See Less"` | Collapse button label (also used as Semantics label) |
| `collapseTextStyle` | `TextStyle?` | same as expand | Style for collapse button (ignored when `collapseButtonBuilder` is set) |
| `animationDuration` | `Duration` | `200ms` | Expand / collapse animation duration |
| `animationCurve` | `Curve` | `easeInOut` | Expand / collapse animation curve |
| `onExpand` | `VoidCallback?` | `null` | Called when text is expanded |
| `onCollapse` | `VoidCallback?` | `null` | Called when text is collapsed |

## Demo

[video](https://github.com/igloodev/see_more/assets/35443097/f20a3f37-dba1-4267-a5db-c3df7cd36c52)
