package.path = "./?.lua;./?/init.lua;" .. package.path

local FocusModel = require("lib/focus_model")

local function line(y, h)
    return { x = 10, y = y, w = 200, h = h or 12 }
end

local function assert_equal(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local model = FocusModel:new()
model:setLines({ line(10), line(30), line(50) }, "next", 1)
assert_equal(model:getFocusedIndex(), 1, "initial focus")
assert_equal(model:move(1), "moved", "next line movement")
assert_equal(model:getFocusedIndex(), 2, "next line index")
assert_equal(model:move(-1), "moved", "previous line movement")
assert_equal(model:getFocusedIndex(), 1, "previous line index")
assert_equal(model:moveToY(58), "moved", "nearest line movement")
assert_equal(model:getFocusedIndex(), 3, "nearest line index")
assert_equal(model:move(1), "next_page", "next page boundary")
assert_equal(model:move(-1), "moved", "movement after boundary keeps focus")
assert_equal(model:getFocusedIndex(), 2, "focus after boundary")

model:setLines({}, "next")
assert_equal(model:getFocusedIndex(), nil, "empty page focus")
assert_equal(model:move(1), "ignored", "empty page movement")

model:setLines({ line(50), line(10), line(30) }, "next", 1)
assert_equal(model:getLines()[1].y, 10, "line boxes sorted by y")
assert_equal(model:getLines()[3].y, 50, "line boxes sorted by y end")

model:setLines({ { x = 10, y = 10, w = 50, h = 12 }, { x = 80, y = 11, w = 40, h = 10 }, line(40, 12) }, "next", 1)
assert_equal(#model:getLines(), 2, "segments on one physical line are merged")
assert_equal(model:getLines()[1].x, 10, "merged line keeps left edge")
assert_equal(model:getLines()[1].w, 110, "merged line covers punctuation and trailing segments")

model:setLines({ { x = 10, y = 10, w = 200, h = 12 }, { x = 500, y = 11, w = 200, h = 10 } }, "next", 1)
assert_equal(#model:getLines(), 2, "separate columns remain separate lines")

print("focus_model_spec: ok")
