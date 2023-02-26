local assets =
{
    Asset("ANIM", "anim/tree_leaf_short.zip"),
    Asset("ANIM", "anim/tree_leaf_normal.zip"),
    Asset("ANIM", "anim/tree_leaf_tall.zip"),

    Asset("ANIM", "anim/teatree_trunk_build.zip"),
    Asset("ANIM", "anim/teatree_build.zip"),

    Asset("ANIM", "anim/dust_fx.zip"),
    Asset("SOUND", "sound/forest.fsb"),
}

local prefabs =
{
    "log",
    "twigs",
    "teatree_nut",
    "charcoal",
    "green_leaves",
    "green_leaves_chop",
}

local builds =
{
	normal = {
		leavesbuild="teatree_build",
		prefab_name="teatree",
		normal_loot = {"log", "twigs","teatree_nut"},
		short_loot = {"log"},
		tall_loot = {"log", "log", "twigs", "teatree_nut","teatree_nut"},
		drop_nut=true,
        fx="green_leaves",
        chopfx="green_leaves_chop",
        shelter=true,
    },
}

local function MakeAnims(stage)
    return {
        idle="idle_"..stage,
        sway1="sway1_loop_"..stage,
        sway2="sway2_loop_"..stage,
        chop="chop_"..stage,
        fallleft="fallleft_"..stage,
        fallright="fallright_"..stage,
        stump="stump_"..stage,
        burning="burning_loop_"..stage,
        burnt="burnt_"..stage,
        chop_burnt="chop_burnt_"..stage,
        idle_chop_burnt="idle_chop_burnt_"..stage,
        blown1="blown_loop_"..stage.."1",
        blown2="blown_loop_"..stage.."2",
        blown_pre="blown_pre_"..stage,
        blown_pst="blown_pst_"..stage
    }
end


local short_anims = MakeAnims("short")
local tall_anims = MakeAnims("tall")
local normal_anims = MakeAnims("normal")

-- local function GetBuild(inst)
--     return builds[inst.build] or builds.normal
-- end

local function GetBuild(inst)
    return builds.normal
end

local function SpawnLeafFX(inst, waittime, chop)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or
        inst:HasTag("stump") or
        inst:HasTag("burnt") or
        inst:IsAsleep() then
        return
    elseif waittime ~= nil then
        inst:DoTaskInTime(waittime, SpawnLeafFX, nil, chop)
        return
    end

    local fx = nil
    if chop then
        if GetBuild(inst).chopfx ~= nil then
            fx = SpawnPrefab(GetBuild(inst).chopfx)
        end
    elseif GetBuild(inst).fx ~= nil then
        fx = SpawnPrefab(GetBuild(inst).fx)
    end
    if fx ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        if inst.components.growable ~= nil then
            if inst.components.growable.stage == 1 then
                -- y = y + 0 --Short FX height
            elseif inst.components.growable.stage == 2 then
                y = y - .3 --Normal FX height
            elseif inst.components.growable.stage == 3 then
                -- y = y + 0 --Tall FX height
            end
        end
        --Randomize height a bit for chop FX
        fx.Transform:SetPosition(x, chop and y + math.random() * 2 or y, z)
    end
end

----------------------------------------------------------------------------------------------------

local function PushSway(inst)
	if math.random() > .5 then
		inst.AnimState:PushAnimation(inst.anims.sway1, true)
	else
		inst.AnimState:PushAnimation(inst.anims.sway2, true)
	end
end

local function Sway(inst)
	if math.random() > .5 then
		inst.AnimState:PlayAnimation(inst.anims.sway1, true)
	else
		inst.AnimState:PlayAnimation(inst.anims.sway2, true)
	end
	inst.AnimState:SetTime(math.random()*2)
end

-------------------------------------------------------------------------------------------------------------------------------

local function UpdateIdleLeafFx(inst)
	if inst.entity:IsAwake() then
		if inst.spawnleaffxtask == nil then
			inst.spawnleaffxtask = inst:DoPeriodicTask(math.random(TUNING.MIN_SWAY_FX_FREQUENCY, TUNING.MAX_SWAY_FX_FREQUENCY), SpawnLeafFX)
		end
	elseif inst.spawnleaffxtask ~= nil then
		inst.spawnleaffxtask:Cancel()
		inst.spawnleaffxtask = nil
	end
end

local function GrowLeavesFn(inst)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or inst:HasTag("stump") or inst:HasTag("burnt") then
        inst:RemoveEventCallback("animover", GrowLeavesFn)
        return
    end

    if GetBuild(inst).leavesbuild then
        inst.AnimState:OverrideSymbol("swap_leaves", GetBuild(inst).leavesbuild, "swap_leaves")
    else
        inst.AnimState:ClearOverrideSymbol("swap_leaves")
    end

    if inst.components.growable ~= nil then
        if inst.components.growable.stage == 1 then
            inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)
        elseif inst.components.growable.stage == 2 then
            inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)
        else
            inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)
        end
    end

    UpdateIdleLeafFx(inst)

    inst.AnimState:OverrideSymbol("mouseover", "tree_leaf_trunk_build", "toggle_mouseover")

    Sway(inst)
end

local function OnChangeLeaves(inst)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or inst:HasTag("stump") or inst:HasTag("burnt") then
        inst.targetleaveschangetime = nil
        inst.leaveschangetask = nil
        return

    elseif inst.components.workable and inst.components.workable.lastworktime and inst.components.workable.lastworktime < GetTime() - 10 then

        inst.targetleaveschangetime = GetTime() + 11
        inst.leaveschangetask = inst:DoTaskInTime(11, OnChangeLeaves)
        return
    else
        inst.targetleaveschangetime = nil
        inst.leaveschangetask = nil
    end

        -- inst.AnimState:PlayAnimation(inst.anims.growleaves)
        -- inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")

        inst.AnimState:PlayAnimation(inst.anims.dropleaves)
        SpawnLeafFX(inst, 11 * FRAMES)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeWilt")
        inst:ListenForEvent("animover", GrowLeavesFn)

    if GetBuild(inst).shelter then
        inst:AddTag("shelter")
    else
        inst:RemoveTag("shelter")
    end
end

local function ChangeSizeFn(inst)
    inst:RemoveEventCallback("animover", ChangeSizeFn)
    if inst.components.growable ~= nil then
        inst.anims =
            (inst.components.growable.stage == 1 and short_anims) or
            (inst.components.growable.stage == 2 and normal_anims) or
            tall_anims
    end
    Sway(inst)
end

----------------------------------------------------------------------------------------------------

local function SetShort(inst)
    inst.anims = short_anims
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_SMALL)
    end
    inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)
end

local function GrowShort(inst)
    inst.AnimState:PlayAnimation("grow_tall_to_short")
    SpawnLeafFX(inst, 17 * FRAMES)
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

----------------------------------------------------------------------------------------------------

local function SetNormal(inst)
    inst.anims = normal_anims
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_NORMAL)
    end
    inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)
end

local function GrowNormal(inst)
    inst.AnimState:PlayAnimation("grow_short_to_normal")
    SpawnLeafFX(inst, 10 * FRAMES)
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

----------------------------------------------------------------------------------------------------

local function SetTall(inst)
    inst.anims = tall_anims
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_TALL)
    end
    inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)
end

local function GrowTall(inst)
    inst.AnimState:PlayAnimation("grow_normal_to_tall")
    SpawnLeafFX(inst, 10 * FRAMES)
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

----------------------------------------------------------------------------------------------------

local growth_stages =
{
    --Short
    { name = "short",
    time = function(inst)
        return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[1].base, TUNING.DECIDUOUS_GROW_TIME[1].random)
    end,
    fn = SetShort,
    growfn = GrowShort },

    --Normal
    { name = "normal",
    time = function(inst)
        return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[2].base, TUNING.DECIDUOUS_GROW_TIME[2].random)
    end,
    fn = SetNormal,
    growfn = GrowNormal },

    --Tall
    { name = "tall",
    time = function(inst)
        return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[3].base, TUNING.DECIDUOUS_GROW_TIME[3].random)
    end,
    fn = SetTall,
    growfn = GrowTall },
}

local function chop_tree(inst, chopper, chopsleft, numchops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree")
    end

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.SoundEmitter:PlaySound("pl/creatures/piko/in_tree")
    end

    SpawnLeafFX(inst, nil, true)
    inst.AnimState:PlayAnimation(inst.anims.chop)
    PushSway(inst)
end

local function dig_up_stump(inst)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function chop_down_tree_shake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .03, inst.components.growable ~= nil and inst.components.growable.stage > 2 and .5 or .25, inst, 6)
end

local function detachchild(inst)
    if inst.components.spawner and inst.components.spawner.child then
        local child = inst.components.spawner.child
        if child.components.knownlocations then
            child.components.knownlocations:ForgetLocation("home")
        end
        child:RemoveComponent("homeseeker")
    end
end

local function Make_Stump(inst)
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("hauntable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("workable")
    -- inst:RemoveComponent("blowinwindgust")
	inst:RemoveTag("gustable")
    inst:RemoveTag("shelter")
    inst:RemoveTag("cattoyairborne")

    MakeSmallBurnable(inst)
    MakeHauntableIgnite(inst)
    MakeSmallPropagator(inst)
    RemovePhysicsColliders(inst)

    inst:AddTag("stump")
    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    if inst.leaveschangetask ~= nil then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end

    inst.MiniMapEntity:SetIcon("tree_leaf_stump.png")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    if inst.components.timer ~= nil and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME, TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME * .5))
    end
end

local function chop_down_tree(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

    local pt = inst:GetPosition()
    local he_right = true

    if chopper then
        local hispos = chopper:GetPosition()
        he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
    else
        if math.random() > 0.5 then
            he_right = false
        end
    end

    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    inst.components.inventory:DropEverything(false, false)

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end

    detachchild(inst)

    inst:DoTaskInTime(.4, chop_down_tree_shake)

    inst.AnimState:PushAnimation(inst.anims.stump)
    Make_Stump(inst)
end

local function chop_down_burnt_tree(inst, chopper)
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
    RemovePhysicsColliders(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()
    if inst.nuttask ~= nil then
        inst.nuttask:Cancel()
        inst.nuttask = nil
    end
end

local function _onburntchanges2(inst)
    if inst.components.burnable ~= nil and inst.components.propagator ~= nil then
        inst.components.burnable:Extinguish()
        inst.components.propagator:StopSpreading()
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("hauntable")
    end
end

local function onburntchanges(inst)
    inst:RemoveComponent("growable")
    -- inst:RemoveComponent("blowinwindgust")

    inst:RemoveTag("shelter")
    inst:RemoveTag("gustable")

    MakeHauntableWork(inst)

    inst.components.lootdropper:SetLoot({})
    if GetBuild(inst).drop_nut then
        inst.components.lootdropper:AddChanceLoot("teatree_nut", .1)
    end

    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
    end

    if inst.leaveschangetask ~= nil then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end

    detachchild(inst)

    inst:RemoveComponent("spawner")

    inst.MiniMapEntity:SetIcon("tree_leaf_burnt.png")

    inst.AnimState:PlayAnimation(inst.anims.burnt, true)
    inst:DoTaskInTime(3 * FRAMES, _onburntchanges2)
end

local function OnBurnt(inst)
    inst:AddTag("burnt")

    inst:DoTaskInTime(.5, onburntchanges)

    if inst.components.timer ~= nil and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME, TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME * .5))
    end

    inst.AnimState:SetRayTestOnBB(true)
end

local function OnNutTask(inst)
    inst.nuttask = nil
    inst.components.lootdropper:DropLoot(math.random() < .5 and inst:GetPosition() + TheCamera:GetRightVec() or inst:GetPosition() - TheCamera:GetRightVec())
end

local function tree_burnt(inst)
    OnBurnt(inst)
    inst.nuttask = inst:DoTaskInTime(10, OnNutTask)
    if inst.leaveschangetask ~= nil then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end
end

local function handler_growfromseed(inst)
    inst.components.growable:SetStage(1)

    if GetBuild(inst).leavesbuild ~= nil then
        inst.AnimState:OverrideSymbol("swap_leaves", GetBuild(inst).leavesbuild, "swap_leaves")
    else
        inst.AnimState:ClearOverrideSymbol("swap_leaves")
    end

    inst.AnimState:PlayAnimation("grow_seed_to_short")
    SpawnLeafFX(inst, 5 * FRAMES)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    inst.anims = short_anims

	UpdateIdleLeafFx(inst)
    PushSway(inst)
end

local function inspect_tree(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst:HasTag("stump") and "CHOPPED")
        or nil
end

local function OnEntitySleep(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        if inst:HasTag("stump") then
            DefaultBurntFn(inst)
            return
        end

        -- inst:RemoveComponent("growable")
        inst:RemoveEventCallback("animover", ChangeSizeFn)
    end
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("inspectable")

	UpdateIdleLeafFx(inst)
end

-------------------------------------------------------------------------------------------------------------------------------

local function BurnInventoryItems(inst)
    if inst.components.inventory ~= nil then
        local burnableItems = inst.components.inventory:GetItems(function(k,v) return v.components.burnable end)
        for index, burnableItem in ipairs(burnableItems) do
            burnableItem.components.burnable:Ignite(true)
        end
    end
end

local function OnIgnite(inst)
    BurnInventoryItems(inst)

    if inst.components.spawner then
        local child = inst.components.spawner.child
        if child then
            child.components.knownlocations:ForgetLocation("home")
        end

        if inst.components.spawner:IsOccupied() then
            inst.components.spawner:ReleaseChild()
        end
    end
end

-------------------------------------------------------------------------------------------------------------------------------

local function OnEntityWake(inst)
    if not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or inst:HasTag("burnt") then
        if inst:HasTag("stump") then
            inst:RemoveComponent("burnable")
            MakeLargeBurnable(inst)
            inst:RemoveComponent("propagator")
            MakeLargePropagator(inst)
        else
            if inst.components.burnable == nil then
                MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
                inst.components.burnable:SetFXLevel(5)
                inst.components.burnable:SetOnBurntFn(tree_burnt)
                inst.components.burnable:SetOnIgniteFn(OnIgnite)
                inst.components.burnable.extinguishimmediately = false
            end

            if inst.components.propagator == nil then
                MakeMediumPropagator(inst)
            end
        end
    end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end

	UpdateIdleLeafFx(inst)
end

local REMOVABLE =
{
    ["log"] = true,
    ["teatree_nut"] = true,
    ["charcoal"] = true,
}

--清理地上的垃圾
local DECAYREMOVE_MUST_TAGS = { "_inventoryitem" }
local DECAYREMOVE_CANT_TAGS = { "INLIMBO", "fire" }
local function OnTimerDone(inst, data)
    if data.name == "decay" then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 6, DECAYREMOVE_MUST_TAGS, DECAYREMOVE_CANT_TAGS)
        if inst:IsAsleep() then
            local leftone = false
            for i, v in ipairs(ents) do
                if REMOVABLE[v.prefab] then
                    if leftone then
                        v:Remove()
                    else
                        leftone = true
                    end
                end
            end
        else
            local fx = SpawnPrefab("small_puff")
            fx.Transform:SetPosition(x, y, z)
        end
        inst:Remove()
    end
end

local function OnHauntTeaTree(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE and
    not (inst:HasTag("burnt") or inst:HasTag("stump")) then

        inst.components.hauntable.hauntvalue = TUNING.HAUNT_HUGE
        inst.components.hauntable.cooldown_on_successful_haunt = false
        return true
    end
end

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end

    if inst:HasTag("stump") then
        data.stump = true
    end

    if inst.leaveschangetask and inst.targetleaveschangetime then
        data.leaveschangetime = inst.targetleaveschangetime - GetTime()
    end

end

local function OnLoad(inst, data)
    if data ~= nil then

        inst.anims =
            (inst.components.growable == nil and tall_anims) or
            (inst.components.growable.stage == 1 and short_anims) or
            (inst.components.growable.stage == 2 and normal_anims) or
            tall_anims

            if data.stump then
                inst.AnimState:PlayAnimation(inst.anims.stump)
                Make_Stump(inst)
                if data.burnt or inst:HasTag("burnt") then
                    DefaultBurntFn(inst)
                end
            end
        end

        if not inst:IsValid() then
            return
        end

        if data ~= nil and data.leaveschangetime ~= nil then
            inst.leaveschangetask = inst:DoTaskInTime(data.leaveschangetime, OnChangeLeaves)
        end

    if data == nil or not (data.burnt or data.stump) then
        inst.AnimState:OverrideSymbol("mouseover", "tree_leaf_trunk_build", "toggle_mouseover")
        Sway(inst)
    end
end

-------------------------------------------------------------------------------------------------------------------------------

local function GetChild(inst)
    if math.random() < 0.2 then
        return "piko_orange"
    end
    return "piko"
end

local function StartSpawning(inst)
    if inst.components.spawner then
        inst.components.spawner:SpawnWithDelay(2 + math.random(20) )
    end
end

local function StopSpawning(inst)
    if inst.components.spawner then
        inst.components.spawner:CancelSpawning()
    end
end

local function OnSpawned(inst, child)
    child.sg:GoToState("descendtree")
end

local function TestSpawning(inst)
    if TheWorld.state.isday or (TheWorld.state.moonphase == "new" and TheWorld.state.isnight) then
        StartSpawning(inst)
    else
        StopSpawning(inst)
    end
end

local function OnOccupied(inst,child)
    if child.components.inventory:NumItems() > 0 then
        for i, item in ipairs(child.components.inventory:GetItems(true)) do
            child.components.inventory:DropItem(item)
            inst.components.inventory:GiveItem(item)
        end
    end
end

local function SetUpSpawner(inst)
    inst:AddTag("pikonest")
    inst.components.spawner:Configure("piko", 10)
    inst.components.spawner.childfn = GetChild
    inst.components.spawner:SetOnSpawnedFn(OnSpawned)
    inst.components.spawner:SetOnOccupiedFn(OnOccupied)
    inst:AddTag("dumpchildrenonignite")
    -- This tag allows the piko to spawn at the same location as the home (ie. tree), so that when it plays the
    -- animation for climbing down, it appears on the trunk, rather than floating in the air next to the trunk.
    -- inst:AddTag("exclude_home_offset")
	inst:WatchWorldState("isday", TestSpawning)
	inst:WatchWorldState("isdusk", TestSpawning)
	inst:WatchWorldState("isnight", TestSpawning)
end

local function pikofix(inst)
    if TheWorld.meta.pikofixed or inst.components.spawner then
        return
    end

    local x,y,z = inst.Transform:GetWorldPosition()
    local ground = TheWorld
    for k , node in ipairs(ground.topology.nodes)do
        if node.type == "piko_land" and TheSim:WorldPointInPoly(x, z, node.poly) then

            inst:AddComponent("spawner")
            SetUpSpawner(inst)
            break
        end
    end
end

------------------------------------------------------------------------------------------

local function WindAnims(inst, type)
	if type == 1 then
		local anim = math.random(1,2)
		return inst.anims["blown"..tostring(anim)]
	elseif type == 2 then
		return inst.anims.blown_pst
	end
	return inst.anims.blown_pre
end

------------------------------------------------------------------------------------------

local function MakeTeaTree(name, stage, data, patch)
    local function fn()
		local l_stage = stage
		if l_stage == 0 then
			l_stage = math.random(1,3)
		end

        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

        inst.MiniMapEntity:SetIcon("teatree.tex")
		inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("teatree")
        inst:AddTag("shelter")
        inst:AddTag("workable")
        inst:AddTag("gustable")
        inst:AddTag("cattoyairborne")

        if patch then
            inst:SetPrefabName("teatree")
        end

        --Yes the T is capitilized, welcome to ds code hell. Enjoy your stay!
        inst.AnimState:SetBank("tree_leaf")
        inst.AnimState:SetBuild("teatree_trunk_build")

        if GetBuild(inst).leavesbuild then
            inst.AnimState:OverrideSymbol("swap_leaves", GetBuild(inst).leavesbuild, "swap_leaves")
        end

		inst:SetPrefabName(GetBuild(inst).prefab_name)

        inst.color = 0.7 + math.random() * 0.3
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(tree_burnt)
        inst.components.burnable:SetOnIgniteFn(OnIgnite)
        inst.components.burnable.extinguishimmediately = false
        MakeMediumPropagator(inst)

        inst:AddComponent("plantregrowth")
        inst.components.plantregrowth:SetRegrowthRate(TUNING.DECIDUOUS_REGROWTH.OFFSPRING_TIME)
        inst.components.plantregrowth:SetProduct("teatree_nut_sapling")
        inst.components.plantregrowth:SetSearchTag("teatree")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree)

        inst:AddComponent("inventory")
        inst:AddComponent("lootdropper")
        -- inst:AddComponent("mystery")

        inst.SpawnLeafFX = SpawnLeafFX

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(l_stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        inst.growfromseed = handler_growfromseed

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(OnHauntTeaTree)

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)

        --暂时没有风
        -- MakeTreeBlowInWindGust(inst, TUNING.PALMTREE_WINDBLOWN_SPEED, TUNING.PALMTREE_WINDBLOWN_FALL_CHANCE)
        inst.PushSway = PushSway
        inst.Sway = Sway
        -- inst.WindGetAnims = WindAnims

        inst:DoTaskInTime(0, pikofix(inst))

        inst.SetUpSpawner= SetUpSpawner

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

		MakeSnowCovered(inst, .01)

        inst.AnimState:SetTime(math.random() * 2)

        if data == "stump" then
            RemovePhysicsColliders(inst)
            inst:AddTag("stump")
            inst:RemoveTag("shelter")

            inst:RemoveComponent("burnable")
            MakeSmallBurnable(inst)
            inst:RemoveComponent("workable")
            inst:RemoveComponent("propagator")
            MakeSmallPropagator(inst)
            inst:RemoveComponent("growable")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(dig_up_stump)
            inst.components.workable:SetWorkLeft(1)
            inst.AnimState:PlayAnimation(inst.anims.stump)
            inst.MiniMapEntity:SetIcon("tree_leaf_stump.png")
        else
            inst.Sway(inst)
        end

        if data == "burnt" then
            OnBurnt(inst)
        end

        if data == "piko_nest" then
            inst:AddComponent("spawner")
            SetUpSpawner(inst)
        end

        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeTeaTree("teatree", 0),

        MakeTeaTree("teatree_normal", 2),
        MakeTeaTree("teatree_tall", 3),
        MakeTeaTree("teatree_short", 1),

        MakeTeaTree("teatree_burnt", 0, "burnt"),
        MakeTeaTree("teatree_stump", 0, "stump"),
        MakeTeaTree("teatree_piko_nest", 0, "piko_nest"),
        MakeTeaTree("teatree_piko_nest_patch", 0, "piko_nest", true)
