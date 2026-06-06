-- Weapons system: radar target tracking and cannon fire control

local Weapons = {}
local Radar   = nil
local cannons = {}
local Logger  = nil
local Network = nil
local cfg     = nil

local state = {
    armed    = false,
    mode     = "safe",      -- safe | standby | tracking | firing
    target   = nil,
    contacts = {},
}

function Weapons.init(config, radar_driver, cannon_driver, logger, network)
    cfg     = config
    Radar   = radar_driver
    Logger  = logger
    Network = network

    for _, ccfg in ipairs(cfg.cannons) do
        local ok, c = pcall(cannon_driver.new, ccfg.side, ccfg.name)
        if ok then
            cannons[#cannons + 1] = c
            if Logger then Logger.info("Cannon ready: " .. ccfg.name) end
        else
            if Logger then
                Logger.warn("Cannon init failed (" .. ccfg.name .. "): " .. tostring(c))
            end
        end
    end
end

function Weapons.getState() return state end

function Weapons.arm()
    state.armed = true
    state.mode  = "standby"
    if Logger  then Logger.warn("Weapons ARMED") end
    if Network then Network.broadcast("weapons_status", { armed = true, mode = state.mode }) end
end

function Weapons.safe()
    state.armed  = false
    state.mode   = "safe"
    state.target = nil
    if Logger  then Logger.info("Weapons SAFE") end
    if Network then Network.broadcast("weapons_status", { armed = false, mode = state.mode }) end
end

function Weapons.lockTarget(contact)
    if not state.armed then return false end
    state.target = contact
    state.mode   = "tracking"
    if Logger then
        Logger.info("Target locked: " .. tostring(contact.name or contact.id or "unknown"))
    end
    return true
end

function Weapons.clearTarget()
    state.target = nil
    if state.armed then state.mode = "standby" end
end

-- Simplified ballistic solution (no air resistance).
local function aimAt(origin, target, muzzle_v)
    local dx    = target.x - origin.x
    local dy    = target.y - origin.y
    local dz    = target.z - origin.z
    local horiz = math.sqrt(dx * dx + dz * dz)
    local az    = math.deg(math.atan2(dx, -dz)) % 360

    local v = muzzle_v or 30
    local g = 0.05
    local d = v ^ 4 - g * (g * horiz ^ 2 + 2 * dy * v ^ 2)
    local el = 45
    if d >= 0 then
        el = math.deg(math.atan2(v ^ 2 - math.sqrt(d), g * horiz))
    end
    return az, el
end

function Weapons.fire(origin_pos)
    if not state.armed or not state.target then return false end
    if state.mode ~= "tracking" then return false end

    local orig   = origin_pos or { x = 0, y = 0, z = 0 }
    local az, el = aimAt(orig, state.target, 30)
    local fired  = false

    for _, cannon in ipairs(cannons) do
        if cannon.isReady() then
            cannon.setRotation(az)
            cannon.setElevation(el)
            os.sleep(0.1)
            cannon.fire()
            fired = true
            if Logger then
                Logger.info(string.format("FIRE — %s az=%.1f° el=%.1f°", cannon.name, az, el))
            end
        end
    end
    return fired
end

function Weapons.radarTask()
    return function()
        while true do
            local tid = os.startTimer(cfg.radar.scan_tick)
            local _, id = os.pullEvent("timer")
            if id == tid then
                if Radar then
                    local contacts = Radar.getContactsInRange(cfg.radar.threat_range)
                    state.contacts = contacts
                    if #contacts > 0 and Network then
                        Network.broadcast("radar_contacts",
                            { count = #contacts, contacts = contacts })
                    end
                    if state.mode == "tracking" and #contacts > 0 then
                        state.target = contacts[1]
                    end
                end
            end
        end
    end
end

function Weapons.registerNetwork(net)
    net.subscribe("weapons_arm",  function(_) Weapons.arm()  end)
    net.subscribe("weapons_safe", function(_) Weapons.safe() end)
    net.subscribe("weapons_fire", function(d) Weapons.fire(d and d.origin) end)
    net.subscribe("weapons_lock", function(d) Weapons.lockTarget(d) end)
    net.subscribe("emergency",    function(_) Weapons.safe() end)
end

return Weapons
