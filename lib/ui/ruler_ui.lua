local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Event = require("ui/event")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local Notification = require("ui/widget/notification")
local Screen = Device.screen
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local FocusRender = require("lib/focus_render")
local I18n = require("lib/i18n")

local RulerUI = WidgetContainer:new()

function RulerUI:new(args)
    local object = WidgetContainer:new(args)
    setmetatable(object, self)
    self.__index = self

    object.ruler = args.ruler
    object.settings = args.settings
    object.ui = args.ui
    object.document = args.document
    object.i18n = I18n:new(object.settings)
    object.is_built = false
    object.last_marker_region = nil
    object.pending_update_region = nil
    object.last_visual_pattern = nil
    object.last_marker_style = nil
    object.auto_advance_action = function()
        object:onAutoAdvanceTick()
    end
    return object
end

function RulerUI:tr(text)
    return self.i18n:translate(text)
end

-- Kept as a lifecycle-compatible no-op: the marker is painted directly from
-- focus state, which avoids stale MovableContainer offsets after navigation.
function RulerUI:buildUI()
    self.is_built = true
end

function RulerUI:getMarkerRegion()
    local line = self.ruler:getFocusedLine()
    local marker_style = self.settings:get("marker_style")
    if not line or marker_style == "none" then
        return nil
    end

    if marker_style == "band" or marker_style == "both" then
        return Geom:new{ x = 0, y = line.y, w = Screen:getWidth(), h = line.h }
    end
    return Geom:new(FocusRender.markerRect(line, Screen:getWidth(), self.settings:get("line_thickness")))
end

function RulerUI:getFocusHitRegion()
    local line = self.ruler:getFocusedLine()
    if not line then
        return nil
    end
    return Geom:new{ x = 0, y = line.y, w = Screen:getWidth(), h = line.h }
end

function RulerUI:paintPattern(bb, x, y)
    local pattern = self.settings:get("visual_pattern")
    if pattern == "underline" then
        return
    end

    local lines = self.ruler:getLines()
    if not self.ruler:getFocusedIndex() or #lines == 0 then
        return
    end
    local focus_radius = pattern == "spotlight" and self.settings:get("focus_radius") or 0
    local bands = FocusRender.maskBands(
        lines,
        self.ruler:getFocusedIndex(),
        focus_radius,
        Screen:getWidth(),
        Screen:getHeight()
    )
    local opacity = self.settings:getMaskOpacity() / 100

    for _, band in ipairs(bands) do
        local band_x, band_y = x + band.x, y + band.y
        if pattern == "dim_others" or pattern == "spotlight" then
            -- Continuous bands include punctuation and glyph fragments that
            -- may not have their own text segment. Repeated lightenRect calls
            -- provide opacity control on grayscale e-ink buffers as well.
            for _ = 1, FocusRender.lightenPasses(opacity * 100) do
                bb:lightenRect(band_x, band_y, band.w, band.h)
            end
        elseif pattern == "hatch_others" then
            bb:hatchRect(band_x, band_y, band.w, band.h, math.max(2, math.floor(band.h / 8)), Blitbuffer.COLOR_BLACK, opacity)
        elseif pattern == "checker_others" then
            local cell_size = math.max(Screen:scaleBySize(12), math.floor(Screen:getHeight() / 45))
            for _, grid_line in ipairs(FocusRender.gridLines(band, cell_size)) do
                bb:paintRect(
                    x + grid_line.x,
                    y + grid_line.y,
                    grid_line.w,
                    grid_line.h,
                    Blitbuffer.gray(FocusRender.opacityToGray(opacity * 100))
                )
            end
        end
    end
end

function RulerUI:paintMarker(bb, x, y)
    local line = self.ruler:getFocusedLine()
    if not line then
        return
    end

    local marker_style = self.settings:get("marker_style")
    local marker_opacity = self.settings:getMarkerOpacity() / 100
    if marker_style == "band" or marker_style == "both" then
        bb:hatchRect(
            x,
            y + line.y,
            Screen:getWidth(),
            line.h,
            line.h,
            Blitbuffer.COLOR_BLACK,
            marker_opacity * 0.35
        )
    end
    if marker_style ~= "underline" and marker_style ~= "both" then
        return
    end

    local marker = FocusRender.markerRect(line, Screen:getWidth(), self.settings:get("line_thickness"))
    if self.ruler.line_style == "dashed" then
        for marker_x = 0, marker.w - 1, 20 do
            bb:hatchRect(
                x + marker_x,
                y + marker.y,
                math.min(14, marker.w - marker_x),
                marker.h,
                marker.h,
                Blitbuffer.COLOR_BLACK,
                marker_opacity
            )
        end
    else
        bb:hatchRect(
            x + marker.x,
            y + marker.y,
            marker.w,
            marker.h,
            marker.h,
            Blitbuffer.COLOR_BLACK,
            marker_opacity
        )
    end
end

function RulerUI:updateUI()
    local old_region = self.last_marker_region
    local new_region = self:getMarkerRegion()
    local pattern = self.settings:get("visual_pattern")
    local marker_style = self.settings:get("marker_style")
    local needs_full_repaint = pattern ~= "underline"
        or self.last_visual_pattern ~= nil and self.last_visual_pattern ~= pattern
        or self.last_marker_style ~= nil and self.last_marker_style ~= marker_style

    if needs_full_repaint then
        self.pending_update_region = Screen:getSize()
    elseif old_region and new_region then
        self.pending_update_region = old_region:combine(new_region)
    else
        self.pending_update_region = old_region or new_region or Screen:getSize()
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
    self:paintPattern(bb, x, y)
    self:paintMarker(bb, x, y)
end

function RulerUI:onPageUpdate(new_page)
    if not self.settings:isEnabled() then
        return
    end
    self.ruler:setInitialPositionOnPage(new_page)
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

function RulerUI:refreshAutoAdvance()
    UIManager:unschedule(self.auto_advance_action)
    if self.settings:isEnabled() and self.settings:get("auto_advance") then
        UIManager:scheduleIn(self.settings:get("auto_advance_seconds"), self.auto_advance_action)
    end
end

function RulerUI:onAutoAdvanceTick()
    if not self.settings:isEnabled() or not self.settings:get("auto_advance") then
        return
    end
    self:handleLineNavigation("next")
    self:refreshAutoAdvance()
end

function RulerUI:setEnabled(enabled)
    if enabled then
        self.settings:enable()
        self.ruler:clearCache()
        self.ruler:setInitialPositionOnPage(self.document:getCurrentPage())
        self:updateUI()
        self:refreshAutoAdvance()
        self:displayNotification(self:tr("Line focus enabled"))
    else
        self.settings:disable()
        self.ruler:exitTapToMoveMode()
        self:refreshAutoAdvance()
        UIManager:setDirty("all", function()
            return "ui", Screen:getSize()
        end)
        self:displayNotification(self:tr("Line focus disabled"))
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

    local focus_region = self:getFocusHitRegion()
    local is_tap_on_focus = focus_region and ges.pos:intersectWith(focus_region)
    if is_tap_on_focus then
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

function RulerUI:onCloseWidget()
    UIManager:unschedule(self.auto_advance_action)
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
        text = self:tr("Tap a line to move focus, or tap the marker again to exit."),
        timeout = 3,
    })
end

return RulerUI
