require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/attackwall"
require "behaviours/minperiod"
require "behaviours/faceentity"
require "behaviours/doaction"
require "behaviours/standstill"

local BrainCommon = require "brains/braincommon"

local SnakeBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local SEE_DIST = 30

local function EatFoodAction(inst)
	local notags = {"FX", "NOCLICK", "DECOR","INLIMBO"}
	local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() end, nil, notags)
	if target then
		return BufferedAction(inst, target, ACTIONS.EAT)
	end
end

local function GetHome(inst)
	return inst.components.homeseeker and inst.components.homeseeker.home
end

local function GetHomePos(inst)
	local home = GetHome(inst)
	return home and home:GetPosition()
end

local function GetWanderPoint(inst)
    local player = GetClosestInstWithTag("player", inst, 15)
	local target = GetHome(inst) or player

	if target then
		return target:GetPosition()
	end
end

local function GoHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker.home and
       inst.components.homeseeker.home:IsValid() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

function SnakeBrain:OnStart()

	local root = PriorityNode(
	{
        BrainCommon.PanicTrigger(self.inst),

		WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst) ),

		ChaseAndAttack(self.inst, 8),

		EventNode(self.inst, "gohome",
            DoAction(self.inst, GoHomeAction, "go home", true )),
        WhileNode(function() return TheWorld and TheWorld.state.isday end, "IsDay",
            DoAction(self.inst, GoHomeAction, "go home", true )),

		DoAction(self.inst, EatFoodAction, "eat food", true ),

		WhileNode(function() return GetHome(self.inst) end, "HasHome",
        Wander(self.inst, GetHomePos, 8) ),

        Wander(self.inst, GetWanderPoint, 20),

	}, .25)

	self.bt = BT(self.inst, root)

end

return SnakeBrain
