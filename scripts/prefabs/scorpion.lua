require "brains/spiderbrain"
require "stategraphs/SGscorpion"

local assets = {
	Asset("ANIM", "anim/scorpion_basic.zip"),
	Asset("ANIM", "anim/scorpion_build.zip"),
	Asset("SOUND", "sound/spider.fsb"),
}

local prefabs = {
	"chitin",
    "monstermeat",
    "venomgland",
    "stinger",
}

SetSharedLootTable( 'scorpion',
{
    {'monstermeat',  1.00},
    {'chitin',  0.3},
    {'venomgland',  0.3},
    {'stinger',  0.3},
})

local SHARE_TARGET_DIST = 30

local function NormalRetarget(inst)
    local targetDist = TUNING.SCORPION_TARGET_DIST
    if inst.components.knownlocations:GetLocation("investigate") then
        targetDist = TUNING.SCORPION_INVESTIGATETARGET_DIST
    end
    return FindEntity(inst, targetDist,
        function(guy)
            if inst.components.combat:CanTarget(guy) then
                return guy:HasTag("player") or guy:HasTag("pig")
            end
    end)
end

local function keeptargetfn(inst, target)
   return target
          and target.components.combat ~= nil
          and target.components.health ~= nil
          and not target.components.health:IsDead()
          and not (inst.components.follower ~= nil and inst.components.follower.leader == target)
end

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude)
        return dude:HasTag("scorpion") and not dude.components.health:IsDead()
    end, 5)
end

local function create_scorpion()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize( 1.5, .5 )
    inst.Transform:SetFourFaced()

    inst:AddTag("monster")
    inst:AddTag("animal")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("scorpion")
    inst:AddTag("canbetrapped")

    MakeCharacterPhysics(inst, 10, .5)
    MakePoisonableCharacter(inst)

    inst.AnimState:SetBank("scorpion")
    inst.AnimState:SetBuild("scorpion_build")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.SCORPION_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SCORPION_RUN_SPEED

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('scorpion')

    inst:AddComponent("follower")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SCORPION_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "scorpion_body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetDefaultDamage(TUNING.SCORPION_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SCORPION_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)
    inst.components.combat:SetHurtSound("dontstarve/creatures/spider/hit_response")
    inst.components.combat:SetRange(TUNING.SCORPION_ATTACK_RANGE, TUNING.SCORPION_ATTACK_RANGE)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    inst:AddComponent("knownlocations")

    inst:AddComponent("eater")
    inst.components.eater:SetCarnivore()
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true

    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:SetStateGraph("SGscorpion")
    local brain = require "brains/spiderbrain"
    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)

    MakeHauntablePanic(inst)
    MakeMediumBurnableCharacter(inst, "scorpion_body")
    MakeMediumFreezableCharacter(inst, "scorpion_body")
    inst.components.burnable.flammability = TUNING.SCORPION_FLAMMABILITY

    return inst
end

return Prefab("scorpion", create_scorpion, assets, prefabs)
