# Line Focus for KOReader

`linefocus.koplugin` is a configurable reading-focus overlay for KOReader. It
keeps a movable focus line while letting you visually reduce distractions from
the surrounding lines.

<p>
  <a href='https://ko-fi.com/H2H311JOCU' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi4.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
</p>

## Features

- Underline, band, or combined marker for the focused line.
- Visual patterns: underline only, dim other lines, spotlight a focus window,
  or hatch other lines.
- Adjustable marker thickness, intensity, and spotlight radius.
- Swipe up/down to move to the previous/next visible line.
- Tap above/below the focus, use top/bottom or left/right zones, tap page
  edges, or tap anywhere to advance.
- Tap the marker to enter tap-to-place mode, then tap any line.
- Automatic previous/next page navigation at line boundaries.
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

- **Visual pattern**: choose how non-focused lines are treated.
- **Focus marker**: choose underline, band, both, or no marker.
- **Line thickness** and **Marker intensity**: tune the focus cue.
- **Spotlight radius**: keep this many neighboring lines undimmed when using
  the spotlight pattern.
- **Swipe navigation**: choose swipes, taps, both, or neither.
- **Tap navigation zones**: choose relative above/below taps, vertical or
  horizontal halves, page edges, anywhere, or disabled.

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
luajit tests/focus_model_spec.lua
```

To check Lua syntax for all source files:

```sh
find . -name '*.lua' -not -path './.git/*' -print0 \
  | xargs -0 -n1 luajit -b /dev/null /private/tmp/linefocus-bytecode
```

For a device or emulator smoke test, validate enabling/disabling, every visual
pattern, each tap policy, swipe directions, tap-to-place mode, dispatcher
actions, and both page boundaries.

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
