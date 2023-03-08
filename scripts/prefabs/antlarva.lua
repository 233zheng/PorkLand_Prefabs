require("stategraphs/SGantlarva")

local assets =
{
	Asset("ANIM", "anim/ant_larva.zip"),
}

local function SpawnAnt(inst)
	local ant = SpawnPrefab("antman")
	local pt = inst:GetPosition():Get()
	ant.Transform:SetPosition(pt.x, pt.y, pt.z)
end

local function OnHit(inst, dist)
	inst.sg:GoToState("land")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeAntLarvaPhysics(inst)

	inst.AnimState:SetBank("ant_larva")
    inst.AnimState:SetBuild("ant_larva")

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor")

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetOnHit(OnHit)
	inst.components.complexprojectile.yOffset = 2.5

	inst.SpawnAnt = SpawnAnt

	inst:SetStateGraph("SGantlarva")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	return inst
end

return Prefab("antlarva", fn, assets)
