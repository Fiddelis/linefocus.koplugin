local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local Screen = Device.screen
local TextWidget = require("ui/widget/textwidget")
local Widget = require("ui/widget/widget")

local FocusRender = require("lib/focus_render")

local Preview = Widget:extend{}

local SAMPLE_LINES = {
    "A short example of focused reading,",
    "with punctuation (and parentheses)",
    "kept inside the focus window.",
    "The surrounding lines fade away.",
    "Choose the treatment that feels right.",
}

function Preview:init()
    self.width = self.width or math.floor(Screen:getWidth() * 0.75)
    self.height = self.height or Screen:scaleBySize(190)
    self.line_height = math.floor(self.height / (#SAMPLE_LINES + 1))
    self.dimen = Geom:new{ w = self.width, h = self.height }
    self.text_widgets = {}
    for _, text in ipairs(SAMPLE_LINES) do
        table.insert(self.text_widgets, TextWidget:new{
            text = text,
            face = Font:getFace("infofont"),
            padding = 0,
            forced_height = self.line_height,
            max_width = self.width - Screen:scaleBySize(30),
        })
    end
end

function Preview:paintMask(bb, x, y, lines, focus_index)
    local pattern = self.settings:get("visual_pattern")
    if pattern == "underline" then
        return
    end

    local radius = pattern == "gray_window" and self.settings:get("focus_radius") or 0
    local bands = FocusRender.maskBands(lines, focus_index, radius, self.width, self.height)
    local plan = FocusRender.maskPlan(pattern, self.settings:getMaskOpacity() or 25)
    if plan.operation == "none" or plan.factor <= 0 then
        return
    end
    for _, band in ipairs(bands) do
        bb:darkenRect(x + band.x, y + band.y, band.w, band.h, plan.factor)
    end
end

function Preview:paintMarker(bb, x, y, lines, focus_index)
    local line = lines[focus_index]
    if not line then
        return
    end

    local marker_opacity = self.settings:getMarkerOpacity() or 30
    if marker_opacity > 0 then
        local marker = FocusRender.markerRect(line, self.width, self.settings:get("line_thickness"))
        bb:paintRect(
            x + marker.x,
            y + marker.y,
            marker.w,
            marker.h,
            Blitbuffer.gray(FocusRender.opacityToGray(marker_opacity))
        )
    end
end

function Preview:paintTo(bb, x, y)
    bb:paintRect(x, y, self.width, self.height, Blitbuffer.COLOR_WHITE)
    local lines = {}
    for index, text_widget in ipairs(self.text_widgets) do
        local line_y = Screen:scaleBySize(8) + (index - 1) * self.line_height
        local size = text_widget:getSize()
        table.insert(lines, { x = Screen:scaleBySize(15), y = line_y, w = size.w, h = self.line_height })
        text_widget:paintTo(bb, x + Screen:scaleBySize(15), y + line_y)
    end
    self:paintMask(bb, x, y, lines, 2)
    self:paintMarker(bb, x, y, lines, 2)
end

return Preview
