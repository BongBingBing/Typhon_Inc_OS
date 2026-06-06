-- TyphonOS Configuration
-- Edit these values to match your ship's hardware setup

return {
    roles = {
        bridge  = "bridge",
        doors   = "doors",
        weapons = "weapons",
    },

    network = {
        modem_side        = "top",
        bridge_channel    = 1,
        door_channel      = 10,
        weapons_channel   = 20,
        emergency_channel = 100,
        broadcast_channel = 200,
    },

    helm = {
        side = "front",  -- side the helm peripheral is attached to
    },

    engines = {
        thrust_side = "back",    -- analog redstone out → forward thrust
        lift_side   = "bottom",  -- analog redstone out → vertical lift
    },

    altitude = {
        pid       = { p = 0.8, i = 0.02, d = 0.3 },
        tick      = 0.5,   -- PID update interval in seconds
        max_thrust = 15,
        hold_deadband = 2, -- ±2 blocks tolerance before PID engages
    },

    safety = {
        max_altitude       = 280,
        min_altitude       = 64,
        emergency_land_alt = 70,
        max_speed          = 12,
        fuel_warning       = 0.25,
        fuel_critical      = 0.10,
        fuel_emergency     = 0.05,
        power_warning      = 0.25,
        power_critical     = 0.10,
    },

    fuel = {
        -- Peripheral names/sides of Create fluid tanks.
        -- Use peripheral.getNames() in the CC terminal to find the exact names.
        tanks = {
            "ironTank_valve_0",
        },
        tank_capacity = 16000, -- total capacity in mB
    },

    power = {
        -- Peripheral names of energy monitors (Create stressometers, energy cells, etc.)
        monitors = {
            "electricMotor_0",
        },
    },

    -- Door controller computer: bundled cable wiring
    doors = {
        cable_side = "bottom", -- side the bundled cable connects to
        -- Map friendly door name → bundled cable color constant
        map = {
            port_bay       = colors.red,
            starboard_bay  = colors.green,
            forward_bay    = colors.blue,
            aft_bay        = colors.yellow,
            hangar_upper   = colors.orange,
            hangar_lower   = colors.purple,
        },
    },

    radar = {
        side         = "left",  -- side radar peripheral attaches to
        threat_range = 200,     -- blocks — contacts inside this are flagged
        scan_tick    = 1.0,     -- scan interval in seconds
    },

    -- List each cannon: side/name the peripheral is on
    cannons = {
        { side = "right", name = "port_cannon" },
        -- add more: { side = "left", name = "starboard_cannon" },
    },

    display = {
        monitor_side = "right",
        text_scale   = 0.5,
    },
}
