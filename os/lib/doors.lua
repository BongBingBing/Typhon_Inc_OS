-- Bay door controller
-- Runs on the dedicated door computer; drives bundled redstone cable.
-- Each door maps to one color in the bundled cable bitmask.

local Doors  = {}
local Logger = nil
local cfg    = nil

local door_state = {}   -- door_name -> boolean (true = open)

function Doors.init(config, logger)
    cfg    = config
    Logger = logger
    for name in pairs(cfg.doors.map) do
        door_state[name] = false
    end
    Doors._apply()
end

function Doors.getState() return door_state end

-- Rebuild and push the full bitmask to the bundled cable
function Doors._apply()
    local mask = 0
    for name, color in pairs(cfg.doors.map) do
        if door_state[name] then
            mask = colors.combine(mask, color)
        end
    end
    rs.setBundledOutput(cfg.doors.cable_side, mask)
end

local function set(name, open)
    if not cfg.doors.map[name] then
        if Logger then Logger.warn("Unknown door: " .. tostring(name)) end
        return false
    end
    door_state[name] = open
    Doors._apply()
    if Logger then
        Logger.info("Door " .. name .. ": " .. (open and "OPEN" or "CLOSED"))
    end
    os.queueEvent("typhon_door_change", name, open and "open" or "close")
    return true
end

function Doors.open(name)   return set(name, true)  end
function Doors.close(name)  return set(name, false) end
function Doors.toggle(name) return set(name, not door_state[name]) end

function Doors.openAll()
    for name in pairs(cfg.doors.map) do door_state[name] = true end
    Doors._apply()
    if Logger then Logger.info("All doors OPEN") end
end

function Doors.closeAll()
    for name in pairs(cfg.doors.map) do door_state[name] = false end
    Doors._apply()
    if Logger then Logger.info("All doors CLOSED") end
end

-- Wire up network command subscriptions (call after Network.init)
function Doors.registerNetwork(Network)
    Network.subscribe("door_open",   function(d) Doors.open(d.door)   end)
    Network.subscribe("door_close",  function(d) Doors.close(d.door)  end)
    Network.subscribe("door_toggle", function(d) Doors.toggle(d.door) end)
    Network.subscribe("door_all",    function(d)
        if d.state == "open" then Doors.openAll() else Doors.closeAll() end
    end)
    Network.subscribe("emergency",   function(_) Doors.closeAll() end)
end

return Doors
