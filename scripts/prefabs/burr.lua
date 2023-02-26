require "prefabutil"

local assets = {
	Asset("ANIM", "anim/burr.zip"),
}

local prefabs = {
    "rainforesttree_sapling",
    "rainforesttree_short"
}

local function plant(inst, growtime)
    local rainforesttree_sapling = SpawnPrefab("rainforesttree_sapling")
    rainforesttree_sapling:StartGrowing(growtime)
    rainforesttree_sapling.Transform:SetPosition(inst.Transform:GetWorldPosition())
    rainforesttree_sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    rainforesttree_sapling:AddTag("rainforesttree")
    inst:Remove()
end

local function ondeploy(inst, pt, deployer)
    inst = inst.components.stackable:Get()
    inst.Transform:SetPosition(pt:Get())
    local timeToGrow = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
    plant(inst, timeToGrow)
end

local function hatchtree(inst)
    local pt = inst:GetPosition()
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 20, {"rainforesttree"},{"stump"})
    if #ents < 4 then
        ondeploy(inst, pt)
    else
        if inst:GetIsOnWater() then
            inst.AnimState:PlayAnimation("disappear_water")
        else
            inst.AnimState:PlayAnimation("disappear")
        end
        inst:ListenForEvent("animover", function() inst:Remove() end)
    end
end

local function OnSeasonChange(inst)
    if TheWorld.state.issummer and not inst:HasTag("rainforesttree") then
        inst.taskgrow, inst.taskgrowinfo = inst:ResumeTask( math.random()* TUNING.TOTAL_DAY_TIME/2,function()
            hatchtree(inst)
        end)
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.growtime ~= nil then
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
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

    inst:AddTag("plant")
    inst:AddTag("cattoy")

    inst.AnimState:SetBank("burr")
    inst.AnimState:SetBuild("burr")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    inst:AddComponent("appeasement")
    inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy

    inst:WatchWorldState("season", OnSeasonChange)

    inst.OnLoad = OnLoad

    MakeHauntableLaunchAndPerish(inst)
	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    return inst
end

local function growtree(inst)
    local rainforesttree = SpawnPrefab("rainforesttree_short")
    if rainforesttree then
        rainforesttree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        rainforesttree:growfromseed()
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

    inst:AddTag("plant")

	inst.AnimState:SetBank("burr")
	inst.AnimState:SetBuild("burr")
	inst.AnimState:PlayAnimation("idle_planted")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.StartGrowing = startgrowing

	inst:AddComponent("timer")

	startgrowing(inst)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({"twigs"})

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(digup)
	inst.components.workable:SetWorkLeft(1)

	inst:ListenForEvent("timerdone", ontimerdone)
	inst:ListenForEvent("onignite", stopgrowing)
	inst:ListenForEvent("onextinguish", startgrowing)

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)
	MakeHauntableIgnite(inst)

    return inst
end

return Prefab("burr", fn, assets, prefabs),
        Prefab("rainforesttree_sapling", saplingfn, assets, prefabs),
        MakePlacer("burr_placer", "burr", "burr", "idle_planted")
