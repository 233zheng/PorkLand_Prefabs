
local assets= {
	Asset("ANIM", "anim/cave_exit_rope.zip"),
	Asset("ANIM", "anim/vine01_build.zip"),
	Asset("ANIM", "anim/vine02_build.zip"),
}

local prefabs = {
	"grabbing_vine",
}

local function OnPlayerNear(inst)
	inst.AnimState:PlayAnimation("down")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:PlaySound("pl/creatures/enemy/grabbing_vine/drop")
    inst.DynamicShadow:SetSize(1.5, .75)
end

local function OnPlayerFar(inst)
    inst.AnimState:PlayAnimation("up")
    inst.SoundEmitter:PlaySound("dontstarve/cave/rope_up")
    inst.DynamicShadow:SetSize(0, 0)
end

local function round(x)
  x = x *10
  local num = x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  print(num)
  return num/10
end

local function PlaceGoffGrids(inst, radiusMax, prefab, musttags)
    local x, y, z = inst.Transform:GetWorldPosition()
    local offgrid = false
    local inc = 1
    while offgrid == false do

        if not radiusMax then
        	radiusMax = 12
        end

        local rad = math.random() * radiusMax
        local xdiff = math.random() * rad
        local ydiff = math.sqrt( (rad * rad) - (xdiff * xdiff) )

        if math.random() > 0.5 then
        	xdiff = -xdiff
            print(xdiff)
        end

        if math.random() > 0.5 then
        	ydiff = -ydiff
            print(ydiff)
        end

        x = x + xdiff
        z = z + ydiff
        local radius = 1
        local ents = TheSim:FindEntities(x, y, z, radius, musttags)
        local test = true
        for i , ent in ipairs(ents) do
            print(tostring(ents))
            local entx, enty, entz = ent.Transform:GetWorldPosition()
           print("checing round x:",round(x),round(entx),"z:", round(z), round(entz),"diff:",round(math.abs(entx-x)),round( math.abs(entz-z)) )
            if round(x) == round(entx) or round(z) == round(entz) or ( math.abs(round(entx-x)) == math.abs(round(entz-z)) )  then
                test = false
                print("test fail")
                break
            end
        end

        offgrid = test
        inc = inc + 1
        print(test, offgrid, rad, ydiff, xdiff, radiusMax, x, y, z)
    end

    local tile = TheWorld.Map:GetTileAtPoint(x,y,z)
    if  tile == WORLD_TILES.DEEPRAINFOREST then
    	local plant = SpawnPrefab(prefab)
    	plant.Transform:SetPosition(x, y, z)
    	plant.spawnpatch = inst
        print(tostring(plant))
    	return true
	end
	return false
end

local function SpawnItem(inst, prefab)
	local rad = 14
	if prefab == "grabbing_vine" then
		rad = 12
	end
	PlaceGoffGrids(inst, rad, prefab,{"hangingvine"})
end

local function SpawnVines(inst)
	inst.spawnedchildren = true
    for i = 1, math.random(8,16), 1 do
        SpawnItem(inst,"hanging_vine")
        inst:SetPrefabName("hanging_vine")
    end

    for i = 1, math.random(6,9), 1 do
    	SpawnItem(inst,"grabbing_vine")
        inst:SetPrefabName("grabbing_vine")
    end
end

local function SpawnNewVine(inst, prefab)
	if not inst.spawntasks then
		inst.spawntasks = {}
	end
	local spawntime = TUNING.TOTAL_DAY_TIME * 2 + (TUNING.TOTAL_DAY_TIME*math.random())
	local newtask = {}
    inst.spawntasks[newtask] = newtask
	newtask.prefab = prefab
    newtask.task, newtask.taskinfo = inst:ResumeTask(spawntime,
        function()
            SpawnItem(inst,newtask.prefab)
            inst.spawntasks[newtask] = nil
        end)
    inst.spawntasks[newtask] = newtask
end

local function OnSave(inst, data)
    data.spawnedchildren = inst.spawnedchildren
    if inst.spawntasks then
    	data.spawntasks= {}
    	for i,oldtask in pairs(inst.spawntasks)do
            local test = inst:DoTaskInTime(5,function()end)
            dumptable(test,1,1)

    		local newtask = {}
    		newtask.prefab = oldtask.prefab
    		newtask.time = inst:TimeRemainingInTask(oldtask.taskinfo)
            table.insert(data.spawntasks,newtask)
    	end
    end
end

local function OnLoad(inst, data)
    if data ~=nil then
        if data.spawnedchildren then
        	inst.spawnedchildren = true
        end
        if data.spawntasks then
        	inst.spawntasks = {}
        	for i,oldtask in ipairs(data.spawntasks)do
        		local newtask = {}
                inst.spawntasks[newtask] = newtask
        		newtask.prefab = oldtask.prefab
                newtask.task, newtask.taskinfo = inst:ResumeTask(oldtask.time,
                function()
                    spawnitem(inst,oldtask.prefab)
                    inst.spawntasks[newtask] = nil
                end)
        	end
        end
    end
end

local function patchfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function()
        if not inst.spawnedchildren then
            SpawnVines(inst)
        end
    end)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.spawnNewVine = SpawnNewVine

    return inst
end



local function commonfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(1.5, .75)

    inst:AddTag("gustable")
	inst:AddTag("hangingvine")
    inst:AddTag("plant")

    inst.AnimState:SetBank("exitrope")
	if math.random() < 0.5 then
		inst.AnimState:SetBuild("vine01_build")
	else
		inst.AnimState:SetBuild("vine02_build")
	end

	inst.AnimState:PlayAnimation("idle_loop",true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local function OnShear(inst)
        if inst.spawnpatch then
            inst.spawnpatch.spawnNewVine(inst.spawnpatch, inst.prefab)
        end

        inst:Remove()
    end

    inst:AddComponent("shearable")
    inst.components.shearable:SetProduct("rope", 2 , false)
    inst.components.shearable:SetOnShearFn(OnShear)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(OnPlayerNear)
    inst.components.playerprox:SetOnPlayerFar(OnPlayerFar)
    inst.components.playerprox:SetDist(10,16)

	inst:AddComponent("inspectable")

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

    inst.placegoffgrids = PlaceGoffGrids

	return inst
end

return Prefab("hanging_vine", commonfn, assets, prefabs),
	   Prefab("hanging_vine_patch", patchfn, assets, prefabs)
