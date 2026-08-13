local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local logger = require("logger")

-- Constants for settings
local SETTINGS_FILE = DataStorage:getSettingsDir() .. "/linefocus_settings.lua"
local DEFAULTS = {
    enabled = false,
    line_thickness = 2,
    marker_opacity = 30,
    mask_opacity = 25,
    navigation_mode = "both", -- tap, swipe, both, none
    tap_navigation = "relative", -- relative, vertical, horizontal, edges, anywhere, none
    visual_pattern = "underline", -- underline, dim_others, spotlight, hatch_others, checker_others
    marker_style = "underline", -- underline, band, both, none
    focus_radius = 1,
    notification = true,
    language = "auto", -- auto, en, pt-BR
    auto_advance = false,
    auto_advance_seconds = 5,
}

---@class Settings
local Settings = {}

--- Creates a new Settings object and loads settings from file.
---@return Settings
function Settings:new()
    ---@class Settings
    local o = {}
    setmetatable(o, self)
    self.__index = self

    -- Load settings from file
    ---@module "luasettings"
    o.settings = LuaSettings:open(SETTINGS_FILE)

    -- Initialize with defaults for any missing settings
    o:init()

    return o
end

--- Load the default settings and overwrite it with value from settings file.
function Settings:init()
    if self:get("marker_opacity") == nil and self:get("line_intensity") ~= nil then
        local legacy_intensity = tonumber(self:get("line_intensity")) or 0.7
        self:set("marker_opacity", (1 - math.max(0, math.min(1, legacy_intensity))) * 100, true)
    end

    -- Initialize with default values if not set
    for key, value in pairs(DEFAULTS) do
        if self:get(key) == nil then
            self:set(key, value, true)
        end
    end

    self.settings:flush()
end

function Settings:getMarkerOpacity()
    return math.max(0, math.min(100, tonumber(self:get("marker_opacity")) or DEFAULTS.marker_opacity))
end

function Settings:getMaskOpacity()
    return math.max(0, math.min(100, tonumber(self:get("mask_opacity")) or DEFAULTS.mask_opacity))
end

--- Get settings from the settings file.
---@param key string The key of the setting to retrieve.
---@return any
function Settings:get(key)
    return self.settings:readSetting(key)
end

--- Set a setting in the settings file, returning true if the value changed.
---@param key string The key of the setting to set.
---@param value any The value to set.
---@param skip_flush? boolean defaults to false. If true, do not flush the settings file.
---@return boolean
function Settings:set(key, value, skip_flush)
    if self:get(key) ~= value then
        self.settings:saveSetting(key, value)

        if not skip_flush then
            self.settings:flush()
        end

        return true
    end

    return false
end

--- Toggle a boolean setting and return the new value.
---@param key string The key of the setting to toggle.
---@return boolean
function Settings:toggle(key)
    local current = self:get(key)
    if type(current) == "boolean" then
        self:set(key, not current)
        return not current
    end
    return current
end

--- Check if the plugin is enabled.
---@return boolean
function Settings:isEnabled()
    return self:get("enabled")
end

--- Enable the plugin and flush.
function Settings:enable()
    self:set("enabled", true)
end

--- Disable the plugin and flush.
function Settings:disable()
    self:set("enabled", false)
end

function Settings:___dump()
    -- logger.info("--- Settings ---")
    -- logger.info(require("ffi/serpent").block(self.settings.data))
end

return Settings
