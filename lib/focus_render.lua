local FocusRender = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function FocusRender.markerRect(line, screen_width, thickness)
    local marker_height = clamp(thickness or 1, 1, math.max(1, line.h))
    return {
        x = 0,
        y = line.y + line.h - marker_height,
        w = screen_width,
        h = marker_height,
    }
end

function FocusRender.focusWindow(lines, focus_index, radius)
    if not focus_index or not lines[focus_index] then
        return nil
    end

    local first = math.max(1, focus_index - (radius or 0))
    local last = math.min(#lines, focus_index + (radius or 0))
    return {
        top = lines[first].y,
        bottom = lines[last].y + lines[last].h,
    }
end

function FocusRender.maskBands(lines, focus_index, radius, screen_width, screen_height)
    local window = FocusRender.focusWindow(lines, focus_index, radius)
    if not window then
        return { { x = 0, y = 0, w = screen_width, h = screen_height } }
    end

    local top = clamp(window.top, 0, screen_height)
    local bottom = clamp(window.bottom, top, screen_height)
    local bands = {}
    if top > 0 then
        table.insert(bands, { x = 0, y = 0, w = screen_width, h = top })
    end
    if bottom < screen_height then
        table.insert(bands, { x = 0, y = bottom, w = screen_width, h = screen_height - bottom })
    end
    return bands
end

function FocusRender.focusRegion(lines, focus_index, radius, screen_width, screen_height)
    local window = FocusRender.focusWindow(lines, focus_index, radius)
    if not window then
        return nil
    end
    local top = clamp(window.top, 0, screen_height)
    local bottom = clamp(window.bottom, top, screen_height)
    return { x = 0, y = top, w = screen_width, h = bottom - top }
end

function FocusRender.transitionRegion(old_region, new_region, screen_width, screen_height)
    if not old_region or not new_region then
        return { x = 0, y = 0, w = screen_width, h = screen_height }
    end
    local top = math.min(old_region.y, new_region.y)
    local bottom = math.max(old_region.y + old_region.h, new_region.y + new_region.h)
    return { x = 0, y = top, w = screen_width, h = bottom - top }
end

function FocusRender.opacityToGray(opacity)
    return clamp(opacity or 0, 0, 100) / 100
end

function FocusRender.opacityFactor(opacity)
    return clamp(opacity or 0, 0, 100) / 100
end

function FocusRender.maskPlan(pattern, opacity)
    if pattern == "gray_others" or pattern == "gray_window" then
        return { operation = "darkenRect", factor = FocusRender.opacityFactor(opacity) }
    end
    return { operation = "none", factor = 0 }
end

return FocusRender
