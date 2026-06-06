-- Create: Radar peripheral driver
-- Wraps the radar and normalises the contact list format.

local Radar = {}
local r = nil

function Radar.init(side)
    if not peripheral.isPresent(side) then
        error("No radar peripheral on side '" .. side .. "'")
    end
    r = peripheral.wrap(side)
    return r
end

-- Returns a list of contacts: each entry has at least {x, y, z, distance}
function Radar.getContacts()
    if not r then return {} end
    local raw
    if r.getTargets  then raw = r.getTargets()  end
    if not raw and r.scan       then raw = r.scan()       end
    if not raw and r.getEntities then raw = r.getEntities() end
    if not raw then return {} end

    -- Normalise: ensure every contact has a .distance field
    for _, c in ipairs(raw) do
        if not c.distance then
            c.distance = math.sqrt((c.x or 0)^2 + (c.y or 0)^2 + (c.z or 0)^2)
        end
    end
    return raw
end

-- Returns contacts within `range` blocks, sorted nearest first
function Radar.getContactsInRange(range)
    local all      = Radar.getContacts()
    local filtered = {}
    for _, c in ipairs(all) do
        if c.distance <= range then
            filtered[#filtered + 1] = c
        end
    end
    table.sort(filtered, function(a, b) return a.distance < b.distance end)
    return filtered
end

function Radar.raw() return r end

return Radar
