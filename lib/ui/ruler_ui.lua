local _ = require("gettext")
local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Event = require("ui/event")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local LineWidget = require("ui/widget/linewidget")
local MovableContainer = require("ui/widget/container/movablecontainer")
local Notification = require("ui/widget/notification")
local Screen = Device.screen
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local ignore_events = {
    "hold",
    "hold_release",
    "hold_pan",
    "swipe",
    "touch",
    "pan",
    "pan_release",
}

local RulerUI = WidgetContainer:new()

function RulerUI:new(args)
    local object = WidgetContainer:new(args)
    setmetatable(object, self)
    self.__index = self

    object.ruler = args.ruler
    object.settings = args.settings
    object.ui = args.ui
    object.document = args.document
    object.ruler_widget = nil
    object.touch_container_widget = nil
    object.movable_widget = nil
    object.is_built = false
    object.last_marker_region = nil
    object.pending_update_region = nil
    object.last_visual_pattern = nil
    object.last_marker_style = nil
    return object
end

function RulerUI:buildUI()
    local line_props = self.ruler:getRulerProperties()
    local geom = self.ruler:getRulerGeometry()

    self.ruler_widget = LineWidget:new{
        background = line_props.color,
        style = line_props.style,
        dimen = Geom:new{ w = geom.w, h = geom.h },
    }

    local padding_y = 0.01 * Screen:getHeight()
    self.touch_container_widget = FrameContainer:new{
        bordersize = 0,
        padding = 0,
        padding_top = padding_y,
        padding_bottom = padding_y,
        self.ruler_widget,
    }

    self.movable_widget = MovableContainer:new{
        ignore_events = ignore_events,
        self.touch_container_widget,
    }
    self.is_built = true
end

function RulerUI:getMarkerRegion()
    local line = self.ruler:getFocusedLine()
    if not line then
        return nil
    end
    return Geom:new{
        x = 0,
        y = line.y,
        w = Screen:getWidth(),
        h = line.h,
    }
end

function RulerUI:paintPattern(bb)
    local pattern = self.settings:get("visual_pattern")
    if pattern == "underline" then
        return
    end

    local focus_index = self.ruler:getFocusedIndex()
    local radius = self.settings:get("focus_radius") or 1
    for index, line in ipairs(self.ruler:getLines()) do
        local is_in_focus_window = focus_index and math.abs(index - focus_index) <= radius
        if not is_in_focus_window then
            if pattern == "dim_others" or pattern == "spotlight" then
                bb:lightenRect(line.x or 0, line.y, line.w or Screen:getWidth(), line.h)
            elseif pattern == "hatch_others" then
                bb:hatchRect(
                    line.x or 0,
                    line.y,
                    line.w or Screen:getWidth(),
                    line.h,
                    math.max(2, math.floor(line.h / 3)),
                    Blitbuffer.COLOR_BLACK,
                    0.25
                )
            end
        end
    end
end

function RulerUI:paintMarker(bb)
    local line = self.ruler:getFocusedLine()
    if not line then
        return
    end

    local marker_style = self.settings:get("marker_style")
    if marker_style == "band" or marker_style == "both" then
        bb:hatchRect(
            line.x or 0,
            line.y,
            line.w or Screen:getWidth(),
            line.h,
            math.max(2, math.floor(line.h / 2)),
            Blitbuffer.COLOR_BLACK,
            0.12
        )
    end
    if marker_style == "underline" or marker_style == "both" then
        if self.movable_widget then
            self.movable_widget:paintTo(bb, 0, 0)
        end
    end
end

function RulerUI:updateUI()
    if not self.is_built then
        self:buildUI()
    end

    local old_region = self.last_marker_region
    local geom = self.ruler:getRulerGeometry()
    local padding_top = self.touch_container_widget.padding_top or 0
    local trans_y = geom.y - padding_top
    local current_offset = self.movable_widget:getMovedOffset().y
    if trans_y ~= current_offset then
        self.movable_widget:setMovedOffset({ x = geom.x, y = trans_y })
    end

    local line_props = self.ruler:getRulerProperties()
    self.ruler_widget.background = line_props.color
    self.ruler_widget.style = line_props.style
    self.ruler_widget.dimen.h = line_props.thickness
    local new_region = self:getMarkerRegion()
    local pattern = self.settings:get("visual_pattern")
    local marker_style = self.settings:get("marker_style")
    if self.last_visual_pattern and self.last_visual_pattern ~= pattern
        or self.last_marker_style and self.last_marker_style ~= marker_style then
        self.pending_update_region = Screen:getSize()
    elseif old_region and new_region then
        self.pending_update_region = old_region:combine(new_region)
    else
        self.pending_update_region = new_region or Screen:getSize()
    end
    self.last_visual_pattern = pattern
    self.last_marker_style = marker_style
    self.last_marker_region = new_region
    self:repaint()
end

function RulerUI:getUpdateRegion()
    return self.pending_update_region or self:getMarkerRegion() or Screen:getSize()
end

function RulerUI:repaint()
    if not self.movable_widget then
        return
    end

    local update_region = self:getUpdateRegion()
    self.pending_update_region = nil
    UIManager:setDirty("all", function()
        return "ui", update_region
    end)
end

function RulerUI:paintTo(bb, x, y)
    if not self.settings:isEnabled() then
        return
    end
    self:paintPattern(bb)
    self:paintMarker(bb)
end

function RulerUI:onPageUpdate(new_page)
    if not self.settings:isEnabled() then
        return
    end
    self.ruler:setInitialPositionOnPage(new_page)
    if not self.ruler:getFocusedLine() then
        self.ruler:logNoLines(new_page)
    end
    self:updateUI()
end

function RulerUI:handleLineNavigation(direction)
    local result = direction == "next" and self.ruler:moveToNextLine() or self.ruler:moveToPreviousLine()
    if result == "moved" then
        self:updateUI()
        return true
    elseif result == "next_page" then
        self.ui:handleEvent(Event:new("GotoViewRel", 1))
        return true
    elseif result == "previous_page" then
        self.ui:handleEvent(Event:new("GotoViewRel", -1))
        return true
    end
    return false
end

function RulerUI:setEnabled(enabled)
    if enabled then
        self.settings:enable()
        self:buildUI()
        self.ruler:clearCache()
        self.ruler:setInitialPositionOnPage(self.document:getCurrentPage())
        self:updateUI()
        self:displayNotification(_("Line focus enabled"))
    else
        self.settings:disable()
        self.ruler:exitTapToMoveMode()
        UIManager:setDirty("all", function()
            return "ui", Screen:getSize()
        end)
        self:displayNotification(_("Line focus disabled"))
    end
end

function RulerUI:toggleEnabled()
    self:setEnabled(not self.settings:isEnabled())
end

function RulerUI:getTapDirection(pos)
    local mode = self.settings:get("tap_navigation")
    if mode == "none" then
        return nil
    elseif mode == "anywhere" then
        return "next"
    elseif mode == "horizontal" then
        return pos.x < Screen:getWidth() / 2 and "prev" or "next"
    elseif mode == "vertical" then
        return pos.y < Screen:getHeight() / 2 and "prev" or "next"
    elseif mode == "edges" then
        local edge = math.min(pos.x, Screen:getWidth() - pos.x, pos.y, Screen:getHeight() - pos.y)
        local edge_size = Screen:scaleBySize(100)
        if edge > edge_size then
            return nil
        end
        if pos.x < edge_size or pos.y < edge_size then
            return "prev"
        end
        return "next"
    end

    local focused = self.ruler:getFocusedLine()
    if not focused then
        return nil
    end
    return pos.y < focused.y and "prev" or "next"
end

function RulerUI:onTap(_, ges)
    if not self.settings:isEnabled() then
        return false
    end

    local is_tap_on_marker = self.touch_container_widget
        and self.touch_container_widget.dimen
        and ges.pos:intersectWith(self.touch_container_widget.dimen)

    if is_tap_on_marker then
        if self.ruler:isTapToMoveMode() then
            self.ruler:exitTapToMoveMode()
        else
            self.ruler:enterTapToMoveMode()
            self:notifyTapToMove()
        end
        self:updateUI()
        return true
    end

    if self.ruler:isTapToMoveMode() then
        self.ruler:moveToNearestLine(ges.pos.y)
        self.ruler:exitTapToMoveMode()
        self:updateUI()
        return true
    end

    local navigation_mode = self.settings:get("navigation_mode")
    if navigation_mode == "tap" or navigation_mode == "both" then
        local direction = self:getTapDirection(ges.pos)
        if direction then
            return self:handleLineNavigation(direction)
        end
    end
    return false
end

function RulerUI:onSwipe(_, ges)
    if not self.settings:isEnabled() then
        return false
    end

    local navigation_mode = self.settings:get("navigation_mode")
    if navigation_mode ~= "swipe" and navigation_mode ~= "both" then
        return false
    end

    if ges.direction == "north" then
        return self:handleLineNavigation("prev")
    elseif ges.direction == "south" then
        return self:handleLineNavigation("next")
    end
    return false
end

function RulerUI:displayNotification(text)
    if not self.settings:get("notification") then
        return
    end
    UIManager:show(Notification:new{ text = text, timeout = 2 })
end

function RulerUI:notifyTapToMove()
    UIManager:show(Notification:new{
        face = Font:getFace("xx_smallinfofont"),
        text = _("Tap a line to move focus, or tap the marker again to exit."),
        timeout = 3,
    })
end

return RulerUI
