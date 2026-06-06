-- Create Aeronautics Helm peripheral driver
-- Wraps the helm with a stable interface. If method names differ in your
-- version of Create Aeronautics, adjust only this file.
--
-- To find your peripheral name in-game:
--   for _, name in pairs(peripheral.getNames()) do print(name) end

local Helm = {}
local h    = nil   -- raw peripheral

function Helm.init(side)
    if not peripheral.isPresent(side) then
        error("No peripheral on side '" .. side .. "' for helm")
    end
    h = peripheral.wrap(side)
    return h
end

-- {x, y, z} world position of the ship assembly
function Helm.getPosition()
    if h.getPos      then return h.getPos()      end
    if h.getPosition then return h.getPosition() end
    return { x = 0, y = 0, z = 0 }
end

function Helm.getAltitude()
    local p = Helm.getPosition()
    return p.y or p[2] or 0
end

-- {x, y, z} velocity (blocks/tick or blocks/s depending on CA version)
function Helm.getVelocity()
    if h.getVelocity then return h.getVelocity() end
    if h.getSpeed    then return h.getSpeed()    end
    return { x = 0, y = 0, z = 0 }
end

-- Compass heading in degrees (0-360, 0 = south in Minecraft)
function Helm.getYaw()
    if h.getYaw   then return h.getYaw()   end
    if h.getAngle then return h.getAngle() end
    return 0
end

function Helm.getPitch()
    if h.getPitch then return h.getPitch() end
    return 0
end

-- Vertical lift input: -1.0 (full down) to 1.0 (full up)
function Helm.setLift(value)
    if h.setLift           then h.setLift(value)           return end
    if h.setVerticalThrust then h.setVerticalThrust(value) return end
end

-- Forward thrust input: -1.0 to 1.0
function Helm.setThrust(value)
    if h.setThrust        then h.setThrust(value)        return end
    if h.setForwardThrust then h.setForwardThrust(value) return end
end

-- Yaw rotation rate: -1.0 (turn left) to 1.0 (turn right)
function Helm.setYawInput(value)
    if h.setYaw      then h.setYaw(value)      return end
    if h.setRotation then h.setRotation(value) return end
end

function Helm.stop()
    Helm.setThrust(0)
    Helm.setLift(0)
    Helm.setYawInput(0)
end

-- Raw peripheral access for operations not covered above
function Helm.raw() return h end

return Helm
