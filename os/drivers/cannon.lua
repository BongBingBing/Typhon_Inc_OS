-- Create: Big Cannons peripheral driver
-- Cannon.new(side, name) returns a cannon instance.

local Cannon = {}

function Cannon.new(side, name)
    if not peripheral.isPresent(side) then
        error("No cannon peripheral on side '" .. side .. "'")
    end
    local p    = peripheral.wrap(side)
    local self = { side = side, name = name or side, _p = p }

    function self.setElevation(deg)
        if p.setElevation then p.setElevation(deg) return end
        if p.setPitch     then p.setPitch(deg)     return end
    end

    function self.setRotation(deg)
        if p.setRotation then p.setRotation(deg) return end
        if p.setYaw      then p.setYaw(deg)      return end
    end

    function self.fire()
        if p.fire  then p.fire()  return end
        if p.shoot then p.shoot() return end
    end

    function self.getAmmo()
        if p.getAmmo      then return p.getAmmo()      end
        if p.getAmmoCount then return p.getAmmoCount() end
        return -1
    end

    function self.isReady()
        if p.isLoaded then return p.isLoaded() end
        if p.isReady  then return p.isReady()  end
        return true
    end

    function self.raw() return p end

    return self
end

return Cannon
