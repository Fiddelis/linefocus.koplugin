local FocusModel = {}

local function copy_lines(lines)
    local result = {}
    for _, line in ipairs(lines or {}) do
        if line and line.y and line.h and line.h > 0 then
            table.insert(result, line)
        end
    end

    table.sort(result, function(a, b)
        if a.y == b.y then
            return (a.x or 0) < (b.x or 0)
        end
        return a.y < b.y
    end)
    return result
end

function FocusModel:new()
    local object = {
        lines = {},
        focused_index = nil,
    }
    setmetatable(object, self)
    self.__index = self
    return object
end

function FocusModel:setLines(lines, direction, preferred_index)
    self.lines = copy_lines(lines)
    if #self.lines == 0 then
        self.focused_index = nil
    elseif preferred_index then
        self.focused_index = math.max(1, math.min(preferred_index, #self.lines))
    elseif direction == "prev" then
        self.focused_index = #self.lines
    else
        self.focused_index = 1
    end
end

function FocusModel:getLines()
    return self.lines
end

function FocusModel:getFocusedIndex()
    return self.focused_index
end

function FocusModel:getFocusedLine()
    return self.focused_index and self.lines[self.focused_index] or nil
end

function FocusModel:move(delta)
    if not self.focused_index or #self.lines == 0 or delta == 0 then
        return "ignored"
    end

    local next_index = self.focused_index + delta
    if next_index < 1 then
        return "previous_page"
    elseif next_index > #self.lines then
        return "next_page"
    end

    self.focused_index = next_index
    return "moved"
end

function FocusModel:moveToY(y)
    if not y or #self.lines == 0 then
        return "ignored"
    end

    local closest_index, closest_distance
    for index, line in ipairs(self.lines) do
        local distance = math.abs((line.y + line.h) - y)
        if not closest_distance or distance < closest_distance then
            closest_index = index
            closest_distance = distance
        end
    end

    self.focused_index = closest_index
    return "moved"
end

return FocusModel
