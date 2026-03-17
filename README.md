# See More

An interactive text widget that supports collapsible and expandable content with smooth animations.

## Features

- **Two trim modes**: Character-based or line-based trimming
- **Fade effect**: Gradient fade at text end (like Instagram/Twitter)
- **Word boundary trimming**: Avoids cutting words in half
- **Customizable ellipsis**: Configure the "..." text
- **Callbacks**: Track expand/collapse state changes
- **Theme integration**: Uses theme colors by default
- **RTL support**: Works with right-to-left languages (uses `Directionality.of(context)`)
- **Accessibility**: Screen reader support with Semantics and `textScaler` for font scaling
- **Smooth animations**: Configurable duration and curve

## Installation

```yaml
dependencies:
  see_more: ^1.0.0
```

## Usage

### Basic Usage (Character-based trimming)

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  maxCharacters: 100,
)
```

### Line-based Trimming

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  trimMode: TrimMode.line,
  maxLines: 3,
)
```

### With Fade Effect

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  trimMode: TrimMode.line,
  maxLines: 3,
  showFadeEffect: true,
  fadeHeight: 60,
  fadeColor: Colors.white, // Match your background
)
```

The fade effect creates a smooth gradient transition at the end of truncated text, similar to Instagram and Twitter. The text fades out and "See More" appears below.

```
┌─────────────────────────────────────┐
│ Lorem ipsum dolor sit amet,        │
│ consectetur adipiscing elit...     │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ ← Gradient fade
│              See More               │
└─────────────────────────────────────┘
```

### Full Customization

```dart
SeeMoreWidget(
  "Lorem ipsum dolor sit amet...",
  // Trim settings
  trimMode: TrimMode.line,
  maxLines: 3,
  trimAtWordBoundary: true,
  ellipsis: "...",

  // Fade effect
  showFadeEffect: true,
  fadeHeight: 60,
  fadeColor: Colors.white,

  // Text styles
  textStyle: const TextStyle(fontSize: 16, color: Colors.black87),
  textAlign: TextAlign.start,

  // Expand/Collapse button customization
  expandText: "Read More",
  expandTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
  collapseText: "Read Less",
  collapseTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),

  // Animation
  animationDuration: const Duration(milliseconds: 300),
  animationCurve: Curves.easeInOut,

  // State
  initiallyExpanded: false,

  // Callbacks
  onExpand: () => print("Expanded!"),
  onCollapse: () => print("Collapsed!"),
)
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `text` | `String` | required | The text content to display |
| `trimMode` | `TrimMode` | `character` | How to trim: `TrimMode.character` or `TrimMode.line` |
| `maxCharacters` | `int` | `240` | Maximum characters before truncation (character mode) |
| `maxLines` | `int` | `3` | Maximum lines before truncation (line mode) |
| `trimAtWordBoundary` | `bool` | `true` | Avoid cutting words in half |
| `ellipsis` | `String` | `"..."` | Text shown before expand button |
| `showFadeEffect` | `bool` | `false` | Enable gradient fade effect |
| `fadeHeight` | `double` | `60.0` | Height of fade gradient in pixels |
| `fadeColor` | `Color?` | scaffold bg | Color to fade to (match your background) |
| `expandButtonSpacing` | `double` | `4.0` | Spacing between text and expand button (fade mode) |
| `textStyle` | `TextStyle?` | theme default | Style for main text |
| `textAlign` | `TextAlign` | `start` | Text alignment |
| `textDirection` | `TextDirection?` | context | For RTL support (uses `Directionality.of(context)`) |
| `textScaler` | `TextScaler?` | MediaQuery | For accessibility text scaling |
| `expandText` | `String` | `"See More"` | Expand button text |
| `expandTextStyle` | `TextStyle?` | primary color | Style for expand button |
| `collapseText` | `String` | `"See Less"` | Collapse button text |
| `collapseTextStyle` | `TextStyle?` | same as expand | Style for collapse button |
| `animationDuration` | `Duration` | `200ms` | Animation duration |
| `animationCurve` | `Curve` | `easeInOut` | Animation curve |
| `initiallyExpanded` | `bool` | `false` | Start in expanded state |
| `onExpand` | `VoidCallback?` | `null` | Called when expanded |
| `onCollapse` | `VoidCallback?` | `null` | Called when collapsed |

## Demo

[video](https://github.com/igloodev/see_more/assets/35443097/f20a3f37-dba1-4267-a5db-c3df7cd36c52)
