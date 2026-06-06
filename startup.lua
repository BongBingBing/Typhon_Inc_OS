local repo = "BongBingBing/Typhon_Inc_OS"
local branch = "main"
local folderInRepo = ""
local scriptName = shell.getRunningProgram() -- Don't delete the script currently running!

-- GitHub API requires a User-Agent
local headers = { ["User-Agent"] = "CC-Tweaked-Auto-Sync" }

-- Function to wipe the local directory
local function clearLocalFiles()
    print("Performing clean wipe...")
    local files = fs.list("/")
    for _, file in ipairs(files) do
        -- We don't delete the sync script itself or the rom
        if file ~= scriptName and file ~= "rom" then
            fs.delete(file)
        end
    end
end

local function downloadFile(url, localPath)
    local res = http.get(url, headers)
    if res then
        local file = fs.open(localPath, "w")
        file.write(res.readAll())
        file.close()
        res.close()
        return true
    end
    return false
end

local function sync(repoPath)
    local apiUrl = ("https://api.github.com/repos/%s/contents/%s?ref=%s"):format(repo, repoPath, branch)
    local res = http.get(apiUrl, headers)
    
    if not res then
        print("Error: Could not reach GitHub API.")
        return
    end

    local contents = textutils.unserializeJSON(res.readAll())
    res.close()

    for _, item in ipairs(contents) do
        -- Remove the 'CCtweaked/' prefix for local saving
        local localPath = folderInRepo == "" and item.path or item.path:sub(#folderInRepo + 2)
        if localPath == "" then localPath = item.name end

        if item.type == "file" then
            print("Installing: " .. localPath)
            downloadFile(item.download_url, localPath)
        elseif item.type == "dir" then
            if not fs.exists(localPath) then fs.makeDir(localPath) end
            sync(item.path) -- Recursive call for subfolders
        end
    end
end

-- Execution
clearLocalFiles()
print("Starting auto-detection sync...")
sync(folderInRepo)
print("System Updated Successfully!")

package.path = "/os/lib/?.lua;/os/drivers/?.lua;/os/apps/?.lua;/os/?.lua;" .. package.path

local cfg    = dofile("/os/config.lua")
local Logger = require("logger")
local Kernel = require("kernel")

Logger.init("/os/logs/typhon.log")

local role = os.getComputerLabel() or "bridge"
Logger.info("TyphonOS booting — role: " .. role)

-- ── Door controller ───────────────────────────────────────────────────────────
if role == cfg.roles.doors then
    dofile("/os/apps/door_daemon.lua")

-- ── Weapons computer ──────────────────────────────────────────────────────────
elseif role == cfg.roles.weapons then
    local Network = require("network")
    local Radar   = require("radar")
    local Cannon  = require("cannon")
    local Weapons = require("weapons")

    local ok, err = pcall(Network.init, cfg, cfg.network.weapons_channel)
    if not ok then Logger.warn("No modem: " .. tostring(err)) end

    local radar_ok, radar_err = pcall(Radar.init, cfg.radar.side)
    if not radar_ok then
        Logger.warn("Radar not found: " .. tostring(radar_err))
        Radar = nil
    end

    Weapons.init(cfg, Radar, Cannon, Logger, ok and Network or nil)
    if ok then Weapons.registerNetwork(Network) end

    Logger.info("Weapons computer ready")
    Kernel.addTask("network", Network.task())
    Kernel.addTask("radar",   Weapons.radarTask())
    print("TyphonOS Weapons Online")
    Kernel.run()

-- ── Bridge (default) ──────────────────────────────────────────────────────────
else
    local Network   = require("network")
    local Display   = require("display")
    local Helm      = require("helm")
    local Engines   = require("engines")
    local ShipCtrl  = require("ship_control")
    local Altitude  = require("altitude")
    local Autopilot = require("autopilot")
    local Fuel      = require("fuel")
    local Power     = require("power")
    local Dashboard = require("dashboard")

    -- Optional modem (bridge can run standalone without one)
    local net_ok = pcall(Network.init, cfg, cfg.network.bridge_channel)
    if not net_ok then Logger.warn("No modem found — running standalone") end

    Display.init(cfg)

    local helm_ok, helm_err = pcall(Helm.init, cfg.helm.side)
    if not helm_ok then
        Logger.warn("Helm not found on side '" .. cfg.helm.side .. "': " .. tostring(helm_err))
    end

    Engines.init(cfg)
    ShipCtrl.init(cfg, Helm, Engines)
    Altitude.init(cfg, Helm, Engines, ShipCtrl, Logger)
    Autopilot.init(cfg, Helm, ShipCtrl, Logger)
    Fuel.init(cfg, Logger, net_ok and Network or nil)
    Power.init(cfg, Logger, net_ok and Network or nil)
    Dashboard.init(Display, ShipCtrl, Fuel, Power, nil, nil, Logger)

    -- Safety event handler: respond to typhon_emergency events from any subsystem
    local function safetyTask()
        while true do
            local _, system, reason = os.pullEvent("typhon_emergency")
            Logger.error("EMERGENCY from " .. tostring(system) .. ": " .. tostring(reason))
            if reason == "fuel_empty" or reason == "power_critical" then
                ShipCtrl.emergencyLand()
            elseif reason == "emergency_stop" then
                ShipCtrl.allStop()
            end
        end
    end

    Logger.info("Bridge ready")
    if net_ok then Kernel.addTask("network",   Network.task()) end
    Kernel.addTask("fuel",       Fuel.task())
    Kernel.addTask("power",      Power.task())
    Kernel.addTask("altitude",   Altitude.task())
    Kernel.addTask("autopilot",  Autopilot.task())
    Kernel.addTask("dashboard",  Dashboard.task())
    Kernel.addTask("safety",     safetyTask)

    print("TyphonOS Bridge Online")
    Kernel.run()
end
