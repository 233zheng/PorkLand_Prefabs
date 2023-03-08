local AddAction = AddAction
local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local PL_ACTIONS = {
    BARK = Action({}),
    RANSACK = Action({}),
    CUREPOISON = Action({})
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

ACTIONS.CUREPOISON.fn = function(act)
    if act.invobject and act.invobject.components.poisonhealer then
        local target = act.target or act.doer
        return act.invobject.components.poisonhealer:Cure(target)
    end
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
    poisonhealer = function(inst, doer, target, actions, right)
        if inst:HasTag("poison_antidote") and target and target:HasTag("poisonable") then
            if target:HasTag("poison") or
            (target:HasTag("player") and
            ((target.components.poisonable ~= nil and target.components.poisonable:IsPoisoned()) or
            (target.player_classified and target.player_classified.ispoisoned:value()) or
            inst:HasTag("poison_vaccine"))) then
                table.insert(actions, ACTIONS.CUREPOISON)
            end
        end
    end
    },

    POINT = { -- args: inst, doer, pos, actions, right, target

    },

    EQUIPPED = { -- args: inst, doer, target, actions, right

    },

    INVENTORY = { -- args: inst, doer, actions, right
    poisonhealer = function(inst, doer, actions, right)
        if inst:HasTag("poison_antidote") and doer:HasTag("poisonable") and (doer:HasTag("player") and
        ((doer.components.poisonable ~= nil and doer.components.poisonable:IsPoisoned()) or
        (doer.player_classified and doer.player_classified.ispoisoned:value()) or
        inst:HasTag("poison_vaccine"))) then
            table.insert(actions, ACTIONS.CUREPOISON)
        end
    end
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
