GLOBAL.setfenv(1, GLOBAL)

local Equippable = require("components/equippable")

function Equippable:IsPoisonBlocker()
    return self.poisonblocker or false
end

function Equippable:IsPoisonGasBlocker()
    return self.poisongasblocker or false
end
