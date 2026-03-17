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
