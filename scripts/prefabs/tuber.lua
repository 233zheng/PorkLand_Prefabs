local assets =
{
	Asset("ANIM", "anim/tuber_crop.zip"),
    Asset("ANIM", "anim/tuber_bloom_crop.zip"),
}

local function oneaten(inst, eater)
    if eater.components.poisonable and eater:HasTag("poisonable") then
        eater.components.poisonable:Poison()
    end
end

local function commomfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    -- MakeInventoryFloatable(inst, "idle_water", "idle")

    return inst
end

local function masterfn(inst)
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "VEGGIE"

    inst:AddComponent("perishable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

local function fn()
	local inst = commomfn()

    inst.AnimState:SetBank("tuber_crop")
    inst.AnimState:SetBuild("tuber_crop")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("poisonous")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible:SetOnEatenFn(oneaten)
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "tuber_crop_cooked"

    return inst
end

local function cookedfn()
    local inst = commomfn()

    inst.AnimState:SetBank("tuber_crop")
    inst.AnimState:SetBuild("tuber_crop")
    inst.AnimState:PlayAnimation("cooked")

    inst:AddTag("poisonous")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

    inst.components.edible:SetOnEatenFn(oneaten)
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.foodstate = "COOKED"

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    return inst
end

local function bloomfn()
    local inst = commomfn()

    inst.AnimState:SetBank("tuber_bloom_crop")
    inst.AnimState:SetBuild("tuber_bloom_crop")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL

    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "tuber_bloom_crop_cooked"

    return inst
end

local function cookedbloomfn()
    local inst = commomfn()

    inst.AnimState:SetBank("tuber_bloom_crop")
    inst.AnimState:SetBuild("tuber_bloom_crop")
    inst.AnimState:PlayAnimation("cooked")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_TINY
    inst.components.edible.foodstate = "COOKED"

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    return inst
end

local function MakeTuber(name, fn, assets)
    return Prefab(name, fn, assets)
end

return MakeTuber("tuber_crop", fn, assets),
            MakeTuber("tuber_crop_cooked", cookedfn, assets),
            MakeTuber("tuber_bloom_crop", bloomfn, assets),
            MakeTuber("tuber_bloom_crop_cooked", cookedbloomfn, assets)
