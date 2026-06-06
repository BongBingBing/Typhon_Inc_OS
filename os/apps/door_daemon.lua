-- Door Daemon — runs on the dedicated door controller computer.
-- Label that computer "doors" so startup.lua routes here automatically.

package.path = "/os/lib/?.lua;/os/drivers/?.lua;/os/apps/?.lua;/os/?.lua;" .. package.path

local cfg     = dofile("/os/config.lua")
local Logger  = require("logger")
local Network = require("network")
local Doors   = require("doors")
local Kernel  = require("kernel")

Logger.init("/os/logs/door_daemon.log")
Logger.info("Door Daemon starting…")

Network.init(cfg, cfg.network.door_channel)
Doors.init(cfg, Logger)
Doors.registerNetwork(Network)

Logger.info("Door Daemon ready — channel " .. cfg.network.door_channel)

Kernel.addTask("network", Network.task())
Kernel.run()
