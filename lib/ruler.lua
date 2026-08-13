local Device = require("device")
local FocusModel = require("lib/focus_model")
local logger = require("logger")

local Ruler = {}

function Ruler:new(args)
    local object = args or {}
    setmetatable(object, self)
    self.__index = self

    object.screen_height = Device.screen:getHeight()
    object.screen_width = Device.screen:getWidth()
    object.cached_texts = nil
    object.cached_texts_page = nil
    object.last_page = nil
    object.tap_to_move = false
    object.line_style = "solid"
    object.model = FocusModel:new()
    return object
end

function Ruler:refreshScreenSize()
    self.screen_height = Device.screen:getHeight()
    self.screen_width = Device.screen:getWidth()
end

function Ruler:setInitialPositionOnPage(new_page)
    local previous_page = self.last_page
    local direction = previous_page and new_page < previous_page and "prev" or "next"
    local is_jump = previous_page and math.abs(new_page - previous_page) > 1
    local texts = self:getTexts(true)
    local lines = texts.sboxes or {}

    local preferred_index
    if #lines > 0 then
        if is_jump or not previous_page then
            preferred_index = 1
        elseif direction == "prev" then
            preferred_index = #lines
        else
            preferred_index = 1
        end
    end

    self.model:setLines(lines, direction, preferred_index)
    self.last_page = new_page
    self:syncCurrentPosition()
end

function Ruler:syncCurrentPosition()
    local line = self.model:getFocusedLine()
    if line then
        self.current_line_x = line.x or 0
        self.current_line_y = line.y + line.h
    else
        self.current_line_x = nil
        self.current_line_y = nil
    end
end

function Ruler:moveToNextLine()
    local result = self.model:move(1)
    self:syncCurrentPosition()
    return result
end

function Ruler:moveToPreviousLine()
    local result = self.model:move(-1)
    self:syncCurrentPosition()
    return result
end

function Ruler:moveToNearestLine(y)
    local result = self.model:moveToY(y)
    self:syncCurrentPosition()
    return result
end

function Ruler:getTexts(ignore_cache)
    local page = self.document:getCurrentPage()
    if not ignore_cache and self.cached_texts and self.cached_texts_page == page then
        return self.cached_texts
    end

    self:refreshScreenSize()
    local texts = self.ui.document:getTextFromPositions(
        { x = 0, y = 0, page = page },
        { x = self.screen_width, y = self.screen_height, page = page },
        true
    )

    self.cached_texts = texts or { sboxes = {} }
    self.cached_texts.sboxes = self.cached_texts.sboxes or {}
    self.cached_texts_page = page
    return self.cached_texts
end

function Ruler:getLines()
    return self.model:getLines()
end

function Ruler:getFocusedLine()
    return self.model:getFocusedLine()
end

function Ruler:getFocusedIndex()
    return self.model:getFocusedIndex()
end

function Ruler:getRulerProperties()
    return {
        thickness = self.settings:get("line_thickness"),
        style = self.line_style,
        opacity = self.settings:getMarkerOpacity(),
    }
end

function Ruler:getRulerGeometry()
    local line = self:getFocusedLine()
    return {
        x = 0,
        y = self.current_line_y or 0,
        w = self.screen_width,
        h = self.settings:get("line_thickness"),
    }
end

function Ruler:isTapToMoveMode()
    return self.tap_to_move
end

function Ruler:enterTapToMoveMode()
    self.tap_to_move = true
    self.line_style = "dashed"
end

function Ruler:exitTapToMoveMode()
    self.tap_to_move = false
    self.line_style = "solid"
end

function Ruler:clearCache()
    self.cached_texts = nil
    self.cached_texts_page = nil
end

function Ruler:logNoLines(page)
    logger.dbg("linefocus: no visible text lines on page", page)
end

return Ruler
