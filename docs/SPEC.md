# linefocus.koplugin Specification

## Problem Statement

Readers who use a visual ruler to keep their place can benefit from stronger visual guidance, but a single underline does not reduce the distraction created by surrounding lines. The existing Reading Ruler interaction model also leaves readers dependent on a small set of gesture behaviors. KOReader users need a configurable focus aid that can emphasize the current line, visually de-emphasize other lines, and move predictably using the input method that feels natural on their device.

## Solution

`linefocus.koplugin` adds a configurable reading-focus overlay to KOReader. It tracks the visible text lines on the current page, marks one line with a continuous underline, and optionally applies solid-gray treatment to the lines outside the focus window. The same focus state can be moved with swipes, relative taps above or below the focused line, left/right taps, corner and edge taps, tap-to-place mode, dispatcher actions, or page transitions.

Settings are persisted per device. Existing KOReader page navigation remains available when a focus move reaches the first or last visible line. The implementation uses KOReader's native document, gesture, widget, and blitbuffer APIs and has no third-party runtime dependency.

## User Stories

1. As a reader, I want to enable and disable linefocus from the document menu, so that I can turn visual guidance on only when I need it.
2. As a reader, I want the plugin to remember my choices, so that I do not have to configure it for every book or session.
3. As a reader, I want the current text line to be identified by an underline, so that I can keep my place without changing the page layout.
4. As a reader, I want to adjust the marker thickness, so that it remains visible on different fonts and screen sizes.
5. As a reader, I want to adjust marker intensity, so that the focus cue is visible without becoming distracting.
6. As a reader, I want to dim lines other than the focused line, so that surrounding text attracts less attention.
7. As a reader, I want to choose a gray focus window around the focused line, so that I can keep one or more nearby lines readable while graying the rest.
8. As a reader, I want solid-gray dimming with configurable opacity, so that the treatment remains readable and inexpensive on e-ink devices.
9. As a reader, I want a continuous underline marker, so that the focus cue has no visual gaps or navigation-state pattern.
10. As a reader, I want the overlay to work on grayscale e-ink screens, so that it does not depend on color rendering or animation.
11. As a reader, I want to move to the next line with a downward swipe and to the previous line with an upward swipe, so that I can advance while holding the device naturally.
12. As a reader, I want to tap above or below the focused line to move in the corresponding direction, so that I can navigate without swiping.
13. As a reader, I want to tap the left or right side of the page to move backward or forward, so that lateral page gestures are available on devices where vertical taps are inconvenient.
14. As a reader, I want to choose whether taps use vertical zones, horizontal zones, all four edges, or are disabled, so that linefocus does not conflict with my normal KOReader gestures.
15. As a reader, I want a tap-to-place mode, so that I can jump several lines without repeating a gesture.
16. As a reader, I want tapping the focus marker to enter and leave placement mode, so that the mode is discoverable and does not require a separate menu action.
17. As a reader, I want next-line and previous-line actions in KOReader's dispatcher, so that I can bind hardware keys, profiles, or custom gestures to linefocus.
18. As a reader, I want movement past the first or last line to navigate to the adjacent page, so that the focus aid does not trap me at a page boundary.
19. As a reader, I want a previous-page transition to start at the last visible line and a next-page transition to start at the first visible line, so that the focus position follows my reading direction.
20. As a reader, I want a large page jump to start at a deterministic line, so that opening a new location does not place the focus unpredictably.
21. As a reader, I want the plugin to refresh only the old and new overlay regions when possible, so that page turns and line moves do not cause unnecessary e-ink flashes.
22. As a reader, I want linefocus to handle pages with no selectable text without crashing, so that scanned or temporarily unavailable content remains usable.
23. As a reader, I want visible line positions to be recalculated after a page change or layout change, so that the overlay stays aligned with the document.
24. As a reader, I want a short optional notification when linefocus changes state or interaction mode, so that I know which behavior is active.
25. As a reader, I want the plugin to expose its version and project information, so that I can report issues with enough context.
26. As a maintainer, I want the focus and navigation decisions isolated from KOReader widgets, so that they can be tested without an e-reader device.
27. As a maintainer, I want the plugin archive to have the standard `.koplugin` layout, so that it can be installed from a release without manual file rearrangement.
28. As a maintainer, I want the README to document installation, settings, gestures, limitations, and testing, so that users can adopt the plugin without reading its source.
29. As a reader, I want the focus marker to remain visible after moving between lines, so that navigation never loses my place.
30. As a reader, I want dimming to use continuous horizontal regions, so that the overlay does not look like separate rectangles attached to each word or line segment.
31. As a reader, I want punctuation such as parentheses to receive the same treatment as the rest of its line, so that the visual focus is consistent.
32. As a reader, I want opacity controls expressed as a broad percentage range, so that I can make the marker and pattern subtle or strong.
33. As a reader, I want to choose Portuguese for the plugin interface, so that configuration labels and notifications are easy to understand.
34. As a reader, I want to see a live sample while configuring the plugin, so that I can compare patterns without repeatedly returning to the document.
35. As a reader, I want automatic line advance with a configurable interval, so that I can read hands-free.

## Implementation Decisions

- Keep the plugin as a single KOReader Lua plugin with small modules for settings, visible-line extraction, focus state, overlay rendering, menu integration, and plugin entry points.
- Use one primary seam: a pure focus model receives an ordered list of visible line boxes and navigation commands, then returns the focused line index and any page-boundary action. UI code adapts KOReader gestures and widgets to that seam.
- Represent a visible line with its screen rectangle and preserve the original rectangle list for painting. The model must tolerate an empty list and non-contiguous line positions.
- Prefer the document's screen text-box APIs and sort visible boxes by reading position before passing them to the model. This improves behavior for documents that return boxes in a different order and provides a best-effort order for multi-column pages.
- Keep page transitions in the UI adapter because only the reader UI can dispatch `GotoViewRel`. The model reports `next_page` or `previous_page` when movement is requested beyond the current visible list.
- Make visual treatment data-driven through persisted settings. The patterns are `underline`, `gray_others`, and `gray_window`; the gray window uses a configurable number of clear neighboring lines.
- Use KOReader-native blitbuffer operations: one `darkenRect` call per continuous gray band and one `paintRect` call for the underline. Do not use per-line patterns, repeated lighten passes, custom framebuffers, or external rendering dependencies.
- Paint the marker directly from the current focus rectangle instead of delegating its position to a movable widget. This keeps the painted position and dirty region derived from the same state and prevents stale offsets when moving backward or forward.
- Merge text segments with a shared baseline and nearby horizontal gap into one physical line. Keep distant same-height columns separate.
- Persist marker and pattern opacity as percentages. Migrate the previous `line_intensity` value into the equivalent marker opacity when the new setting is first initialized.
- Provide a small local Portuguese dictionary with Automatic/English/Português selection. Use dynamic menu text functions so changing language does not require restarting KOReader.
- Provide a preview card backed by a native `ButtonDialog` and a custom paintable widget. Preview changes update the same persisted settings and repaint the card immediately.
- Schedule automatic next-line movement with KOReader's `UIManager:scheduleIn`, unscheduling it when disabled or when the reader widget closes.
- Keep interaction modes explicit: swipe direction, tap zone policy, tap-to-place mode, and dispatcher actions. A tap on the marker toggles placement mode; a tap while in placement mode chooses the nearest visible line.
- Migrate the previous visual pattern names to their solid-gray equivalents and clamp Kindle-friendly thickness, focus-radius, and automatic-advance ranges.
- Register state and navigation actions with KOReader's dispatcher and register the plugin as a reader view module so it can repaint above the document.
- Build and release a folder named `linefocus.koplugin` inside the archive, matching KOReader's plugin installation convention.
- Retain the upstream MIT license notice because the first implementation is derived from the public Reading Ruler plugin structure and API integration patterns.

## Testing Decisions

- Test only externally observable focus behavior in the pure model: initial placement, next/previous movement, nearest-line placement, empty pages, and page-boundary results.
- Test visual treatment planning as returned regions/operations rather than asserting widget internals. The KOReader adapter is covered by syntax checks and a small set of dependency stubs where practical.
- Test continuous mask bands, one-operation gray planning, continuous marker geometry, opacity clamping, and Portuguese/automatic label selection at the pure seams.
- Run the model tests with the LuaJIT runtime shipped by the development machine; no test framework or third-party dependency is required.
- Run Lua syntax checks over every plugin Lua file before publishing.
- Keep a lightweight rendering plan check so regressions cannot reintroduce repeated buffer passes or per-cell pattern loops on Kindle.
- Manually validate on a KOReader device or emulator: enable/disable, each visual pattern, swipe directions, each tap policy, tap-to-place mode, dispatcher actions, and crossing both page boundaries.
- Prior art for integration behavior is KOReader's reader view modules and the upstream Reading Ruler plugin; tests should not depend on private widget implementation details.

## Out of Scope

- Continuous/rolling scroll mode with a persistent focus line across scroll offsets.
- Full semantic paragraph or word tracking when KOReader's document engine does not expose reliable screen boxes.
- Replacing KOReader's built-in page-turn gestures globally.
- Animated transitions, color-specific themes, or device-specific waveform tuning.
- Synchronizing focus position across devices or books.
- A settings import/migration tool from unrelated third-party plugins.
- Full translation coverage for every KOReader language; this release provides Portuguese and English fallback while the plugin remains dependency-free.

## Further Notes

- Two-column documents are supported on a best-effort basis by ordering visible boxes by screen position; column-specific reading order remains dependent on what the document engine exposes.
- The plugin should fail soft when text boxes are unavailable: it remains enabled but does not paint a stale focus marker.
- The initial release is intentionally dependency-free and compatible with KOReader's Lua module conventions.
