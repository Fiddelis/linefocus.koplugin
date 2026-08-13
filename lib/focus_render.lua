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

function FocusRender.opacityToGray(opacity)
    return 1 - clamp(opacity or 0, 0, 100) / 100
end

-- Grayscale KOReader buffers expose lightenRect without an alpha parameter.
-- Five passes keep the user-facing 0..100 range useful while remaining safe
-- for both grayscale e-ink and color buffers.
function FocusRender.lightenPasses(opacity)
    return math.floor(clamp(opacity or 0, 0, 100) / 20 + 0.5)
end

function FocusRender.gridLines(region, cell_size)
    local size = math.max(2, cell_size or 12)
    local lines = {}
    for x = region.x, region.x + region.w - 1, size do
        table.insert(lines, { x = x, y = region.y, w = 1, h = region.h })
    end
    for y = region.y, region.y + region.h - 1, size do
        table.insert(lines, { x = region.x, y = y, w = region.w, h = 1 })
    end
    return lines
end

return FocusRender
