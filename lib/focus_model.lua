local FocusModel = {}

local function merge_line(target, source)
    local left = math.min(target.x or 0, source.x or 0)
    local top = math.min(target.y, source.y)
    local right = math.max((target.x or 0) + (target.w or 0), (source.x or 0) + (source.w or 0))
    local bottom = math.max(target.y + target.h, source.y + source.h)
    target.x = left
    target.y = top
    target.w = right - left
    target.h = bottom - top
end

local function belongs_to_same_line(previous, current)
    local previous_middle = previous.y + previous.h / 2
    local current_middle = current.y + current.h / 2
    local tolerance = math.max(previous.h, current.h) * 0.6
    local previous_right = (previous.x or 0) + (previous.w or 0)
    local horizontal_gap = (current.x or 0) - previous_right
    local max_gap = math.max(previous.h, current.h) * 6
    return math.abs(previous_middle - current_middle) <= tolerance and horizontal_gap <= max_gap
end

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

    local merged = {}
    for _, line in ipairs(result) do
        local previous = merged[#merged]
        if previous and belongs_to_same_line(previous, line) then
            merge_line(previous, line)
        else
            table.insert(merged, {
                x = line.x or 0,
                y = line.y,
                w = line.w or 0,
                h = line.h,
            })
        end
    end
    return merged
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
