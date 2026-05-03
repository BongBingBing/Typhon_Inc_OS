-- /os/apps/hangar.lua
os.loadAPI("/os/lib/doors.lua")
local mon = peripheral.find("monitor")

local function drawButton(x, y, label, active)
    mon.setBackgroundColor(active and colors.green or colors.red)
    mon.setCursorPos(x, y)
    mon.write(" " .. label .. " ")
end

function refreshUI()
    mon.clear()
    mon.setBackgroundColor(colors.black)
    mon.setCursorPos(1,1)
    mon.write("--- HANGAR CONTROL SYSTEM ---")
    
    -- Draw 8 Small Docks
    for i=1, 8 do
        drawButton(2, i + 2, "Small Dock " .. i, false)
    end
    
    -- Draw Large Docks
    drawButton(20, 3, "Large Port", false)
    drawButton(20, 5, "Large Starboard", false)
    
    -- Draw Cargo Bay
    drawButton(20, 9, "CARGO BELLY", false)
end

refreshUI()

-- Main Event Loop
while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    -- Logic to check which button was pressed based on X/Y coordinates
    -- For example:
    if x >= 2 and x <= 15 and y >= 3 and y <= 10 then
        local doorID = y - 2
        doors.toggleDoor("small", doorID)
    end
end