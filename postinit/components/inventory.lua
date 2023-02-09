GLOBAL.setfenv(1, GLOBAL)

local Inventory = require("components/inventory")

function Inventory:IsItemNameEquipped(prefab)
    for k,v in pairs(self.equipslots) do
        if v.prefab == prefab then
            return true
        end
    end

    return false
end

-- Get all of the items in the inventory which meet
-- the criteria specified by the criteria function.
function Inventory:GetItems(criteriaFn)
    local items = {}
    if criteriaFn then
        for k,v in pairs(self.itemslots) do
            if criteriaFn(k, v) then
                table.insert(items, v)
            end
        end
    end

    return items
end
