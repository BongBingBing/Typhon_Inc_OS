-- Engine control: analog redstone output for thrust and lift

local Engines = {}
local cfg     = nil

function Engines.init(config)
    cfg = config
end

local function clamp15(v)
    return math.max(0, math.min(15, math.floor(v + 0.5)))
end

-- Forward thrust: 0–15 redstone level
function Engines.setThrust(level)
    redstone.setAnalogOutput(cfg.engines.thrust_side, clamp15(level))
end

-- Vertical lift: 0–15 (7 = neutral hover, >7 = rise, <7 = sink)
function Engines.setLift(level)
    if cfg.engines.lift_side then
        redstone.setAnalogOutput(cfg.engines.lift_side, clamp15(level))
    end
end

function Engines.getThrust()
    return redstone.getAnalogOutput(cfg.engines.thrust_side)
end

function Engines.getLift()
    if cfg.engines.lift_side then
        return redstone.getAnalogOutput(cfg.engines.lift_side)
    end
    return 0
end

function Engines.emergencyStop()
    redstone.setAnalogOutput(cfg.engines.thrust_side, 0)
    if cfg.engines.lift_side then
        redstone.setAnalogOutput(cfg.engines.lift_side, 0)
    end
    os.queueEvent("typhon_emergency", "engines", "emergency_stop")
end

return Engines
