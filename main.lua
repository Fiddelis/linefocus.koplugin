local Device = require("device")
local Screen = Device.screen
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")

local Settings = require("lib/settings")
local Ruler = require("lib/ruler")
local RulerUI = require("lib/ui/ruler_ui")
local Menu = require("lib/ui/menu")
local I18n = require("lib/i18n")
local Dispatcher = require("dispatcher")

local LineFocus = InputContainer:extend{
    name = "linefocus",
    is_doc_only = true,
}

function LineFocus:init()
    self.settings = Settings:new()
    self.i18n = I18n:new(self.settings)
    self.ruler = Ruler:new{
        settings = self.settings,
        ui = self.ui,
        view = self.view,
        document = self.document,
    }
    self.ruler_ui = RulerUI:new{
        settings = self.settings,
        ruler = self.ruler,
        ui = self.ui,
        document = self.document,
    }
    self.menu = Menu:new{
        settings = self.settings,
        ruler = self.ruler,
        ruler_ui = self.ruler_ui,
    }

    self.ui.menu:registerToMainMenu(self.menu)
    self.view:registerViewModule("linefocus", self)
    self:registerGestures()
    self:registerActions()

    if self.settings:isEnabled() then
        self.ruler_ui:buildUI()
    end
end

function LineFocus:registerGestures()
    if not Device:isTouchDevice() then
        return
    end

    self.ges_events = {
        Tap = {
            GestureRange:new{ ges = "tap", range = Geom:new{
                x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight(),
            } },
        },
        Swipe = {
            GestureRange:new{ ges = "swipe", range = Geom:new{
                x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight(),
            } },
        },
    }
end

function LineFocus:registerActions()
    Dispatcher:registerAction("linefocus_move_to_next_line", {
        category = "none",
        event = "LineFocusMoveToNextLine",
        title = self.i18n:translate("Line focus: move to next line"),
        general = true,
    })
    Dispatcher:registerAction("linefocus_move_to_previous_line", {
        category = "none",
        event = "LineFocusMoveToPreviousLine",
        title = self.i18n:translate("Line focus: move to previous line"),
        general = true,
    })
    Dispatcher:registerAction("linefocus_set_state", {
        category = "string",
        event = "LineFocusSetState",
        title = self.i18n:translate("Line focus"),
        general = true,
        args = { true, false },
        toggle = { self.i18n:translate("enable"), self.i18n:translate("disable") },
    })
    Dispatcher:registerAction("linefocus_toggle", {
        category = "none",
        event = "LineFocusToggle",
        title = self.i18n:translate("Line focus: toggle"),
        general = true,
    })
end

function LineFocus:addToMainMenu(menu_items)
    self.menu:addToMainMenu(menu_items)
end

function LineFocus:paintTo(bb, x, y)
    self.ruler_ui:paintTo(bb, x, y)
end

function LineFocus:onPageUpdate(new_page)
    return self.ruler_ui:onPageUpdate(new_page)
end

function LineFocus:onSwipe(arg, ges)
    return self.ruler_ui:onSwipe(arg, ges)
end

function LineFocus:onTap(arg, ges)
    return self.ruler_ui:onTap(arg, ges)
end

function LineFocus:onLineFocusMoveToNextLine()
    self.ruler_ui:handleLineNavigation("next")
end

function LineFocus:onLineFocusMoveToPreviousLine()
    self.ruler_ui:handleLineNavigation("prev")
end

function LineFocus:onLineFocusSetState(state)
    self.ruler_ui:setEnabled(state)
end

function LineFocus:onLineFocusToggle()
    self.ruler_ui:toggleEnabled()
end

return LineFocus
