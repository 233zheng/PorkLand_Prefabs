local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Spawner = require("components/spawner")

function Spawner:SetOnSpawnedFn(fn)
    self.onspawned = fn
end

local _ReleaseChild = Spawner.ReleaseChild
function Spawner:ReleaseChild(...)
    if self:IsOccupied() then
        if self.onspawned then
            assert(self.child)
                self.onspawned(self.inst, self.child)
            end
        end
    return _ReleaseChild(self, ...)
end

local function postinit(self)
    self.onspawned = nil
end

AddComponentPostInit("spawner", postinit)
