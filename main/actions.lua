local AddAction = AddAction
local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local PL_ACTIONS = {
    HACK = Action({mindistance = 1.75, silent_fail = true}),
    SHEAR = Action({distance = 1.75}),
    PEAGAWK_TRANSFORM = Action({}),
    BARK = Action({}),
    RANSACK = Action({}),
}

for name, ACTION in pairs(PL_ACTIONS) do
    ACTION.id = name
    ACTION.str = STRINGS.ACTIONS[name] or "PL_ACTION"
    AddAction(ACTION)
end







ACTIONS.BARK.fn = function(act)
    return true
end

ACTIONS.RANSACK.fn = function(act)
    return true
end




-- SCENE		using an object in the world
-- USEITEM		using an inventory item on an object in the world
-- POINT		using an inventory item on a point in the world
-- EQUIPPED		using an equiped item on yourself or a target object in the world
-- INVENTORY	using an inventory item
local PL_COMPONENT_ACTIONS =
{
    SCENE = { -- args: inst, doer, actions, right

    },

    USEITEM = { -- args: inst, doer, target, actions, right
    },

    POINT = { -- args: inst, doer, pos, actions, right, target

    },

    EQUIPPED = { -- args: inst, doer, target, actions, right

    },

    INVENTORY = { -- args: inst, doer, actions, right


    },
    ISVALID = { -- args: inst, action, right
    },
}

for actiontype, actons in pairs(PL_COMPONENT_ACTIONS) do
    for component, fn in pairs(actons) do
        AddComponentAction(actiontype, component, fn)
    end
end

-- hack
local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local SCENE = COMPONENT_ACTIONS.SCENE
local USEITEM = COMPONENT_ACTIONS.USEITEM
local POINT = COMPONENT_ACTIONS.POINT
local EQUIPPED = COMPONENT_ACTIONS.EQUIPPED
local INVENTORY = COMPONENT_ACTIONS.INVENTORY
