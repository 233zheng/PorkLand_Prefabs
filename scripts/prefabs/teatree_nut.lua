require "prefabutil"

local assets = {
    Asset("ANIM", "anim/teatree_nut.zip"),
}

local prefabs =
{
    "teatree_short",
    "teatree_piko_nest",
    "teatree_nut_sapling"
}

local function plant(inst, growtime)
    local teatree_nut_sapling = SpawnPrefab("teatree_nut_sapling")
    teatree_nut_sapling:StartGrowing(growtime)
    teatree_nut_sapling.Transform:SetPosition(inst.Transform:GetWorldPosition())
    teatree_nut_sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    inst:Remove()
end

local function ondeploy(inst, pt, deployer)
    inst = inst.components.stackable:Get()
    inst.Transform:SetPosition(pt:Get())
    local timeToGrow = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
    plant(inst, timeToGrow)
end

local function describe(inst)
    if inst.growtime then
        return "PLANTED"
    end
end

local function OnLoad(inst, data)
    if data and data.growtime then
        plant(inst, data.growtime)
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    -- MakeInventoryFloatable(inst, "idle_water", "idle")
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    inst.AnimState:SetBank("teatree_nut")
    inst.AnimState:SetBuild("teatree_nut")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("plant")
    inst:AddTag("icebox_valid")
    inst:AddTag("cattoy")
    inst:AddTag("show_spoilage")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("tradable")
    inst:AddComponent("bait")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("cookable")
    inst.components.cookable.product = "teatree_nut_cooked"

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = describe

    inst:AddComponent("deployable")
    -- inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = ondeploy

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("edible")
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.antihistamine = 60
    inst.components.edible.foodtype = "SEEDS"
    inst.components.edible.foodstate = "RAW"

    inst.OnLoad = OnLoad

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndPerish(inst)

    return inst
end

local function cooked()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    -- MakeInventoryFloatable(inst, "cooked_water", "cooked")

    inst.AnimState:SetBank("teatree_nut")
    inst.AnimState:SetBuild("teatree_nut")
    inst.AnimState:PlayAnimation("cooked")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("inventoryitem")
    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("edible")
    inst.components.edible.foodstate = "COOKED"
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.antihistamine = 120
    inst.components.edible.foodtype = "SEEDS"

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndPerish(inst)

    return inst
end

------------------------------------------------------------------------------------------

local function growtree(inst)
    local num = math.random(1,2)
    local teatree

    if num == 1 then
        teatree = "teatree_short"
    else
        teatree = "teatree_piko_nest"
    end

    local tree = SpawnPrefab(teatree)
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function stopgrowing(inst)
    inst.components.timer:StopTimer("grow")
end

local function startgrowing(inst, growtime)
    if not inst.components.timer:TimerExists("grow") then
        growtime = growtime or GetRandomWithVariance(TUNING.ACORN_GROWTIME.base, TUNING.ACORN_GROWTIME.random)
        inst.components.timer:StartTimer("grow", growtime)
    end
end

local function ontimerdone(inst, data)
    if data.name == "grow" then
        growtree(inst)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function saplingfn()
    local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("teatree_nut")
	inst.AnimState:SetBuild("teatree_nut")
	inst.AnimState:PlayAnimation("idle_planted")

	inst:AddTag("plant")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.StartGrowing = startgrowing

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", ontimerdone)
	startgrowing(inst)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({"twigs"})

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(digup)
	inst.components.workable:SetWorkLeft(1)

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	inst:ListenForEvent("onignite", stopgrowing)
	inst:ListenForEvent("onextinguish", startgrowing)
	MakeSmallPropagator(inst)

	MakeHauntableIgnite(inst)

    return inst
end

return Prefab("teatree_nut", fn, assets, prefabs),
        Prefab("teatree_nut_sapling", saplingfn, assets, prefabs),
       Prefab("teatree_nut_cooked", cooked, assets),
	   MakePlacer( "teatree_nut_placer", "teatree_nut", "teatree_nut", "idle_planted" )
