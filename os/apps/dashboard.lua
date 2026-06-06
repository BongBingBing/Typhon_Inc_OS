-- TyphonOS Bridge Dashboard
-- Renders ship status to the Advanced Monitor (and falls back to terminal).

local Dashboard = {}
local D       = nil   -- Display module
local Ship    = nil
local Fuel    = nil
local Power   = nil
local Weapons = nil
local Doors   = nil
local Logger  = nil

function Dashboard.init(display, ship_ctrl, fuel, power, weapons, doors, logger)
    D       = display
    Ship    = ship_ctrl
    Fuel    = fuel
    Power   = power
    Weapons = weapons
    Doors   = doors
    Logger  = logger
end

-- ── helpers ──────────────────────────────────────────────────────────────────

local function pad(s, n)
    s = tostring(s)
    return s .. string.rep(" ", math.max(0, n - #s))
end

local function pct(v)
    return string.format("%5.1f%%", (v or 0) * 100)
end

local STATUS_COLOR = {
    ok        = colors.green,
    warning   = colors.yellow,
    critical  = colors.red,
    emergency = colors.red,
    safe      = colors.gray,
    standby   = colors.yellow,
    tracking  = colors.orange,
    firing    = colors.red,
}

local function sc(s)
    return STATUS_COLOR[s] or colors.white
end

-- ── rendering ─────────────────────────────────────────────────────────────────

local function render()
    if not D.hasMonitor() then return end
    local W, H = D.getSize()
    D.clear()

    -- ── header ──
    D.rect(1, 1, W, 1, colors.gray)
    D.write(1, 1, pad("  TYPHON OS  |  BRIDGE", W), colors.white, colors.gray)

    -- ── navigation (left column) ──
    local pos  = Ship and Ship.getPosition() or { x = 0, y = 0, z = 0 }
    local alt  = Ship and Ship.getAltitude() or 0
    local mode = Ship and Ship.getMode()     or "---"
    local yaw  = Ship and Ship.getYaw()      or 0
    local stt  = Ship and Ship.getState()    or {}

    D.write(1, 3, "NAVIGATION", colors.cyan)
    D.write(1, 4, string.format("  Alt    %d m", math.floor(alt)))
    D.write(1, 5, string.format("  Hdg    %d°", math.floor(yaw)))
    D.write(1, 6, string.format("  Mode   %s", string.upper(mode)))
    if stt.target_altitude then
        D.write(1, 7, string.format("  Tgt    %d m", math.floor(stt.target_altitude)))
    else
        D.write(1, 7, "  Tgt    ---")
    end
    D.write(1, 8, string.format("  Pos    %d, %d, %d",
        math.floor(pos.x or 0), math.floor(pos.y or 0), math.floor(pos.z or 0)))

    -- ── fuel ──
    local fs = Fuel and Fuel.getState() or { level = 0, status = "ok", amount = 0, capacity = 0 }
    D.write(1, 10, "FUEL", colors.cyan)
    D.write(1, 11, "  Level  " .. pct(fs.level),           sc(fs.status))
    D.write(1, 12, "  Status " .. string.upper(fs.status), sc(fs.status))
    D.write(1, 13, string.format("  Store  %.0f / %.0f mB", fs.amount, fs.capacity))

    -- ── power ──
    local ps = Power and Power.getState() or { level = 0, status = "ok" }
    D.write(1, 15, "POWER", colors.cyan)
    D.write(1, 16, "  Level  " .. pct(ps.level),           sc(ps.status))
    D.write(1, 17, "  Status " .. string.upper(ps.status), sc(ps.status))
    if ps.generation and ps.generation > 0 then
        D.write(1, 18, string.format("  Gen    %.0f FE/t", ps.generation))
    end

    -- ── weapons (right column) ──
    local half = math.floor(W / 2) + 2
    local ws   = Weapons and Weapons.getState()
                          or { mode = "safe", armed = false, contacts = {}, target = nil }
    D.write(half, 3, "WEAPONS", colors.cyan)
    D.write(half, 4, "  Armed    " .. (ws.armed and "YES" or "NO"),
            ws.armed and colors.red or colors.gray)
    D.write(half, 5, "  Mode     " .. string.upper(ws.mode), sc(ws.mode))
    D.write(half, 6, "  Contacts " .. tostring(#(ws.contacts or {})))
    local tgt = ws.target
    D.write(half, 7, "  Target   " .. (tgt and tostring(tgt.name or tgt.id or "?") or "none"),
            tgt and colors.red or colors.white)

    -- ── bay doors ──
    D.write(half, 9, "BAY DOORS", colors.cyan)
    if Doors then
        local ds  = Doors.getState()
        local row = 10
        for name, open in pairs(ds) do
            if row > H - 3 then break end
            D.write(half, row,
                string.format("  %-14s %s", name, open and "OPEN" or "SHUT"),
                open and colors.yellow or colors.green)
            row = row + 1
        end
    else
        D.write(half, 10, "  (remote — see door PC)", colors.gray)
    end

    -- ── alert log ──
    D.rect(1, H - 2, W, 1, colors.gray)
    D.write(1, H - 2, pad("  RECENT ALERTS", W), colors.white, colors.gray)
    if Logger then
        local recent = Logger.getRecent(2)
        for k, entry in ipairs(recent) do
            local fc = sc(entry.level == "ERROR" and "critical"
                       or entry.level == "WARN"  and "warning" or "ok")
            D.write(1, H - 2 + k,
                string.sub(string.format("[%s] %s", entry.level, entry.msg), 1, W), fc)
        end
    end
end

function Dashboard.task()
    return function()
        while true do
            local tid = os.startTimer(1.0)
            local _, id = os.pullEvent("timer")
            if id == tid then render() end
        end
    end
end

return Dashboard
