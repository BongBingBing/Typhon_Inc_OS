-- Power monitoring and safety system
-- Polls Create energy monitors; fires typhon_power_status on state changes.

local Power   = {}
local Logger  = nil
local Network = nil
local cfg     = nil

local state = {
    level      = 1.0,
    stored     = 0,
    capacity   = 0,
    generation = 0,
    status     = "ok",   -- ok | warning | critical
}

function Power.init(config, logger, network)
    cfg     = config
    Logger  = logger
    Network = network
end

function Power.getState() return state end

local function readMonitors()
    local stored   = 0
    local capacity = 0
    local gen      = 0
    local found    = false

    for _, name in ipairs(cfg.power.monitors) do
        if peripheral.isPresent(name) then
            local p = peripheral.wrap(name)
            found = true
            if p.getEnergyStored and p.getMaxEnergyStored then
                stored   = stored   + p.getEnergyStored()
                capacity = capacity + p.getMaxEnergyStored()
            elseif p.getEnergy and p.getCapacity then
                stored   = stored   + p.getEnergy()
                capacity = capacity + p.getCapacity()
            end
            if p.getGenerating then gen = gen + p.getGenerating() end
        end
    end

    if not found or capacity == 0 then return 1.0, 0, 0, 0 end
    return stored / capacity, stored, capacity, gen
end

local function classify(level)
    if level <= cfg.safety.power_critical then return "critical"
    elseif level <= cfg.safety.power_warning then return "warning"
    else return "ok" end
end

local function update()
    local level, stored, capacity, gen = readMonitors()
    state.level      = level
    state.stored     = stored
    state.capacity   = capacity
    state.generation = gen

    local new_status = classify(level)
    if new_status ~= state.status then
        state.status = new_status
        local msg = string.format("Power %s — %.1f%%", new_status, level * 100)
        if Logger then
            if new_status == "ok"      then Logger.info(msg)
            elseif new_status == "warning" then Logger.warn(msg)
            else Logger.error(msg) end
        end
        os.queueEvent("typhon_power_status", new_status, level)
        if Network then
            Network.broadcast("power_status", { status = new_status, level = level })
        end
    end

    if new_status == "critical" then
        if Logger then Logger.error("POWER CRITICAL — shedding non-essential loads") end
        os.queueEvent("typhon_emergency", "power", "power_critical")
    end
end

function Power.task()
    return function()
        while true do
            local tid = os.startTimer(3.0)
            local _, id = os.pullEvent("timer")
            if id == tid then update() end
        end
    end
end

return Power
