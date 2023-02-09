local prefabs =
{
    "antqueen",
}

local ANTQUEEN_SPAWNTIMER = "regen_antqueen"

local function StartSpawning(inst)
    inst.components.worldsettingstimer:StartTimer(ANTQUEEN_SPAWNTIMER, TUNING.DRAGONFLY_RESPAWN_TIME)
end

local function GenerateNewQueen(inst)
    inst.components.childspawner:AddChildrenInside(1)
    inst.components.childspawner:StartSpawning()
end

local function ontimerdone(inst, data)
    if data.name == ANTQUEEN_SPAWNTIMER then
        GenerateNewQueen(inst)
    end
end

local function onspawned(inst, child)

    local throne = GetClosestInstWithTag("throne", inst, 5)
    if throne then
        throne:Remove()
    end

    local x, y, z = child.Transform:GetWorldPosition()
    child.Transform:SetPosition(x, y, z)
    child.sg:GoToState("sleep")
    child:PushEvent("spawnantqueen")
    TUNING.ANTQUEEN_SPAWN_COUNT = TUNING.ANTQUEEN_SPAWN_COUNT + 1
end

local function OnPreLoad(inst, data)
    if data and data.childspawner then
        data.childspawner.spawning = true
    end
end

local function OnLoadPostPass(inst, newents, data)
    if inst.components.childspawner:CountChildrenOutside() + inst.components.childspawner.childreninside == 0 and
    not inst.components.worldsettingstimer:ActiveTimerExists(ANTQUEEN_SPAWNTIMER) then
        StartSpawning(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "antqueen"
    inst.components.childspawner:SetMaxChildren(1)
    inst.components.childspawner:SetSpawnPeriod(TUNING.DRAGONFLY_SPAWN_TIME, 0)
    inst.components.childspawner.onchildkilledfn = StartSpawning

    if not TUNING.SPAWN_ANTQUEEN then
        inst.components.childspawner.childreninside = 0
    end

    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StopRegen()
    inst.components.childspawner:SetSpawnedFn(onspawned)

    inst:AddComponent("worldsettingstimer")
    inst.components.worldsettingstimer:AddTimer(ANTQUEEN_SPAWNTIMER, TUNING.DRAGONFLY_RESPAWN_TIME, TUNING.SPAWN_DRAGONFLY)

    inst:ListenForEvent("timerdone", ontimerdone)

    inst.OnPreLoad = OnPreLoad
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("antqueen_spawner", fn, nil, prefabs)
