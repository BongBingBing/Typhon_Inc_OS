-- Simple Engine API
local side = "back" -- Redstone output to a Speed Controller

function setThrust(level)
    -- level 0 to 15 for redstone-based control
    redstone.setAnalogOutput(side, level)
    print("Thrust adjusted to: " .. level)
end

function emergencyStop()
    redstone.setAnalogOutput(side, 0)
    print("EMERGENCY STOP ACTIVATED")
end