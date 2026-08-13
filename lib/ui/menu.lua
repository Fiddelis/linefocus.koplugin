local _ = require("gettext")
local DataStorage = require("datastorage")
local Font = require("ui/font")
local Github = require("lib/github")
local InfoMessage = require("ui/widget/infomessage")
local SpinWidget = require("ui/widget/spinwidget")
local UIManager = require("ui/uimanager")

local VERSION = require("linefocus_version")

local Menu = {}

function Menu:new(args)
    local object = {}
    setmetatable(object, self)
    self.__index = self
    object.settings = args.settings
    object.ruler = args.ruler
    object.ruler_ui = args.ruler_ui
    return object
end

function Menu:setAndRefresh(key, value, notification)
    self.settings:set(key, value)
    if self.settings:isEnabled() then
        self.ruler_ui:updateUI()
    end
    if notification then
        self.ruler_ui:displayNotification(notification)
    end
end

function Menu:addToMainMenu(menu_items)
    menu_items.linefocus = {
        text = _("Line focus"),
        sub_item_table = {
            {
                text = _("Toggle line focus"),
                keep_menu_open = true,
                checked_func = function() return self.settings:isEnabled() end,
                callback = function() self.ruler_ui:toggleEnabled() end,
            },
            {
                text = _("Visual pattern"),
                sub_item_table = {
                    self:choice("Underline only", "visual_pattern", "underline"),
                    self:choice("Dim other lines", "visual_pattern", "dim_others"),
                    self:choice("Spotlight focus window", "visual_pattern", "spotlight"),
                    self:choice("Hatch other lines", "visual_pattern", "hatch_others"),
                },
            },
            {
                text = _("Focus marker"),
                sub_item_table = {
                    self:choice("Underline", "marker_style", "underline"),
                    self:choice("Band", "marker_style", "band"),
                    self:choice("Band and underline", "marker_style", "both"),
                    self:choice("No marker", "marker_style", "none"),
                },
            },
            {
                text = _("Line thickness"),
                keep_menu_open = true,
                callback = function() self:showNumberDialog("line_thickness", 0, 12, 1, 2, "Line thickness") end,
            },
            {
                text = _("Marker intensity"),
                keep_menu_open = true,
                callback = function() self:showNumberDialog("line_intensity", 0, 1, 0.1, 0.5, "Marker intensity", "%.2f") end,
            },
            {
                text = _("Spotlight radius"),
                keep_menu_open = true,
                callback = function() self:showNumberDialog("focus_radius", 0, 4, 1, 1, "Spotlight radius") end,
            },
            {
                text = _("Swipe navigation"),
                sub_item_table = {
                    self:choice("Swipe only", "navigation_mode", "swipe"),
                    self:choice("Taps only", "navigation_mode", "tap"),
                    self:choice("Swipe and taps", "navigation_mode", "both"),
                    self:choice("Disabled", "navigation_mode", "none"),
                },
            },
            {
                text = _("Tap navigation zones"),
                sub_item_table = {
                    self:choice("Above / below focus", "tap_navigation", "relative"),
                    self:choice("Top / bottom halves", "tap_navigation", "vertical"),
                    self:choice("Left / right halves", "tap_navigation", "horizontal"),
                    self:choice("Page edges", "tap_navigation", "edges"),
                    self:choice("Tap anywhere to advance", "tap_navigation", "anywhere"),
                    self:choice("Disabled", "tap_navigation", "none"),
                },
            },
            {
                text = _("Notifications"),
                keep_menu_open = true,
                checked_func = function() return self.settings:get("notification") end,
                callback = function() self.settings:toggle("notification") end,
            },
            {
                text = _("About"),
                keep_menu_open = true,
                callback = function() self:showAbout() end,
            },
        },
    }
end

function Menu:choice(label, key, value)
    return {
        text = _(label),
        checked_func = function() return self.settings:get(key) == value end,
        callback = function() self:setAndRefresh(key, value, _(label)) end,
    }
end

function Menu:showNumberDialog(key, minimum, maximum, step, hold_step, title, precision)
    UIManager:show(SpinWidget:new{
        value = self.settings:get(key),
        value_min = minimum,
        value_max = maximum,
        value_step = step,
        value_hold_step = hold_step,
        precision = precision,
        title_text = _(title),
        ok_text = _("Set"),
        callback = function(new_value)
            self:setAndRefresh(key, new_value.value)
        end,
    })
end

function Menu:showAbout()
    local latest = Github:newestRelease()
    local version = table.concat(VERSION, ".")
    local latest_text = latest and " (latest v" .. latest .. ")" or ""
    local settings_file = DataStorage:getSettingsDir() .. "/linefocus_settings.lua"
    UIManager:show(InfoMessage:new{
        text = [[
Line Focus for KOReader
v]] .. version .. latest_text .. [[

Configurable line focus overlay with dimming patterns and gesture navigation.

Project:
github.com/Fiddelis/linefocus.koplugin

Settings:
]] .. settings_file,
        face = Font:getFace("cfont", 18),
        show_icon = false,
    })
end

return Menu
