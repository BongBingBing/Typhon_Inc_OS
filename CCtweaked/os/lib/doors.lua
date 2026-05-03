-- /os/lib/doors.lua
local doors = {
    -- Format: {name, side, color/id}
    small = {
        {name="Small Dock 1", side="top", color=colors.white},
        {name="Small Dock 2", side="top", color=colors.orange},
        -- ... add all 8 here
    },
    large = {
        {name="Main Port Dock", side="bottom", color=colors.red},
        {name="Main Starboard Dock", side="bottom", color=colors.blue},
    },
    cargo = {name="Cargo Belly", side="back", color=colors.black}
}

function toggleDoor(doorType, index)
    local d = (index) and doors[doorType][index] or doors[doorType]
    local currentState = rs.getBundledOutput(d.side)
    
    if colors.test(currentState, d.color) then
        rs.setBundledOutput(d.side, colors.subtract(currentState, d.color))
        return false -- Closed
    else
        rs.setBundledOutput(d.side, colors.combine(currentState, d.color))
        return true -- Open
    end
end