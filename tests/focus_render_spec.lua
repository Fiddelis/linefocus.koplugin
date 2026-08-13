package.path = "./?.lua;./?/init.lua;" .. package.path

local FocusRender = require("lib/focus_render")

local function assert_equal(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local lines = {
    { x = 10, y = 20, w = 200, h = 12 },
    { x = 10, y = 45, w = 200, h = 12 },
    { x = 10, y = 70, w = 200, h = 12 },
    { x = 10, y = 95, w = 200, h = 12 },
}

local marker = FocusRender.markerRect(lines[2], 480, 3)
assert_equal(marker.x, 0, "marker starts at screen edge")
assert_equal(marker.w, 480, "marker spans the screen")
assert_equal(marker.y, 54, "marker sits on the line baseline")
assert_equal(marker.h, 3, "marker uses configured thickness")

local bands = FocusRender.maskBands(lines, 2, 0, 480, 160)
assert_equal(#bands, 2, "mask uses continuous bands")
assert_equal(bands[1].y, 0, "top band starts at screen top")
assert_equal(bands[1].h, 45, "top band reaches focused line")
assert_equal(bands[2].y, 57, "bottom band starts after focused line")
assert_equal(bands[2].h, 103, "bottom band reaches screen bottom")

assert_equal(FocusRender.opacityToGray(0), 1, "zero opacity is white")
assert_equal(FocusRender.opacityToGray(100), 0, "full opacity is black")
assert_equal(FocusRender.opacityToGray(150), 0, "opacity is clamped at one hundred")
assert_equal(FocusRender.lightenPasses(0), 0, "zero opacity does not lighten")
assert_equal(FocusRender.lightenPasses(25), 1, "default opacity uses one pass")
assert_equal(FocusRender.lightenPasses(100), 5, "maximum opacity uses five passes")

local checker = FocusRender.gridLines(bands[1], 10)
assert(#checker > 1, "checker pattern creates multiple grid lines")
assert(checker[1].x ~= checker[2].x or checker[1].y ~= checker[2].y, "checker grid lines have distinct positions")

print("focus_render_spec: ok")
