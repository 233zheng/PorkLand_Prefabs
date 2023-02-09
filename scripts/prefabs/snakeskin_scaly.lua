local assets= {
    Asset("ANIM", "anim/snakeskin_scaly.zip"),
}

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    -- MakeInventoryFloatable(inst, "idle_water", "idle")
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

    inst.AnimState:SetBank("snakeskin_scaly")
    inst.AnimState:SetBuild("snakeskin_scaly")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("appeasement")
    inst.components.appeasement.appeasementvalue = TUNING.APPEASEMENT_TINY

	MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("snakeskin_scaly", fn, assets)
