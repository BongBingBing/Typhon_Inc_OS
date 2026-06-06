-- Autopilot: heading hold and single-waypoint navigation
-- Works alongside altitude.lua which handles the vertical axis.

local Autopilot = {}
local Helm   = nil
local Ship   = nil
local Logger = nil

function Autopilot.init(config, helm, ship_control, logger)
    Helm   = helm
    Ship   = ship_control
    Logger = logger
end

-- Compass bearing (0-360) from world position cur to target {x, z}
local function bearingTo(cur, target)
    local dx = target.x - cur.x
    local dz = target.z - cur.z
    -- In Minecraft: south = +Z, east = +X, north = -Z.
    -- atan2(dx, -dz) gives angle from north (south-facing = 0 is avoided).
    return math.deg(math.atan2(dx, -dz)) % 360
end

-- Signed angular difference in [-180, 180]
local function angleDiff(target, current)
    return (target - current + 540) % 360 - 180
end

function Autopilot.setWaypoint(x, y, z)
    Ship.getState().target_pos = { x = x, y = y, z = z }
    Ship.setTargetAltitude(y)
    Ship.setMode("autopilot")
    if Logger then Logger.info(string.format("Autopilot: waypoint set (%d, %d, %d)", x, y, z)) end
end

function Autopilot.clearWaypoint()
    Ship.getState().target_pos = nil
    Ship.setMode("altitude_hold")
end

local function tick()
    if Ship.getMode() ~= "autopilot" then return end
    local target = Ship.getState().target_pos
    if not target then return end

    local pos     = Helm.getPosition()
    local bearing = bearingTo(pos, target)
    local diff    = angleDiff(bearing, Helm.getYaw())

    -- Proportional yaw correction, clamped to ±1
    Helm.setYawInput(math.max(-1, math.min(1, diff / 90)))

    -- Check horizontal arrival (within 10 blocks)
    local dx   = target.x - pos.x
    local dz   = target.z - pos.z
    local dist = math.sqrt(dx * dx + dz * dz)
    if dist < 10 then
        if Logger then Logger.info("Autopilot: waypoint reached") end
        Autopilot.clearWaypoint()
        Helm.setThrust(0)
        Helm.setYawInput(0)
        os.queueEvent("typhon_waypoint_reached", target)
    end
end

function Autopilot.task()
    return function()
        while true do
            local tid = os.startTimer(1.0)
            local _, id = os.pullEvent("timer")
            if id == tid then tick() end
        end
    end
end

return Autopilot
