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
local gray_plan = FocusRender.maskPlan("gray_others", 25)
assert_equal(gray_plan.operation, "darkenRect", "gray mask uses one native buffer operation")
assert_equal(gray_plan.factor, 0.25, "gray mask preserves opacity")
assert_equal(FocusRender.maskPlan("underline", 25).operation, "none", "underline skips mask rendering")

local old_focus = FocusRender.focusRegion(lines, 2, 0, 480, 160)
local new_focus = FocusRender.focusRegion(lines, 3, 0, 480, 160)
local transition = FocusRender.transitionRegion(old_focus, new_focus, 480, 160)
assert_equal(transition.y, 45, "mask transition starts at old focus")
assert_equal(transition.h, 37, "mask transition covers old and new focus")

print("focus_render_spec: ok")
