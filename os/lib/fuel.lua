-- Fuel monitoring and safety system
-- Polls Create fluid tanks; fires typhon_fuel_status on state changes.

local Fuel    = {}
local Logger  = nil
local Network = nil
local cfg     = nil

local state = {
    level    = 1.0,   -- 0.0 – 1.0 fraction of capacity remaining
    amount   = 0,     -- mB currently stored
    capacity = 0,
    status   = "ok",  -- ok | warning | critical | emergency
}

function Fuel.init(config, logger, network)
    cfg     = config
    Logger  = logger
    Network = network
end

function Fuel.getState() return state end

local function readTanks()
    local amount   = 0
    local capacity = cfg.fuel.tank_capacity
    local found    = false

    for _, name in ipairs(cfg.fuel.tanks) do
        local p = nil
        if peripheral.isPresent(name) then
            p = peripheral.wrap(name)
        elseif peripheral.find then
            p = peripheral.find(name)
        end
        if p then
            found = true
            if p.tanks then
                for _, tank in ipairs(p.tanks()) do
                    amount = amount + (tank.amount or 0)
                    if tank.capacity then capacity = tank.capacity end
                end
            elseif p.getFluidAmount then
                amount = amount + p.getFluidAmount()
            elseif p.getStoredFluid then
                local f = p.getStoredFluid()
                amount = amount + (f and f.amount or 0)
            end
        end
    end

    if not found then return 1.0, capacity, capacity end
    if capacity == 0 then return 1.0, 0, 0 end
    return amount / capacity, amount, capacity
end

local function classify(level)
    if level <= cfg.safety.fuel_emergency then return "emergency"
    elseif level <= cfg.safety.fuel_critical then return "critical"
    elseif level <= cfg.safety.fuel_warning  then return "warning"
    else return "ok" end
end

local function logMsg(new_status, level, amount, capacity)
    if not Logger then return end
    local msg = string.format("Fuel %s — %.1f%% (%.0f / %.0f mB)",
        new_status, level * 100, amount, capacity)
    if new_status == "ok"      then Logger.info(msg)
    elseif new_status == "warning" then Logger.warn(msg)
    else Logger.error(msg) end
end

local function update()
    local level, amount, capacity = readTanks()
    state.level    = level
    state.amount   = amount
    state.capacity = capacity

    local new_status = classify(level)
    if new_status ~= state.status then
        state.status = new_status
        logMsg(new_status, level, amount, capacity)
        os.queueEvent("typhon_fuel_status", new_status, level)
        if Network then
            Network.broadcast("fuel_status", { status = new_status, level = level })
        end
    end

    if new_status == "emergency" then
        if Logger then Logger.error("FUEL EMERGENCY — triggering emergency land") end
        os.queueEvent("typhon_emergency", "fuel", "fuel_empty")
    end
end

function Fuel.task()
    return function()
        while true do
            local tid = os.startTimer(5.0)
            local _, id = os.pullEvent("timer")
            if id == tid then update() end
        end
    end
end

return Fuel
