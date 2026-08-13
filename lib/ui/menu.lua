local ButtonDialog = require("ui/widget/buttondialog")
local DataStorage = require("datastorage")
local Font = require("ui/font")
local Github = require("lib/github")
local InfoMessage = require("ui/widget/infomessage")
local Preview = require("lib/ui/preview")
local SpinWidget = require("ui/widget/spinwidget")
local UIManager = require("ui/uimanager")

local I18n = require("lib/i18n")
local VERSION = require("linefocus_version")

local Menu = {}

function Menu:new(args)
    local object = {}
    setmetatable(object, self)
    self.__index = self
    object.settings = args.settings
    object.ruler = args.ruler
    object.ruler_ui = args.ruler_ui
    object.i18n = I18n:new(object.settings)
    object.preview_dialog = nil
    return object
end

function Menu:tr(text)
    return self.i18n:translate(text)
end

function Menu:setAndRefresh(key, value, notification)
    self.settings:set(key, value)
    if self.settings:isEnabled() then
        self.ruler_ui:updateUI()
    end
    if key == "auto_advance" or key == "auto_advance_seconds" then
        self.ruler_ui:refreshAutoAdvance()
    end
    if notification then
        self.ruler_ui:displayNotification(self:tr(notification))
    end
end

function Menu:addToMainMenu(menu_items)
    menu_items.linefocus = {
        text_func = function() return self:tr("Line focus") end,
        sub_item_table = {
            {
                text_func = function() return self:tr("Toggle line focus") end,
                keep_menu_open = true,
                checked_func = function() return self.settings:isEnabled() end,
                callback = function() self.ruler_ui:toggleEnabled() end,
            },
            {
                text_func = function() return self:tr("Preview and configure") end,
                keep_menu_open = true,
                callback = function() self:showPreview() end,
            },
            {
                text_func = function() return self:tr("Visual treatment") end,
                sub_item_table = {
                    self:choice("Continuous underline", "visual_pattern", "underline"),
                    self:choice("Gray other lines", "visual_pattern", "gray_others"),
                    self:choice("Gray focus window", "visual_pattern", "gray_window"),
                },
            },
            {
                text_func = function() return self:tr("Underline thickness") end,
                keep_menu_open = true,
                callback = function() self:showNumberDialog("line_thickness", 1, 4, 1, 1, "Underline thickness") end,
            },
            {
                text_func = function() return self:tr("Underline opacity") end,
                keep_menu_open = true,
                callback = function() self:showNumberDialog("marker_opacity", 0, 100, 5, 10, "Underline opacity", "%.0f%%") end,
            },
            {
                text_func = function() return self:tr("Gray opacity") end,
                keep_menu_open = true,
                callback = function() self:showNumberDialog("mask_opacity", 0, 100, 5, 10, "Gray opacity", "%.0f%%") end,
            },
            {
                text_func = function() return self:tr("Lines kept clear around focus") end,
                keep_menu_open = true,
                callback = function() self:showNumberDialog("focus_radius", 0, 3, 1, 1, "Lines kept clear around focus") end,
            },
            {
                text_func = function() return self:tr("Navigation") end,
                sub_item_table = {
                    self:choice("Swipe up/down", "navigation_mode", "swipe"),
                    self:choice("Tap above/below", "navigation_mode", "tap"),
                    self:choice("Swipes and taps", "navigation_mode", "both"),
                    self:choice("Disabled", "navigation_mode", "none"),
                },
            },
            {
                text_func = function() return self:tr("Tap direction") end,
                sub_item_table = {
                    self:choice("Above/below focus", "tap_navigation", "relative"),
                    self:choice("Top/bottom halves", "tap_navigation", "vertical"),
                    self:choice("Left/right halves", "tap_navigation", "horizontal"),
                    self:choice("Page edges", "tap_navigation", "edges"),
                    self:choice("Anywhere advances", "tap_navigation", "anywhere"),
                    self:choice("Disabled", "tap_navigation", "none"),
                },
            },
            {
                text_func = function() return self:tr("Automatic advance") end,
                keep_menu_open = true,
                checked_func = function() return self.settings:get("auto_advance") end,
                callback = function() self:setAndRefresh("auto_advance", not self.settings:get("auto_advance")) end,
            },
            {
                text_func = function() return self:tr("Automatic advance interval") end,
                keep_menu_open = true,
                callback = function() self:showNumberDialog("auto_advance_seconds", 2, 60, 1, 5, "Automatic advance interval", "%.0f s") end,
            },
            {
                text_func = function() return self:tr("Language") end,
                sub_item_table = {
                    self:choice("Automatic", "language", "auto"),
                    self:choice("Português", "language", "pt-BR"),
                    self:choice("English", "language", "en"),
                },
            },
            {
                text_func = function() return self:tr("Notifications") end,
                keep_menu_open = true,
                checked_func = function() return self.settings:get("notification") end,
                callback = function() self.settings:toggle("notification") end,
            },
            {
                text_func = function() return self:tr("About") end,
                keep_menu_open = true,
                callback = function() self:showAbout() end,
            },
        },
    }
end

function Menu:choice(label, key, value)
    return {
        text_func = function() return self:tr(label) end,
        checked_func = function() return self.settings:get(key) == value end,
        callback = function() self:setAndRefresh(key, value, label) end,
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
        title_text = self:tr(title),
        ok_text = self:tr("Set"),
        callback = function(new_value)
            self:setAndRefresh(key, new_value.value)
        end,
    })
end

function Menu:cycleSetting(key, values)
    local current = self.settings:get(key)
    for index, value in ipairs(values) do
        if value == current then
            self:setAndRefresh(key, values[index % #values + 1])
            return
        end
    end
    self:setAndRefresh(key, values[1])
end

function Menu:previewChoice(label, key, values, labels)
    return {
        text_func = function()
            local current = self.settings:get(key)
            local current_label = labels[current] or current
            return self:tr(label) .. ": " .. self:tr(current_label)
        end,
        callback = function()
            self:cycleSetting(key, values)
            UIManager:setDirty(self.preview_dialog, "ui")
        end,
    }
end

function Menu:adjustPreviewOpacity(key, delta, dialog)
    local value = math.max(0, math.min(100, (self.settings:get(key) or 0) + delta))
    self:setAndRefresh(key, value)
    UIManager:setDirty(dialog, "ui")
end

function Menu:showPreview()
    local preview = Preview:new{ settings = self.settings }
    local dialog
    dialog = ButtonDialog:new{
        title = self:tr("Configurable line focus preview"),
        title_align = "center",
        width_factor = 0.9,
        _added_widgets = { preview },
        buttons = {
            {
                self:previewChoice("Visual treatment", "visual_pattern", { "underline", "gray_others", "gray_window" }, {
                    underline = "Continuous underline",
                    gray_others = "Gray other lines",
                    gray_window = "Gray focus window",
                }),
            },
            {
                {
                    text_func = function() return self:tr("Underline opacity") .. " -" end,
                    callback = function() self:adjustPreviewOpacity("marker_opacity", -5, dialog) end,
                },
                {
                    text_func = function() return self:tr("Underline opacity") .. " +" end,
                    callback = function() self:adjustPreviewOpacity("marker_opacity", 5, dialog) end,
                },
            },
            {
                {
                    text_func = function() return self:tr("Gray opacity") .. " -" end,
                    callback = function() self:adjustPreviewOpacity("mask_opacity", -5, dialog) end,
                },
                {
                    text_func = function() return self:tr("Gray opacity") .. " +" end,
                    callback = function() self:adjustPreviewOpacity("mask_opacity", 5, dialog) end,
                },
            },
            {
                {
                    text_func = function()
                        local state = self.settings:get("auto_advance") and "On" or "Off"
                        return self:tr("Automatic advance") .. ": " .. self:tr(state)
                    end,
                    callback = function()
                        self:setAndRefresh("auto_advance", not self.settings:get("auto_advance"))
                        UIManager:setDirty(dialog, "ui")
                    end,
                },
                {
                    text_func = function() return self:tr("Close") end,
                    callback = function()
                        self.preview_dialog = nil
                        UIManager:close(dialog)
                    end,
                },
            },
        },
    }
    self.preview_dialog = dialog
    UIManager:show(dialog)
end

function Menu:showAbout()
    local latest = Github:newestRelease()
    local version = table.concat(VERSION, ".")
    local latest_text = latest and " (latest v" .. latest .. ")" or ""
    local settings_file = DataStorage:getSettingsDir() .. "/linefocus_settings.lua"
    UIManager:show(InfoMessage:new{
        text = self:tr("Line Focus for KOReader") .. "\nv" .. version .. latest_text .. [[

]] .. self:tr("Configurable line focus overlay with gray treatments and gesture navigation.") .. [[

]] .. self:tr("Project:") .. [[
github.com/Fiddelis/linefocus.koplugin

]] .. self:tr("Settings:") .. "\n" .. settings_file,
        face = Font:getFace("cfont", 18),
        show_icon = false,
    })
end

return Menu
