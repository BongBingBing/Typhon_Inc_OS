-- startup.lua
shell.setPath(shell.path() .. ":/os/apps")
os.loadAPI("/os/lib/ship_control.lua")

print("Aeronautics OS Loaded...")
shell.run("dashboard.lua")