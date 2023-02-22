local prefabs = {
    "glowfly",
}

local assets = {
    Asset("ANIM", "anim/pillar_tree.zip"),
}

-- 生成虫卵
local function Spawncocoons(inst, player)
    if math.random() < 0.4 then
        local pt = inst:GetPosition()
        local radius = 5 + math.random()*10
        local start_angle =  math.random() * 2 * PI
        local offset = FindWalkableOffset(pt, start_angle, radius, 10)

        if offset ~= nil then
            local newpoint = pt+offset
            if player:GetDistanceSqToPoint(newpoint) > 40 * 40 then
                for i = 1, math.random(6,10) do
                    radius = math.random()*8
                    start_angle =  math.random() * 2 * PI
                    local suboffset = FindWalkableOffset(newpoint,radius, start_angle, 10)
                    local cocoon = SpawnPrefab("glowfly")
                    local spawnpt = newpoint + suboffset
                    cocoon.Physics:Teleport(spawnpt.x,spawnpt.y,spawnpt.z)
                    cocoon:AddTag("cocoonspawn")
                    cocoon.forceCocoon(cocoon)
                end
            end
        end
    end
end

local function filterspawn(inst)

    if not inst:HasTag("filtered") then
        inst:AddTag("filtered")
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 20, {"tree_pillar"})

        for i,ent in ipairs(ents)do
            if ent == inst then
                table.remove(ents,i)
                break
            end
        end
        if #ents > 0 then
            inst:Remove()
        end
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 3, 24)

    inst.Transform:SetScale(1,1,1)
	inst.MiniMapEntity:SetIcon("pillar_tree.png")

    -- THIS WAS COMMENTED OUT BECAUSE THE ROC WAS BUMPING INTO IT. BUT I'M NOT SURE WHY IT WAS SET THAT WAY TO BEGIN WITH.
    --inst.Physics:SetCollisionGroup(COLLISION.GROUND)
    inst:AddTag("tree_pillar")

	inst.AnimState:SetBank("pillar_tree")
	inst.AnimState:SetBuild("pillar_tree")
    inst.AnimState:PlayAnimation("idle",true)
    -- inst.AnimState:SetMultColour(.2, 1, .2, 1.0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst.Spawncocoons = Spawncocoons

   -- inst:DoTaskInTime(0,function() filterspawn(inst)  end)

    if TheWorld.components.glowflyspawner then
        TheWorld:ListenForEvent("spawncocoons", function() 
            Spawncocoons(inst) 
        end)
    end

   return inst
end

return Prefab("tree_pillar", fn, assets, prefabs )
