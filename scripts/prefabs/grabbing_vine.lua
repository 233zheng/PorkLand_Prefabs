require "brains/grabbing_vinebrain"
require "stategraphs/SGgrabbing_vine"

local assets = {
	Asset("ANIM", "anim/cave_exit_rope.zip"),
	Asset("ANIM", "anim/copycreep_build.zip"),
}

local prefabs = {
	"plantmeat",
	"rope",
}

local brain = require "brains/grabbing_vinebrain"

SetSharedLootTable('grabbing_vine', {
    {'plantmeat',  0.4},
    {'rope',  0.4},
})

local RESTARGET_MUST_TAGS = {"_combat","_health"}
local RETARGET_CANT_TAGS = {"FX", "NOCLICK","INLIMBO", "wall"}
local function ReTargetFn(inst)
	if not inst.components.health:IsDead() then
            local target = FindEntity(inst, TUNING.GRABBING_VINE_TARGET_DIST, function(guy)
                if guy.components.combat ~= nil and
                    guy.components.health ~= nil and
                    not guy.components.health:IsDead() then
                    return guy.components.inventory ~= nil and not guy:HasTag("plantkin")
                end
            end,
            RESTARGET_MUST_TAGS,
            RETARGET_CANT_TAGS
        )

		return target
	end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function shadownon(inst)
	inst.DynamicShadow:SetSize(1.5, .75)
end

local function shadowoff(inst)
	inst.DynamicShadow:SetSize(0,0)
end

local function onnear(inst)
	if not inst.near then
		inst.near = true
		inst:PushEvent("godown")
	end
end

local function onfar(inst)
	if inst.near then
		inst.near = nil
		inst:PushEvent("goup")
	end
end

local function onhitotherfn(inst, other)
    inst.components.thief:StealItem(other)
end

local function canbeattackedfn(inst, attacker)
    return not inst:HasTag("up")
end

local function OnSave(inst, data)
	local references = {}
  	if inst.spawnpatch then
  		data.spawnpatch = inst.spawnpatch.GUID
  		references = {data.leader}
  	end
    return references
end

local function OnLoad(inst, data)
end

local function LoadPostPass(inst,ents, data)
    if data ~= nil then
		if data.spawnpatch then
			local spawnpatch = ents[data.spawnpatch]
            if spawnpatch then
                inst.spawnpatch = spawnpatch.entity
            end
	    end
	end
end

local function OnKilled(inst)
	if inst.spawnpatch ~= nil then
		inst.spawnpatch.spawnNewVine(inst.spawnpatch, inst.prefab)
	end
end

local function commonfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize( 1.5, .75 )
	inst.Transform:SetFourFaced()

	MakeCharacterPhysics(inst, 1, .3)

    inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
	inst.Physics:CollidesWith(COLLISION.FLYERS)

	inst:AddTag("flying")
	inst:AddTag("hangingvine")
	inst:AddTag("animal")

	inst.AnimState:SetBank("exitrope")
	inst.AnimState:SetBuild("copycreep_build")
	inst.AnimState:PlayAnimation("idle_loop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.GRABBING_VINE_WALKSPEED
    inst.components.locomotor.runspeed = TUNING.GRABBING_VINE_RUNSPEED

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.GRABBING_VINE_HEALTH)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('grabbing_vine')

	inst:AddComponent("thief")

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.GRABBING_VINE_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.GRABBING_VINE_ATTACK_PERIOD)
	inst.components.combat:SetRange(TUNING.GRABBING_VINE_RANGE, TUNING.GRABBING_VINE_HITRANGE)
	inst.components.combat:SetRetargetFunction(1, ReTargetFn)
	inst.components.combat.canbeattackedfn = canbeattackedfn
	inst.components.combat.onhitotherfn = onhitotherfn

    --藤蔓不能被冰冻
	-- MakeTinyFreezableCharacter(inst, "frogsack")

	inst:AddComponent("knownlocations")
	inst:DoTaskInTime(0, function()
		inst.components.knownlocations:RememberLocation("home", Point(inst.Transform:GetWorldPosition()), true)
	end)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst.components.playerprox:SetDist(10,16)

    inst:AddComponent("distancefade")
    inst.components.distancefade:Setup(25,15)

 	inst:AddComponent("eater")
 	inst.components.eater:SetOmnivore()
     inst.components.eater.strongstomach = true

	inst:AddComponent("inspectable")

	inst:SetStateGraph("SGgrabbing_vine")
	inst:SetBrain(brain)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("death", OnKilled)

	inst.shadownon = shadownon
	inst.shadowoff = shadowoff

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.LoadPostPass = LoadPostPass

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

	onfar(inst)
	inst.sg:GoToState("idle_up")

	return inst
end

return Prefab("grabbing_vine", commonfn, assets, prefabs)
