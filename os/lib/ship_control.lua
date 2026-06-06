-- High-level ship control: mode management and safe wrappers around the helm

local ShipControl = {}
local Helm    = nil
local Engines = nil
local cfg     = nil

local state = {
    mode           = "manual",  -- manual | altitude_hold | autopilot | emergency
    target_altitude= nil,
    target_heading = nil,
    target_pos     = nil,       -- {x, y, z} for autopilot waypoint
}

function ShipControl.init(config, helm, engines)
    cfg     = config
    Helm    = helm
    Engines = engines
end

function ShipControl.getState()  return state end
function ShipControl.getMode()   return state.mode end

function ShipControl.setMode(mode)
    state.mode = mode
    os.queueEvent("typhon_mode_change", mode)
end

function ShipControl.getPosition() return Helm.getPosition() end
function ShipControl.getAltitude() return Helm.getAltitude() end
function ShipControl.getVelocity() return Helm.getVelocity() end
function ShipControl.getYaw()      return Helm.getYaw()      end

-- Clamps to configured altitude limits before accepting the target
function ShipControl.setTargetAltitude(y)
    state.target_altitude = math.max(
        cfg.safety.min_altitude,
        math.min(cfg.safety.max_altitude, y)
    )
    if state.mode ~= "autopilot" then
        ShipControl.setMode("altitude_hold")
    end
end

function ShipControl.setTargetHeading(deg)
    state.target_heading = deg % 360
end

function ShipControl.emergencyLand()
    state.target_altitude = cfg.safety.emergency_land_alt
    ShipControl.setMode("emergency")
    os.queueEvent("typhon_emergency", "ship", "emergency_land")
end

function ShipControl.allStop()
    Helm.stop()
    Engines.emergencyStop()
    ShipControl.setMode("manual")
end

return ShipControl
