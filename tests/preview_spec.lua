package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["ffi/blitbuffer"] = function()
    return {
        gray = function(value)
            return value
        end,
    }
end
package.preload["device"] = function()
    return { screen = { getWidth = function() return 600 end, scaleBySize = function(_, value) return value end } }
end
package.preload["ui/font"] = function()
    return { getFace = function() return {} end }
end
package.preload["ui/geometry"] = function()
    return { new = function(_, value) return value end }
end
package.preload["ui/widget/textwidget"] = function()
    return {}
end
package.preload["ui/widget/widget"] = function()
    return { extend = function() return {} end }
end

local Preview = require("lib/ui/preview")
local marker_thickness = 1
local preview = {
    width = 600,
    line_height = 30,
    settings = {
        getMarkerOpacity = function() return 50 end,
        get = function(_, key)
            return key == "line_thickness" and marker_thickness or nil
        end,
    },
}
local painted = {}
local buffer = {
    paintRect = function(_, _, _, _, height, color)
        table.insert(painted, { height = height, color = color })
    end,
}

for _, thickness in ipairs({ 1, 2, 3, 4 }) do
    marker_thickness = thickness
    Preview.paintMarker(preview, buffer, 0, 0, { { y = 10, h = 20 } }, 1)
end

assert(#painted == 4, "preview should draw one marker per thickness")
for index, marker in ipairs(painted) do
    assert(marker.height == index, string.format(
        "preview thickness %d should draw %d px, got %s",
        index,
        index,
        tostring(marker.height)
    ))
end

print("preview_spec: ok")
