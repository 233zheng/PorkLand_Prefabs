GLOBAL.setfenv(1, GLOBAL)

local PlantRegrowth = require("components/plantregrowth")

local time_multipliers = {
    teatree = function()
        return TUNING.TEATREE_REGROWTH_TIME_MULT * ((TheWorld.state.iswinter and 0) or 1)
    end,
    tubertree = function()
        return TUNING.TUBERTREE_REGROWTH_TIME_MULT * ((TheWorld.state.iswinter and 0) or 1)
    end,
    rainforesttree = function()
        return TUNING.RAINFORESTTREE_REGROWTH_TIME_MULT * ((TheWorld.state.iswinter and 0) or 1)
    end,
}

for k, v in pairs(time_multipliers) do
    PlantRegrowth.TimeMultipliers[k] = v
end
