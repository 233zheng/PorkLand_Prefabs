require("stategraphs/SGglowfly_cocoon")

--NOTE: 在温和季，茧会爆掉，在其他季节(毁灭季呢？)则会孵化生成疯狂甲虫

local assets = {
	Asset("ANIM", "anim/lantern_fly.zip"),
}

local prefabs = {
    "glowfly"
}

-- 如果有玩家在附近并且这个萤火虫带有readytohatch时，推送事件hatch
local function OnNear(inst)
	if inst:HasTag("readytohatch") then
		inst:DoTaskInTime(5 + math.random() * 3, function()
            inst:PushEvent("hatch")
        end)
	end
end

-- 生成疯狂甲虫
local function SpawnRabidBeetle(inst)
    local pos = Vector3(inst.Transform:GetWorldPosition())

    local rabid_beetle = SpawnPrefab("rabid_beetle")
    if rabid_beetle then
        rabid_beetle.Transform:SetPosition(pos.x,pos.y,pos.z)
        rabid_beetle.sg:GoToState("hatch")
    end
end

-- 在切换季节时，如果季节是温和季，那么设置
local function OnChangeSeason(inst, season)
    if season ~= SEASONS.AUTUMN then
        inst.expiretask, inst.expiretaskinfo = inst:ResumeTask(2 * TUNING.SEG_TIME + math.random() * 3, function()
            inst.sg:GoToState("cocoon_expire")
        end)
    else
        inst:AddTag("readytohatch")
        if inst.components.playerprox == nil then
            inst:AddComponent("playerprox")
            inst.components.playerprox:SetDist(30,31)
            inst.components.playerprox:SetOnPlayerNear(OnNear)
        end
    end
end

local function OnSave(inst, data)
    if inst.expiretaskinfo ~= nil then
		data.expiretasktime = inst:TimeRemainingInTask(inst.expiretaskinfo)
	end
end

local function OnLoad(inst, data)
    if data.expiretasktime ~= nil then
        inst.expiretask, inst.expiretaskinfo = inst:ResumeTask(data.expiretasktime, function()
            inst.sg:GoToState("cocoon_expire")
        end)
    end
end

local function mainfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(0.6,0.6,0.6)

    MakeCocoonPhysics(inst)

    inst:AddTag("insect")
	inst:AddTag("animal")
	inst:AddTag("smallcreature")
	inst:AddTag("butterfly")
	inst:AddTag("cocoon")

	inst.AnimState:SetBank("lantern_fly")
	inst.AnimState:SetBuild("lantern_fly")
	inst.AnimState:PlayAnimation("cocoon_idle_pre")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('glowfly')

    inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.GLOWFLY_COCOON_HEALTH)

    inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "body"


    inst:SetStateGraph("glowfly_cocoon")

    inst:ListenForEvent("glowflyhatch", SpawnRabidBeetle)

    inst:WatchWorldState("season", OnChangeSeason)

    inst.SpawnRabidBeetle = SpawnRabidBeetle

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
	MakeSmallBurnableCharacter(inst, "upper_body", Vector3(0, -1, 1))
	MakeTinyFreezableCharacter(inst, "upper_body", Vector3(0, -1, 1))

    return inst
end

return Prefab("glowfly_cocoon", mainfn, assets, prefabs)
