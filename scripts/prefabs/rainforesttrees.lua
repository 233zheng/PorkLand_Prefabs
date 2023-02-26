local assets =
{
	Asset("ANIM", "anim/tree_forest_rot_build.zip"),
	Asset("ANIM", "anim/tree_rainforest_gas_build.zip"),

	Asset("ANIM", "anim/tree_forest_bloom_build.zip"),

	Asset("ANIM", "anim/tree_rainforest_build.zip"),
	Asset("ANIM", "anim/tree_rainforest_bloom_build.zip"),
	Asset("ANIM", "anim/tree_rainforest_normal.zip"),
	Asset("ANIM", "anim/tree_rainforest_short.zip"),
	Asset("ANIM", "anim/tree_rainforest_tall.zip"),
	Asset("ANIM", "anim/dust_fx.zip"),
}

local prefabs =
{
	"log",
	"charcoal",
	"chop_mangrove_pink",
	"fall_mangrove_pink",
	"snake_amphibious",
	"cave_banana",
	"bird_egg",
	"scorpion",
	"burr",
}

local builds =
{
	normal = {
		file="tree_rainforest_build",
		prefab_name="rainforesttree",
		normal_loot = {"log", "log"},
		short_loot = {"log"},
		tall_loot = {"log", "log", "log"},
	},
	rot = {
		file="tree_rainforest_gas_build",
		prefab_name="rainforesttree_rot",
		normal_loot = {"log", "log"},
		short_loot = {"log"},
		tall_loot = {"log", "log", "log"},
	},
	blooming = {
		file="tree_rainforest_bloom_build",
		prefab_name="rainforesttree",
		normal_loot = {"log", "log"},
		short_loot = {"log"},
		tall_loot = {"log", "log", "log"},
	}
}

local function makeanims(stage)
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

local short_anims = makeanims("short")
local tall_anims = makeanims("tall")
local normal_anims = makeanims("normal")

local function dig_up_stump(inst, chopper)
	inst:Remove()
	inst.components.lootdropper:SpawnLootPrefab("log")
end

local function chop_down_burnt_tree(inst, chopper)
	inst:RemoveComponent("workable")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
	inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
	RemovePhysicsColliders(inst)
	inst:ListenForEvent("animover", function() inst:Remove() end)
	inst.components.lootdropper:SpawnLootPrefab("charcoal")
	inst.components.lootdropper:DropLoot()
	if inst.pineconetask then
		inst.pineconetask:Cancel()
		inst.pineconetask = nil
	end
end

local function GetBuild(inst)
	local build = builds[inst.build]
	if build == nil then
		return builds["normal"]
	end
	return build
end

local burnt_highlight_override = {.5,.5,.5}
local function OnBurnt(inst, imm)

	local function changes()
		if inst.components.burnable then
			inst.components.burnable:Extinguish()
		end
		inst:RemoveComponent("burnable")
		inst:RemoveComponent("propagator")
		inst:RemoveComponent("growable")
		-- inst:RemoveComponent("blowinwindgust")
        inst:RemoveComponent("hauntable")

		inst:RemoveTag("shelter")
		inst:RemoveTag("gustable")
        inst:AddTag("burnt")

        MakeHauntableWork(inst)

		inst.components.lootdropper:SetLoot({})

		if inst.components.workable then
			inst.components.workable:SetWorkLeft(1)
			inst.components.workable:SetOnWorkCallback(nil)
			inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
		end
	end

	if imm then
		changes()
	else
		inst:DoTaskInTime( 0.5, changes)
	end
	inst.AnimState:PlayAnimation(inst.anims.burnt, true)
	inst.AnimState:SetRayTestOnBB(true)


	inst.highlight_override = burnt_highlight_override
end

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

local function SetShort(inst)
	inst.anims = short_anims

	if inst.components.workable then
		inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_SMALL)
	end
	-- if inst:HasTag("shelter") then inst:RemoveTag("shelter") end

	inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)

	if math.random() < 0.5 then
		for i = 1, TUNING.SNAKE_JUNGLETREE_AMOUNT_SMALL do
			if math.random() < 0.5 and TheWorld.state.cycles >= TUNING.SNAKE_POISON_START_DAY then
				inst.components.lootdropper:AddChanceLoot("scorpion", TUNING.SNAKE_JUNGLETREE_CHANCE)
			else
				inst.components.lootdropper:AddChanceLoot("snake_amphibious", TUNING.SNAKE_JUNGLETREE_CHANCE)
			end
		end
	end

	inst.Transform:SetScale(0.9,0.9,0.9)

	Sway(inst)
end

local function GrowShort(inst)
	inst.AnimState:PlayAnimation("grow_tall_to_short")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
	PushSway(inst)
end

local function SetNormal(inst)
	inst.anims = normal_anims

	if inst.components.workable then
		inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_NORMAL)
	end
	-- if inst:HasTag("shelter") then inst:RemoveTag("shelter") end

	inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)

	if math.random() < 0.5 then
		for i = 1, TUNING.SNAKE_JUNGLETREE_AMOUNT_MED do
			if math.random() < 0.5 and TheWorld.state.cycles >= TUNING.SNAKE_POISON_START_DAY then
				inst.components.lootdropper:AddChanceLoot("scorpion", TUNING.SNAKE_JUNGLETREE_CHANCE)
			else
				inst.components.lootdropper:AddChanceLoot("snake_amphibious", TUNING.SNAKE_JUNGLETREE_CHANCE)
			end
		end
	else
		inst.components.lootdropper:AddChanceLoot("bird_egg", 1.0)
	end
	inst.Transform:SetScale(0.8,0.8,0.8)

	Sway(inst)
end

local function GrowNormal(inst)
	inst.AnimState:PlayAnimation("grow_short_to_normal")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
	PushSway(inst)
end

local function SetTall(inst)
	inst.anims = tall_anims
	if inst.components.workable then
		inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_TALL)
	end
	inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)

	if math.random() < 0.5 then
		for i = 1, TUNING.SNAKE_JUNGLETREE_AMOUNT_TALL do
			if math.random() < 0.5 and TheWorld.state.cycles >= TUNING.SNAKE_POISON_START_DAY then
				inst.components.lootdropper:AddChanceLoot("scorpion", TUNING.SNAKE_JUNGLETREE_CHANCE)
			else
				inst.components.lootdropper:AddChanceLoot("snake_amphibious", TUNING.SNAKE_JUNGLETREE_CHANCE)
			end
		end
	else
		inst.components.lootdropper:AddChanceLoot("bird_egg", 1.0)
	end

	inst.Transform:SetScale(0.7,0.7,0.7)
	Sway(inst)
end

local function GrowTall(inst)
	inst.AnimState:PlayAnimation("grow_normal_to_tall")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
	PushSway(inst)
end

local function inspect_tree(inst)
	if inst:HasTag("burnt") then
		return "BURNT"
	elseif inst:HasTag("stump") then
		return "CHOPPED"
	end
end

local growth_stages =
{
	{name="short", time = function(inst) return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[1].base, TUNING.JUNGLETREE_GROW_TIME[1].random) end, fn = function(inst) SetShort(inst) end,  growfn = function(inst) GrowShort(inst) end , leifscale=.7 },
	{name="normal", time = function(inst) return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[2].base, TUNING.JUNGLETREE_GROW_TIME[2].random) end, fn = function(inst) SetNormal(inst) end, growfn = function(inst) GrowNormal(inst) end, leifscale=1 },
	{name="tall", time = function(inst) return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[3].base, TUNING.JUNGLETREE_GROW_TIME[3].random) end, fn = function(inst) SetTall(inst) end, growfn = function(inst) GrowTall(inst) end, leifscale=1.25 },
}


local function chop_tree(inst, chopper, chops)

	if chopper and chopper.components.beaverness and chopper.components.beaverness:IsBeaver() then
		inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/beaver_chop_tree")
	else
		inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
	end

	local fx = SpawnPrefab("chop_mangrove_pink")
	local x, y, z= inst.Transform:GetWorldPosition()
	fx.Transform:SetPosition(x,y + 2 + math.random()*2,z)

	inst.AnimState:PlayAnimation(inst.anims.chop)
	inst.AnimState:PushAnimation(inst.anims.sway1, true)
end

local function testforbloomingdrop(inst,pt)
	if inst.components.bloomable.blooming then
		local loop = 1
		if inst.components.growable.stage == 3 then
			loop = 2
		end
		for i=1, loop do
			local burr = SpawnPrefab("burr")
			inst.components.lootdropper:DropLootPrefab(burr, pt)
		end
	end
end

local function chop_down_tree_shake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .03, inst.components.growable ~= nil and inst.components.growable.stage > 2 and .5 or .25, inst, 6)
end

local function MakeStump(inst)
	inst:RemoveComponent("burnable")
	inst:RemoveComponent("propagator")
	inst:RemoveComponent("workable")
    inst:RemoveComponent("hauntable")
	inst:RemoveTag("shelter")
	-- inst:RemoveComponent("blowinwindgust")
	inst:RemoveTag("gustable")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
    RemovePhysicsColliders(inst)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(dig_up_stump)
	inst.components.workable:SetWorkLeft(1)

	inst:AddTag("stump")

    if inst.components.growable ~= nil then
		inst.components.growable:StopGrowing()
	end

	inst:AddTag("NOCLICK")
	inst:DoTaskInTime(2, function() inst:RemoveTag("NOCLICK") end)
end

local function chop_down_tree(inst, chopper)
	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
	local pt = Vector3(inst.Transform:GetWorldPosition())
	local hispos = Vector3(chopper.Transform:GetWorldPosition())

	local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0

	if he_right then
		inst.AnimState:PlayAnimation(inst.anims.fallleft)
		inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
		testforbloomingdrop(inst,pt - TheCamera:GetRightVec())
	else
		inst.AnimState:PlayAnimation(inst.anims.fallright)
		inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
		testforbloomingdrop(inst,pt + TheCamera:GetRightVec())
	end

	local fx = SpawnPrefab("fall_mangrove_pink")
	local x, y, z= inst.Transform:GetWorldPosition()
	fx.Transform:SetPosition(x,y + 2 + math.random()*2,z)

	-- make snakes attack
	local x,y,z = inst.Transform:GetWorldPosition()
	local snakes = TheSim:FindEntities(x,y,z, 2,nil,nil,{"snake_amphibious","scorpion"})
	for k, v in pairs(snakes) do
		if v.components.combat then
			v.components.combat:SetTarget(chopper)
		end
	end

    inst:DoTaskInTime(.4, chop_down_tree_shake)

	inst.AnimState:PushAnimation(inst.anims.stump)
    MakeStump(inst)
end

local function tree_burnt(inst)
	OnBurnt(inst)
	inst.pineconetask = inst:DoTaskInTime(10, function()
        local pt = Vector3(inst.Transform:GetWorldPosition())
        if math.random(0, 1) == 1 then
            pt = pt + TheCamera:GetRightVec()
        else
            pt = pt - TheCamera:GetRightVec()
        end
        inst.components.lootdropper:DropLoot(pt)
        inst.pineconetask = nil
    end)
end

local function dropCritter(inst, prefab)

	local snake = SpawnPrefab(prefab)
	local pt = Vector3(inst.Transform:GetWorldPosition())

	if math.random(0, 1) == 1 then
		pt = pt + (TheCamera:GetRightVec()*((math.random()*1)+1))
	else
		pt = pt - (TheCamera:GetRightVec()*((math.random()*1)+1))
	end

	snake.sg:GoToState("fall")
	pt.y = pt.y + (2*inst.components.growable.stage)

	snake.Transform:SetPosition(pt:Get())
end

local function OnIgnite(inst)
	DefaultIgniteFn(inst)
	if not inst.flushed and math.random() < 0.4 then
		inst.flushed = true

		local prefab = "snake_amphibious"

		if math.random() < 0.5 then
			prefab = "scorpion"
		end

		inst:DoTaskInTime(math.random()*0.5, function() dropCritter(inst, prefab) end)
		if math.random() < 0.3 and prefab == "snake_amphibious" then
			inst:DoTaskInTime(math.random()*0.5, function() dropCritter(inst, prefab) end)
		end

	end
end

local function handler_growfromseed(inst)
	inst.components.growable:SetStage(1)
	inst.AnimState:PlayAnimation("grow_seed_to_short")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
	PushSway(inst)
end

local function updateTreeType(inst)
	inst.AnimState:SetBuild(GetBuild(inst).file)
end

local function doTransformBloom(inst)
	if not inst:HasTag("rotten") then
		inst.build = "blooming"

		updateTreeType(inst)
	end
end

local function doTransformNormal(inst)
	if not inst:HasTag("rotten") then
		inst.build = "normal"

		updateTreeType(inst)
	end
end

local function Make_Stump(inst)
    inst:RemoveComponent("burnable")
    MakeSmallBurnable(inst)
    inst:RemoveComponent("workable")
    inst:RemoveComponent("propagator")
    MakeSmallPropagator(inst)
    inst:RemoveComponent("growable")
    inst:RemoveComponent("hauntable")
    MakeHauntableIgnite(inst)
    inst:RemoveComponent("blowinwindgust")
    inst:RemoveTag("gustable")
    RemovePhysicsColliders(inst)

    inst:AddTag("stump")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    -- Start the decay timer if we haven't already.
    if inst.components.timer ~= nil and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(TUNING.PALMTREE_REGROWTH.DEAD_DECAY_TIME, TUNING.PALMTREE_REGROWTH.DEAD_DECAY_TIME*0.5))
    end
end

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end

	if inst.flushed then
		data.flushed = inst.flushed
	end

	if inst:HasTag("stump") then
		data.stump = true
	end

	if inst.build ~= "normal" then
		data.build = inst.build
	end

	if inst.bloomtaskinfo then
		data.bloomtask = inst:TimeRemainingInTask(inst.bloomtaskinfo)
	end
	if inst.unbloomtaskinfo then
		data.unbloomtask = inst:TimeRemainingInTask(inst.unbloomtaskinfo)
	end
end

local function OnLoad(inst, data)
	if data then
		if not data.build or builds[data.build] == nil then
			 doTransformNormal(inst)
		else
			inst.build = data.build
		end

        if data.bloomtask then
            if inst.bloomtask then inst.bloomtask:Cancel() inst.bloomtask = nil end
            inst.bloomtaskinfo = nil
            inst.bloomtask, inst.bloomtaskinfo = inst:ResumeTask(data.bloomtask, doTransformBloom(inst))
        end

        if data.unbloomtask then
            if inst.unbloomtask then inst.unbloomtask:Cancel() inst.unbloomtask = nil end
            inst.unbloomtaskinfo = nil
            inst.unbloomtask, inst.unbloomtaskinfo = inst:ResumeTask(data.unbloomtask, doTransformNormal(inst))
        end

		if data.flushed then
			inst.flushed = data.flushed
		end

		if data.burnt then
			inst:AddTag("burnt")
		elseif data.stump then
            Make_Stump(inst)
			inst.AnimState:PlayAnimation(inst.anims.stump)
		end
	end
end

local function OnEntitySleep(inst)
	local burnt = false
	if inst:HasTag("burnt") then
		burnt = true
	end
	inst:RemoveComponent("burnable")
	inst:RemoveComponent("propagator")
	inst:RemoveComponent("inspectable")
	if burnt then
		inst:AddTag("burnt")
	end
end

local function OnEntityWake(inst)

	if not inst:HasTag("burnt")then
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
			if inst:HasTag("stump") then
				MakeSmallBurnable(inst)
			else
				MakeLargeBurnable(inst)
				inst.components.burnable:SetFXLevel(5)
				inst.components.burnable:SetOnBurntFn(tree_burnt)
                inst.components.burnable:SetOnIgniteFn(OnIgnite)
			end
		end

        if inst.components.propagator == nil then
			if inst:HasTag("stump") then
				MakeSmallPropagator(inst)
			else
				MakeLargePropagator(inst)
			end
		end
	elseif not inst:HasTag("burnt") and inst:HasTag("burnt") then
		OnBurnt(inst, true)
	end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end
end

local function DropBurr(inst)
	if not inst:HasTag("burnt") then
		local burr = SpawnPrefab("burr")
		local pt = Vector3(inst.Transform:GetWorldPosition())

		if math.random(0, 1) == 1 then
			pt = pt + (TheCamera:GetRightVec()*((math.random()*1)+1))
		else
			pt = pt - (TheCamera:GetRightVec()*((math.random()*1)+1))
		end

		burr.AnimState:PlayAnimation("drop")
		burr.AnimState:PushAnimation("idle")

		--pt.y = pt.y + (2*inst.components.growable.stage)

		burr.Transform:SetPosition(pt:Get())
	end
end

local function CanBloom(inst)
	 if not inst:HasTag("stump") and not inst:HasTag("rotten") and inst.components.growable and  inst.components.growable.stage == 3 then
	 	return true
	 else
	 	return false
	 end
end

local function StartBloomFn(inst)
	doTransformBloom(inst)
end

local function StopBloomFn(inst)
	doTransformNormal(inst)
end

local function OnHauntTree(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE and
    not (inst:HasTag("burnt") or inst:HasTag("stump")) then

        inst.components.hauntable.hauntvalue = TUNING.HAUNT_HUGE
        inst.components.hauntable.cooldown_on_successful_haunt = false
        return true
    end
end

local function MakeFn(build, stage, data)
	local function fn()
		local l_stage = stage
		if l_stage == 0 then
			l_stage = math.random(1,3)
		end

		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
        inst.entity:AddMiniMapEntity()
		inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, .25)

		inst.MiniMapEntity:SetIcon("tree_rainforest.png")
        inst.MiniMapEntity:SetPriority(-1)

		inst:AddTag("plant")
		inst:AddTag("tree")
		inst:AddTag("workable")
		inst:AddTag("shelter")
		inst:AddTag("gustable")
		inst:AddTag("jungletree")

		if build == "rot" then
			inst:AddTag("rotten")
		end

		inst.build = build
		inst.AnimState:SetBuild(GetBuild(inst).file)
		inst.AnimState:SetBank("rainforesttree")

		inst.AnimState:SetTime(math.random()*2)

		inst:SetPrefabName(GetBuild(inst).prefab_name)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

		local color = 0.5 + math.random() * 0.5
		inst.AnimState:SetMultColour(color, color, color, 1)

		MakeLargeBurnable(inst)
		inst.components.burnable:SetFXLevel(3)
		inst.components.burnable:SetOnBurntFn(tree_burnt)
		inst.components.burnable:SetOnIgniteFn(OnIgnite)

        MakeSmallPropagator(inst)

        -- inst:AddComponent("mystery")

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(OnHauntTree)

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = inspect_tree

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetOnWorkCallback(chop_tree)
		inst.components.workable:SetOnFinishCallback(chop_down_tree)

		inst:AddComponent("lootdropper")

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

		inst:AddComponent("bloomable")
		inst.components.bloomable:SetCanBloom(CanBloom)
		inst.components.bloomable:SetStartBloomFn(StartBloomFn)
		inst.components.bloomable:SetStopBloomFn(StopBloomFn)
		inst.components.bloomable:SetDoBloom(DropBurr)

		if data =="burnt"  then
			OnBurnt(inst)
		end

		if data =="stump"  then
            Make_Stump(inst)
		end

		MakeSnowCovered(inst, .01)

		inst.OnSave = OnSave
		inst.OnLoad = OnLoad

		inst.OnEntitySleep = OnEntitySleep
		inst.OnEntityWake = OnEntityWake

		return inst
	end
	return fn
end

local function MakeRainForestTree(name, build, stage, data)
	return Prefab(name, MakeFn(build, stage, data), assets, prefabs)
end

return MakeRainForestTree("rainforesttree", "normal", 0),
        MakeRainForestTree("rainforesttree_normal", "normal", 2),
        MakeRainForestTree("rainforesttree_tall", "normal", 3),
		MakeRainForestTree("rainforesttree_short", "normal", 1),
		MakeRainForestTree("rainforesttree_burnt", "normal", 0, "burnt"),
		MakeRainForestTree("rainforesttree_stump", "normal", 0, "stump"),

		MakeRainForestTree("rainforesttree_rot", "rot", 0),
		MakeRainForestTree("rainforestree_rot_normal", "rot", 2),
		MakeRainForestTree("rainforesttree_rot_tall", "rot", 3),
		MakeRainForestTree("rainforesttree_rot_short", "rot", 1),
		MakeRainForestTree("rainforesttree_rot_burnt", "rot", 0, "burnt"),
		MakeRainForestTree("rainforesttree_rot_stump", "rot", 0, "stump")
