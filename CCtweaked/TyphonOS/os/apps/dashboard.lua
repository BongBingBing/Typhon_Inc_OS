package.path = package.path .. ";/?.lua;/?.bit"

local basalt = require("basalt")

-- Create the main project
local main = basalt.createFrame()

-- 1. TOP BAR (Title and Status)
local topBar = main:addFrame()
    :setSize("parent.w", 1)
    :setBackground(colors.blue)

topBar:addLabel()
    :setText(" AERONAUTICS SHIP OS v1.0")
    :setForeground(colors.white)
    :setPosition(2, 1)

-- 2. SIDEBAR (Navigation)
local sidebar = main:addFrame()
    :setPosition(1, 2)
    :setSize(12, function() return main:getHeight() - 1 end) -- Use a function for dynamic sizing
    :setBackground(colors.gray)

-- 3. CONTENT AREA (Where the magic happens)
local content = main:addFrame()
    :setPosition(13, 2)
    :setSize(function() return main:getWidth() - 12 end, function() return main:getHeight() - 1 end)
    :setBackground(colors.black)

-- Function to clear content and show new screen
local function openTab(name)
    content:clear()
    content:addLabel()
        :setText(name:upper())
        :setPosition(2, 2)
        :setForeground(colors.yellow)
    return content
end

sidebar:addButton()
    :setPosition(2, 2)
    :setSize(10, 3)
    :setText("THRUSTERS")
    :onClick(function()
        local tab = openTab("Thruster Control")
        
        tab:addLabel():setText("Main Throttle"):setPosition(2, 4)
        local throttle = tab:addSlider()
            :setPosition(2, 5)
            :setSize(15, 1)
            :setMax(100)
            :onChange(function(self)
                -- Link to your ship_control API here
                -- ship_control.setThrust(self:getValue())
            end)
    end)

sidebar:addButton()
    :setPosition(2, 6)
    :setSize(10, 3)
    :setText("DOCK DOORS")
    :onClick(function()
        local tab = openTab("Hangar Bay Management")
        
        -- Example for Small Dock 1
        for i = 1, 8 do
            tab:addCheckbox()
                :setPosition(2, 3 + i)
                :setLabel("Small Dock " .. i)
                :onChange(function(self, checked)
                    -- doors.toggleDoor("small", i, checked)
                end)
        end
    end)

sidebar:addButton()
    :setPosition(2, 10)
    :setSize(10, 3)
    :setText("SYSTEMS")
    :onClick(function()
        local tab = openTab("Power & Bulkheads")
        
        tab:addLabel():setText("Reactor Output"):setPosition(2, 4)
        tab:addProgressBar()
            :setPosition(2, 5)
            :setSize(15, 1)
            :setDirection(0) -- Horizontal
            :setProgress(75) -- Replace with actual power data
            
        tab:addButton()
            :setPosition(2, 8)
            :setSize(15, 3)
            :setText("SEAL ALL BULKHEADS")
            :setBackground(colors.red)
    end)


-- Start the UI
basalt.update()