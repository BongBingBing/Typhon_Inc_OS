-- Display abstraction: wraps an Advanced Monitor + terminal fallback

local Display = {}
local mon = nil

function Display.init(config)
    local side = config.display.monitor_side
    if peripheral.isPresent(side) and peripheral.getType(side) == "monitor" then
        mon = peripheral.wrap(side)
        mon.setTextScale(config.display.text_scale or 0.5)
        mon.setBackgroundColor(colors.black)
        mon.clear()
    end
end

function Display.hasMonitor() return mon ~= nil end

function Display.getSize()
    if mon then return mon.getSize() end
    return term.getSize()
end

function Display.clear()
    if mon then mon.clear(); mon.setCursorPos(1, 1) end
end

-- Write text at (x, y) with optional fg/bg colors
function Display.write(x, y, text, fg, bg)
    if not mon then return end
    mon.setCursorPos(x, y)
    if bg then mon.setBackgroundColor(bg) end
    if fg then mon.setTextColor(fg) end
    mon.write(text)
    mon.setTextColor(colors.white)
    mon.setBackgroundColor(colors.black)
end

-- Fill a rectangle with a background color
function Display.rect(x, y, w, h, bg)
    if not mon then return end
    mon.setBackgroundColor(bg or colors.black)
    for row = y, y + h - 1 do
        mon.setCursorPos(x, row)
        mon.write(string.rep(" ", w))
    end
    mon.setBackgroundColor(colors.black)
end

-- Draw a horizontal rule across the full width at row y
function Display.hline(y, bg)
    if not mon then return end
    local w = select(1, mon.getSize())
    Display.rect(1, y, w, 1, bg or colors.gray)
end

return Display
