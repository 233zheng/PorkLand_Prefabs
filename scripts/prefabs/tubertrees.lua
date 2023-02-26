local assets =
{
	Asset("ANIM", "anim/tuber_tree_build.zip"),
	Asset("ANIM", "anim/tuber_bloom_build.zip"),

	Asset("ANIM", "anim/tuber_tree.zip"),
	Asset("ANIM", "anim/dust_fx.zip"),
	Asset("SOUND", "sound/forest.fsb"),
}

local prefabs =
{
	"charcoal",
	"chop_mangrove_pink",
	"fall_mangrove_pink",
	"tuber_crop",
	"tuber_bloom_crop",
	"tuber_crop_cooked",
	"tuber_bloom_crop_cooked",
}

local builds =
{
	normal = {
		file="tuber_tree_build",
		prefab_name="tubertree",
		tuberslots_short ={5,6},
		tuberslots_tall ={8,5,7},
	},
	blooming = {
		file="tuber_bloom_build",
		prefab_name="tubertree",
		tuberslots_short ={5,6},
		tuberslots_tall ={8,5,7},
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

local function dig_up_stump(inst, chopper)
	inst:Remove()
	inst.components.lootdropper:SpawnLootPrefab("tuber_crop")
end

local function chop_down_burnt_tree(inst, chopper)
	inst:RemoveComponent("hackable")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bamboo_hack")
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

local function updateart(inst)
	for k,v in ipairs(inst.tuberslots) do
		inst.AnimState:Hide("tubers"..v)
	end

	for i = 1, inst.tubers do
		inst.AnimState:Show("tubers"..inst.tuberslots[i])
	end
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
        inst:RemoveComponent("hauntable")
        MakeHauntableWork(inst)
		-- inst:RemoveComponent("blowinwindgust")
		inst:RemoveTag("shelter")
		inst:RemoveTag("fire")
		inst:RemoveTag("gustable")

		inst.components.lootdropper:SetLoot({})

		if inst.components.workable ~= nil then
			inst.components.workable:SetWorkLeft(1)
			inst.components.workable:SetOnWorkCallback(nil)
			inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
		end

		if inst.components.hackable then
			inst.components.hackable.onhackedfn = chop_down_burnt_tree
		end
	end

	if imm then
		changes()
	else
		inst:DoTaskInTime( 0.5, changes)
	end
	inst.AnimState:PlayAnimation(inst.anims.burnt, true)
	--inst.AnimState:SetRayTestOnBB(true);
	inst:AddTag("burnt")

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
	inst.maxtubers = 2
	inst.tuberslots = GetBuild(inst).tuberslots_short
	Sway(inst)
end

local function GrowShort(inst)
	inst.AnimState:PlayAnimation("grow_tall_to_short")
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/volcano_cactus/grow_pre")
	inst.tubers = math.min(inst.tubers, inst.maxtubers)
	updateart(inst)
	PushSway(inst)
end

local function SetTall(inst)
	inst.maxtubers = 3
	inst.anims = tall_anims
	inst.tuberslots = GetBuild(inst).tuberslots_tall
	Sway(inst)
end

local function GrowTall(inst)
	inst.AnimState:PlayAnimation("grow_short_to_tall")
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/volcano_cactus/grow_pre")
	inst.tubers = math.min(inst.tubers + 1, inst.maxtubers)
	updateart(inst)
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
	{
		name="short",
	 	time = function(inst) return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[1].base, TUNING.CLAWPALMTREE_GROW_TIME[1].random) end,
	 	fn = function(inst) SetShort(inst) end,
	 	growfn = function(inst) GrowShort(inst) end,
	 	leifscale=.7
	 },

	{
		name="tall",
		time = function(inst) return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[3].base, TUNING.CLAWPALMTREE_GROW_TIME[3].random) end,
		fn = function(inst) SetTall(inst) end,
		growfn = function(inst) GrowTall(inst) end,
		leifscale=1.25
	},
}

local function tree_burnt(inst)
    local function pineconetask()
        local pt = Vector3(inst.Transform:GetWorldPosition())
        if math.random(0, 1) == 1 then
            pt = pt + TheCamera:GetRightVec()
        else
            pt = pt - TheCamera:GetRightVec()
        end
        inst.components.lootdropper:DropLoot(pt)
        inst.pineconetask = nil
    end

	OnBurnt(inst)

    inst.pineconetask = inst:DoTaskInTime(10,pineconetask)
end

local function OnIgnite(inst)
	DefaultIgniteFn(inst)
end

local function updateTreeType(inst)
	inst.AnimState:SetBuild(GetBuild(inst).file)
end

local function doTransformBloom(inst)
	if not inst:HasTag("rotten") then
		inst.build = "blooming"
		inst.components.hackable.product = "tuber_bloom_crop"

		updateTreeType(inst)
	end
end

local function doTransformNormal(inst)
	if not inst:HasTag("rotten") then
		inst.build = "normal"
		if inst.components.hackable ~= nil then
			inst.components.hackable.product = "tuber_crop"
		end
		updateTreeType(inst)
	end
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or inst:HasTag("fire") then
		data.burnt = true
	end

	if inst.flushed then
		data.flushed = inst.flushed
	end

	if inst.tubers then
		data.tubers  = inst.tubers
	end

	if inst:HasTag("stump") then
		data.stump = true
	end

	if inst.build ~= "normal" then
		data.build = inst.build
	end
end

local function onload(inst, data)
	if data then
		if not data.build or builds[data.build] == nil then
			 doTransformNormal(inst)
		else
			inst.build = data.build
		end

        if data.bloomtask then
            if inst.bloomtask then inst.bloomtask:Cancel() inst.bloomtask = nil end
            inst.bloomtaskinfo = nil
            inst.bloomtask,
            inst.bloomtaskinfo = inst:ResumeTask(data.bloomtask, function() doTransformBloom(inst) end)
        end
            if data.unbloomtask then
                if inst.unbloomtask then
                inst.unbloomtask:Cancel()
                inst.unbloomtask = nil
            end
            inst.unbloomtaskinfo = nil
            inst.unbloomtask,
            inst.unbloomtaskinfo = inst:ResumeTask(data.unbloomtask, function() doTransformNormal(inst) end)
        end

		if data.flushed then
			inst.flushed = data.flushed
		end

		if data.tubers then
			inst.tubers = data.tubers
		end

		if data.burnt then
            -- Add the fire tag here: OnEntityWake will handle it actually doing burnt logic
			inst:AddTag("burnt")
		elseif data.stump then

			inst:RemoveComponent("burnable")
			MakeSmallBurnable(inst)

			inst:RemoveComponent("propagator")
			MakeSmallPropagator(inst)

            inst:RemoveComponent("hauntable")
            MakeHauntableIgnite(inst)

            inst:RemoveComponent("growable")
			RemovePhysicsColliders(inst)
			inst.AnimState:PlayAnimation(inst.anims.stump)
			inst:AddTag("stump")
			inst:RemoveTag("shelter")
			inst:RemoveTag("gustable")
			-- inst:RemoveComponent("blowinwindgust")
			inst:AddComponent("workable")
			inst.components.workable:SetWorkAction(ACTIONS.DIG)
			inst.components.workable:SetOnFinishCallback(dig_up_stump)
			inst.components.workable:SetWorkLeft(1)
		end
	end
end

local function OnEntitySleep(inst)
	local burnt = false
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() and inst:HasTag("burnt") then
		burnt = true
	end
    if inst:HasTag("stump") then
        DefaultBurntFn(inst)
        return
    end

	inst:RemoveComponent("burnable")
	inst:RemoveComponent("propagator")
	inst:RemoveComponent("inspectable")
	if burnt then
		inst:AddTag("burnt")
	end
end

local function OnEntityWake(inst)
    if not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or inst:HasTag("burnt") then
		if not inst.components.burnable then
			if inst:HasTag("stump") then
				MakeSmallBurnable(inst)
			else
				MakeLargeBurnable(inst)
				inst.components.burnable:SetFXLevel(5)
				inst.components.burnable:SetOnBurntFn(tree_burnt)
                inst.components.burnable:SetOnIgniteFn(OnIgnite)
			end
		end

		if not inst.components.propagator ~= nil then
			if inst:HasTag("stump") then
				MakeSmallPropagator(inst)
			else
				MakeLargePropagator(inst)
			end
		end
	elseif not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) and inst:HasTag("burnt") then
		OnBurnt(inst, true)
	end

	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = inspect_tree
	end
end

local function canbloom(inst)
	 if not inst:HasTag("stump") and not inst:HasTag("rotten") then
	 	return true
	 else
	 	return false
	 end
end

local function startbloom(inst)
	doTransformBloom(inst)
end

local function stopbloom(inst)
	doTransformNormal(inst)
end

local function onregenfn(inst)
	if not inst:HasTag("burnt") then
		inst.tubers = math.min(inst.tubers + 1, inst.maxtubers)
		updateart(inst)
	end
end

local function onhackedfn(inst)
	inst.AnimState:PlayAnimation(inst.anims.chop)
	inst.AnimState:PushAnimation(inst.anims.idle)

	if inst.components.hackable.hacksleft <= 0 then
		inst.tubers = inst.tubers - 1
	end
	updateart(inst)

	inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/volcano_cactus/hit")
end

local function onhackedfinal(prefab,data)
	local inst = data.plant
	inst:RemoveTag("stump")
	if inst.tubers < 0 then
		inst:RemoveComponent("hackable")
	    inst:RemoveComponent("burnable")
	    MakeSmallBurnable(inst)
	    inst:RemoveComponent("propagator")
	    MakeSmallPropagator(inst)
	    inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/volcano_cactus/tuber_fall")

        local he_right = math.random()>0.5 and true or false
		local pt = Vector3(inst.Transform:GetWorldPosition())

	    if data.hacker then

	    	local hispos = Vector3(data.hacker.Transform:GetWorldPosition())

	    	he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
		end

	    if he_right then
	        inst.AnimState:PlayAnimation(inst.anims.fallleft)
	        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
	    else
	        inst.AnimState:PlayAnimation(inst.anims.fallright)
	        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
	    end

		RemovePhysicsColliders(inst)
    	inst.AnimState:PushAnimation(inst.anims.stump)

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

	else

		if inst.components.hackable ~= nil then
			inst.components.hackable.hacksleft = inst.components.hackable.maxhacks
		    inst.components.hackable.canbehacked = true
		    inst.components.hackable.hasbeenhacked = false
		end
	end
end

------------------------------------------------------------------------------------------
--haunt
local function onhauntwork(inst, haunter)
    if inst.components.workable ~= nil and math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
        inst.components.workable:WorkedBy(haunter, 1)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function onhaunttubertree(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE and
    not (inst:HasTag("burnt") or inst:HasTag("stump")) then

        inst.components.hauntable.hauntvalue = TUNING.HAUNT_HUGE
        inst.components.hauntable.cooldown_on_successful_haunt = false
        return true
    end
    return onhauntwork(inst, haunter)
end

------------------------------------------------------------------------------------------

local function WindAnims(inst, type)
	if type == 1 then
		local num = math.random(1,2)
		return inst.anims["blown"..tostring(num)]
	elseif type == 2 then
		return inst.anims.blown_pst
	end
	return inst.anims.blown_pre
end

------------------------------------------------------------------------------------------

local function MakeFn(build, stage, data)

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

		inst.MiniMapEntity:SetIcon("tuber_trees.tex")
		inst.MiniMapEntity:SetPriority(-1)

		inst:AddTag("plant")
		inst:AddTag("tree")
		inst:AddTag("workable")
		inst:AddTag("shelter")
		inst:AddTag("gustable")
		inst:AddTag("tubertree")

		inst.build = build
		inst.AnimState:SetBuild(GetBuild(inst).file)
		inst.AnimState:SetBank("tubertree")

        local color = 0.5 + math.random() * 0.5
        inst.AnimState:SetMultColour(color, color, color, 1)

		inst:SetPrefabName(GetBuild(inst).prefab_name)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

		--PushSway(inst)
		inst.AnimState:SetTime(math.random() * 2)

        MakeSmallPropagator(inst)
        MakeLargeBurnable(inst)
		inst.components.burnable:SetFXLevel(3)
		inst.components.burnable:SetOnBurntFn(tree_burnt)
		inst.components.burnable:SetOnIgniteFn(OnIgnite)

		inst:AddComponent("lootdropper")
		--inst:AddComponent("mystery")

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(onhaunttubertree or onhauntwork)

		inst:AddComponent("bloomable")
		inst.components.bloomable:SetCanBloom(canbloom)
		inst.components.bloomable:SetStartBloomFn(startbloom)
		inst.components.bloomable:SetStopBloomFn(stopbloom)
		inst.components.bloomable.season = {SEASONS.SUMMER}

		inst:AddComponent("growable")
		inst.components.growable.stages = growth_stages
		inst.components.growable:SetStage(l_stage)
		inst.components.growable.loopstages = true
		inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
		inst.components.growable:StartGrowing()

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

		inst:AddComponent("hackable")
		inst.components.hackable:SetUp("tuber_crop", TUNING.VINE_REGROW_TIME )
		inst.components.hackable.onregenfn = onregenfn
		inst.components.hackable.onhackedfn = onhackedfn
		inst.components.hackable.hacksleft = 3
		inst.components.hackable.maxhacks = 3

		inst:ListenForEvent("hacked", onhackedfinal)

		if data =="burnt"  then
			OnBurnt(inst)
		end

		if data =="stump"  then
			inst:RemoveComponent("burnable")
			MakeSmallBurnable(inst)
			inst:RemoveComponent("propagator")
			MakeSmallPropagator(inst)
            inst:RemoveComponent("hauntable")
			inst:RemoveComponent("growable")
			-- inst:RemoveComponent("blowinwindgust")
			inst:RemoveTag("gustable")
			RemovePhysicsColliders(inst)
			inst.AnimState:PlayAnimation(inst.anims.stump)
			inst:AddTag("stump")
			inst:AddComponent("workable")
			inst.components.workable:SetWorkAction(ACTIONS.DIG)
			inst.components.workable:SetOnFinishCallback(dig_up_stump)
			inst.components.workable:SetWorkLeft(1)
		end

        --暂时没有风
        -- MakeTreeBlowInWindGust(inst, TUNING.PALMTREE_WINDBLOWN_SPEED, TUNING.PALMTREE_WINDBLOWN_FALL_CHANCE)
        inst.PushSway = PushSway
        inst.Sway = Sway
        -- inst.WindGetAnims = WindAnims

		inst.OnEntitySleep = OnEntitySleep
		inst.OnEntityWake = OnEntityWake

		inst.tubers = inst.maxtubers
		inst.OnSave = onsave
		inst.OnLoad = onload
        updateart(inst)

		MakeSnowCovered(inst, .01)

		return inst
	end
	return fn
end

local function MakeTuberTree(name, build, stage, data)
	return Prefab(name, MakeFn(build, stage, data), assets, prefabs)
end

return MakeTuberTree("tubertree", "normal", 0),
        MakeTuberTree("tubertree_tall", "normal", 2),
        MakeTuberTree("tubertree_short", "normal", 1),
        MakeTuberTree("tubertree_burnt", "normal", 0, "burnt"),
        MakeTuberTree("tubertree_stump", "normal", 0, "stump")
