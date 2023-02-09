require "brains/snakebrain"
require "stategraphs/SGsnake"

local assets= {
	Asset("ANIM", "anim/snake_water.zip"),
	Asset("ANIM", "anim/snake_scaly_build.zip"),
    Asset("ANIM", "anim/snake_basic.zip"),
}

local prefabs = {
	"monstermeat",
	"snakeskin_scaly",
	"ash",
	"snakeoil",
}

local sounds = {
	amphibious = {
		idle = "dontstarve_DLC002/creatures/snake/idle",
		pre_attack = "dontstarve_DLC002/creatures/snake/pre-attack",
		attack = "dontstarve_DLC002/creatures/snake/attack",
		hurt = "dontstarve_DLC002/creatures/snake/hurt",
		taunt = "dontstarve_DLC002/creatures/snake/taunt",
		death = "dontstarve_DLC002/creatures/snake/death",
		sleep = "dontstarve_DLC002/creatures/snake/sleep",
		move = "dontstarve_DLC002/creatures/snake/move",
	},
}

local SHARE_TARGET_DIST = 30

local function ShouldWakeUp(inst)
    return TheWorld.state.isnight
    or (inst.components.combat and inst.components.combat.target)
    or (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
    or (inst.components.burnable and inst.components.burnable:IsBurning() )
    or (inst.components.follower and inst.components.follower.leader)
  end

  local function ShouldSleep(inst)
    return TheWorld.state.isday
    and not (inst.components.combat and inst.components.combat.target)
    and not (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
    and not (inst.components.burnable and inst.components.burnable:IsBurning() )
    and not (inst.components.follower and inst.components.follower.leader)
  end

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function retargetfn(inst)
	local dist = TUNING.SNAKE_TARGET_DIST
	local notags = {"FX", "NOCLICK","INLIMBO", "wall", "snake", "structure", "aquatic", "snakefriend"}
	return FindEntity(inst, dist, function(guy)
		return  inst.components.combat:CanTarget(guy)
	end, nil, notags)
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (TUNING.SNAKE_KEEP_TARGET_DIST*TUNING.SNAKE_KEEP_TARGET_DIST) and not target:HasTag("aquatic")
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake")and not dude.components.health:IsDead() end, 5)
end

local function OnAttackOther(inst, data)
	inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
end

local function DoReturn(inst)
	if inst.components.homeseeker then
		inst.components.homeseeker:ForceGoHome()
	end
end

local function SanityAura(inst, observer)
    if observer.prefab == "webber" then
        return 0
    end

    return -TUNING.SANITYAURA_SMALL
end

-- 下水时
local function OnEnterWater(inst)
    inst.sg:GoToState("submerge")
    inst.DynamicShadow:Enable(true)
    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.components.locomotor.walkspeed = 4
end

-- 上岸时
local function OnExitWater(inst)
    inst.sg:GoToState("emerge")
    inst.DynamicShadow:Enable(false)
    inst.components.locomotor.walkspeed = 3
end

local function OnEntityWake(inst)
	if inst.components.tiletracker then
		inst.components.tiletracker:Start()
	end
end

local function OnEntitySleep(inst)
	if inst.components.tiletracker then
		inst.components.tiletracker:Stop()
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()

	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("snake")
	inst:AddTag("animal")
	inst:AddTag("amphibious")

	MakeAmphibiousCharacterPhysics(inst, 1, .5)

	inst.AnimState:SetBank("snake")
	inst.AnimState:SetBuild("snake_scaly_build")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = TUNING.SNAKE_SPEED

	inst:AddComponent("knownlocations")

	inst:AddComponent("follower")

	inst:AddComponent("eater")
	inst.components.eater:SetCarnivore()
	inst.components.eater:SetCanEatHorrible()
	inst.components.eater.strongstomach = true -- can eat monster meat!

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.SNAKE_HEALTH)
	inst.components.health.poison_damage_scale = 0 -- immune to poison

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.SNAKE_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.SNAKE_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/snake/hurt")
	inst.components.combat:SetRange(2,3)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddRandomLoot("monstermeat", 1.00)
	inst.components.lootdropper:AddRandomLoot("snakeskin_scaly", 0.50)
	inst.components.lootdropper:AddRandomLoot("snakeoil", 0.01)
	inst.components.lootdropper.numrandomloot = math.random(0,1)

	inst:AddComponent("inspectable")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = SanityAura

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetNocturnal(true)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:AddComponent("embarker")

    -- 添加两栖生物组件
    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetBanks("snake", "snake_water")
    inst.components.amphibiouscreature:SetEnterWaterFn(OnEnterWater)
    inst.components.amphibiouscreature:SetExitWaterFn(OnExitWater)

    -- inst:AddComponent("tiletracker")
	-- inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)

	inst:SetStateGraph("SGsnake")
	local brain = require "brains/snakebrain"
	inst:SetBrain(brain)

	inst.sounds = sounds.amphibious

	inst.OnEntityWake = OnEntityWake
	inst.OnEntitySleep = OnEntitySleep

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)
	inst:ListenForEvent("newcombattarget", OnNewTarget)

    MakeHauntablePanic(inst)
	MakeMediumFreezableCharacter(inst, "hound_body")
	MakeMediumBurnableCharacter(inst, "hound_body")

    return inst
end

return Prefab("snake_amphibious", fn, assets, prefabs)
