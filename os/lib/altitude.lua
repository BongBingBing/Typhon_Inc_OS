-- PID altitude hold controller
-- Fires every cfg.altitude.tick seconds and adjusts lift output.

local Altitude = {}
local Helm     = nil
local Engines  = nil
local Ship     = nil
local Logger   = nil
local cfg      = nil

local pid = { integral = 0, prev_err = 0 }

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function resetPID()
    pid.integral = 0
    pid.prev_err = 0
end

function Altitude.init(config, helm, engines, ship_control, logger)
    cfg     = config
    Helm    = helm
    Engines = engines
    Ship    = ship_control
    Logger  = logger
end

-- Maps a PID output value to a 0-15 redstone level centred on 7 (neutral hover)
local function pidToLift(output)
    return clamp(math.floor(output + 7.5), 0, cfg.altitude.max_thrust)
end

local function tick()
    local mode = Ship.getMode()
    if mode ~= "altitude_hold" and mode ~= "autopilot" and mode ~= "emergency" then
        resetPID()
        return
    end

    local target  = Ship.getState().target_altitude
    if not target then return end

    local current = Helm.getAltitude()
    local err     = target - current
    local dt      = cfg.altitude.tick

    if math.abs(err) <= (cfg.altitude.hold_deadband or 2) then
        -- Inside deadband: keep neutral lift and let the ship drift to hold
        resetPID()
        Engines.setLift(7)
        return
    end

    pid.integral = clamp(pid.integral + err * dt, -60, 60)
    local deriv  = (err - pid.prev_err) / dt
    pid.prev_err = err

    local p, i, d = cfg.altitude.pid.p, cfg.altitude.pid.i, cfg.altitude.pid.d
    local output  = p * err + i * pid.integral + d * deriv
    Engines.setLift(pidToLift(output))

    if Logger and math.abs(err) > 10 then
        Logger.debug(string.format("ALT hold: cur=%.1f tgt=%.1f err=%.1f out=%.2f",
            current, target, err, output))
    end
end

function Altitude.task()
    return function()
        while true do
            local tid = os.startTimer(cfg.altitude.tick)
            local _, id = os.pullEvent("timer")
            if id == tid then tick() end
        end
    end
end

return Altitude
