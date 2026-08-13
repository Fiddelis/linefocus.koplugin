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
    object.last_mask_opacity = nil
    object.last_focus_radius = nil
    object.force_full_repaint = true
    object.last_focus_region = nil
    object.mask_bands = nil
    object.mask_pattern = nil
    object.mask_focus_index = nil
    object.mask_radius = nil
    object.mask_line_count = nil
    object.mask_plan = nil
    object.mask_plan_key = nil
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
    if not line then
        return nil
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
    local bands = self:getMaskBands(pattern, lines)
    local plan = self:getMaskPlan(pattern)
    if plan.operation == "none" or plan.factor <= 0 then
        return
    end

    for _, band in ipairs(bands) do
        bb:darkenRect(x + band.x, y + band.y, band.w, band.h, plan.factor)
    end
end

function RulerUI:getMaskPlan(pattern)
    local opacity = self.settings:getMaskOpacity()
    local key = pattern .. ":" .. opacity
    if self.mask_plan_key == key and self.mask_plan then
        return self.mask_plan
    end
    self.mask_plan_key = key
    self.mask_plan = FocusRender.maskPlan(pattern, opacity)
    return self.mask_plan
end

function RulerUI:getMaskBands(pattern, lines)
    local focus_index = self.ruler:getFocusedIndex()
    local radius = pattern == "gray_window" and self.settings:get("focus_radius") or 0
    if self.mask_bands
        and self.mask_pattern == pattern
        and self.mask_focus_index == focus_index
        and self.mask_radius == radius
        and self.mask_line_count == #lines then
        return self.mask_bands
    end
    self.mask_pattern = pattern
    self.mask_focus_index = focus_index
    self.mask_radius = radius
    self.mask_line_count = #lines
    self.mask_bands = FocusRender.maskBands(
        lines,
        focus_index,
        radius,
        Screen:getWidth(),
        Screen:getHeight()
    )
    return self.mask_bands
end

function RulerUI:getFocusRegion(pattern)
    local lines = self.ruler:getLines()
    local region = self.ruler:getFocusedIndex() and FocusRender.focusRegion(
        lines,
        self.ruler:getFocusedIndex(),
        pattern == "gray_window" and self.settings:get("focus_radius") or 0,
        Screen:getWidth(),
        Screen:getHeight()
    ) or nil
    return region and Geom:new(region) or nil
end

function RulerUI:paintMarker(bb, x, y)
    local line = self.ruler:getFocusedLine()
    if not line then
        return
    end

    local marker_opacity = self.settings:getMarkerOpacity()
    if marker_opacity <= 0 then
        return
    end

    local marker = FocusRender.markerRect(line, Screen:getWidth(), self.settings:get("line_thickness"))
    bb:paintRect(
        x + marker.x,
        y + marker.y,
        marker.w,
        marker.h,
        Blitbuffer.gray(FocusRender.opacityToGray(marker_opacity))
    )
end

function RulerUI:updateUI()
    local old_region = self.last_marker_region
    local new_region = self:getMarkerRegion()
    local old_focus_region = self.last_focus_region
    local pattern = self.settings:get("visual_pattern")
    local mask_opacity = self.settings:getMaskOpacity()
    local focus_radius = self.settings:get("focus_radius")
    local pattern_changed = self.last_visual_pattern ~= nil and self.last_visual_pattern ~= pattern
    local gray_settings_changed = pattern ~= "underline"
        and (self.last_mask_opacity ~= nil and self.last_mask_opacity ~= mask_opacity
            or self.last_focus_radius ~= nil and self.last_focus_radius ~= focus_radius)
    local needs_full_repaint = self.force_full_repaint or pattern_changed or gray_settings_changed

    if needs_full_repaint then
        self.pending_update_region = Screen:getSize()
    elseif pattern ~= "underline" then
        self.pending_update_region = Geom:new(FocusRender.transitionRegion(
            old_focus_region,
            self:getFocusRegion(pattern),
            Screen:getWidth(),
            Screen:getHeight()
        ))
    elseif old_region and new_region then
        self.pending_update_region = old_region:combine(new_region)
    else
        self.pending_update_region = old_region or new_region or Screen:getSize()
    end

    self.last_visual_pattern = pattern
    self.last_mask_opacity = mask_opacity
    self.last_focus_radius = focus_radius
    self.force_full_repaint = false
    self.last_marker_region = new_region
    self.last_focus_region = self:getFocusRegion(pattern)
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
    self.force_full_repaint = true
    self.mask_bands = nil
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
        self.force_full_repaint = true
        self.mask_bands = nil
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
