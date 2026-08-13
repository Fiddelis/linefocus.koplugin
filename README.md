# Line Focus for KOReader

`linefocus.koplugin` is a configurable reading-focus overlay for KOReader. It
keeps a movable focus line while letting you visually reduce distractions from
the surrounding lines.

<p>
  <a href='https://ko-fi.com/H2H311JOCU' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi4.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
</p>

## Features

- Continuous underline marker for the focused line.
- Visual treatments: continuous underline, gray other lines, or a gray focus
  window.
- Adjustable underline thickness, underline opacity, gray opacity, and the
  number of neighboring lines kept clear.
- Swipe up/down to move to the previous/next visible line.
- Tap above/below the focus, use top/bottom or left/right zones, tap page
  edges, or tap anywhere to advance.
- Tap the marker to enter tap-to-place mode, then tap any line.
- Automatic previous/next page navigation at line boundaries.
- Optional automatic line advance with a configurable interval.
- Portuguese or English plugin labels, with automatic detection from KOReader.
- A live preview card for trying visual treatments, opacity, and automatic
  advance before closing the configuration menu.
- Dispatcher actions for hardware keys, profiles, and custom gestures.
- Persistent settings and optional notifications.
- Best-effort ordering for multi-column pages.

## Installation

1. Download `linefocus.koplugin.zip` from the latest release.
2. Extract the `linefocus.koplugin` directory into KOReader's `plugins`
   directory.
3. Restart KOReader.
4. Open a document and choose **Menu → Tools → Line focus** (the exact menu
   location can vary by KOReader version).

## Configuration

Open **Line focus** in the document menu:

- **Visual treatment**: choose continuous underline, gray other lines, or a
  gray focus window.
- **Underline thickness**: choose a lightweight 1–4 pixel line.
- **Underline opacity** and **Gray opacity**: tune both cues from 0% to 100%.
- **Lines kept clear around focus**: keep 0–3 neighboring lines clear when
  using the gray focus window.
- **Swipe navigation**: choose swipes, taps, both, or neither.
- **Tap navigation zones**: choose relative above/below taps, vertical or
  horizontal halves, page edges, anywhere, or disabled.
- **Automatic advance**: move to the next line at a chosen interval from 2 to
  60 seconds.
- **Language**: choose Automatic, Português, or English.

Use **Preview and configure** to open a card over the document menu. Its sample
contains punctuation and parentheses so the effect of each visual treatment is
visible before applying it to the page. The preview uses the same solid-gray
and continuous-underline operations as the document overlay.

## Dispatcher actions

The plugin registers:

- `Line focus: move to next line`
- `Line focus: move to previous line`
- `Line focus: toggle`
- `Line focus` enable/disable state action

These can be assigned from KOReader's gesture or profile configuration.

## Development

The repository is dependency-free. The model seam can be tested without a
KOReader device:

```sh
for test in tests/*_spec.lua; do luajit "$test"; done
```

To check Lua syntax for all source files:

```sh
find . -name '*.lua' -not -path './.git/*' -print0 \
  | xargs -0 -n1 luajit -b /dev/null /private/tmp/linefocus-bytecode
```

For a device or emulator smoke test, validate enabling/disabling, all three
visual treatments, opacity changes, each tap policy, swipe directions,
tap-to-place mode, dispatcher actions, automatic advance, and both page
boundaries. On Kindle-class devices, prioritize gray opacity changes and rapid
line navigation to check that the overlay remains responsive.

## Limitations

- Continuous/rolling scroll mode is not yet supported as a persistent focus
  track.
- Multi-column ordering is best effort because it depends on the boxes exposed
  by the document engine.
- Scanned pages without selectable text have no line overlay.

## License and attribution

This project is MIT licensed. The initial KOReader integration was derived from
the public structure and API usage of
[Reading Ruler](https://github.com/Syakhisk/readingruler.koplugin), also MIT
licensed. See [`LICENSE`](LICENSE) and [`NOTICE.md`](NOTICE.md).
