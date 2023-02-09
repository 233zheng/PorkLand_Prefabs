require "stategraphs/SGpiko"
require "brains/pikobrain"

local INTENSITY = .5

local assets = {
	Asset("ANIM", "anim/ds_squirrel_basic.zip"),

	Asset("ANIM", "anim/squirrel_cheeks_build.zip"),
	Asset("ANIM", "anim/squirrel_build.zip"),

	Asset("ANIM", "anim/orange_squirrel_cheeks_build.zip"),
	Asset("ANIM", "anim/orange_squirrel_build.zip"),

	Asset("SOUND", "sound/rabbit.fsb"),
}

local loot = {"smallmeat"}

local prefabs =
{
	"smallmeat",
	"cookedsmallmeat",
}

local pikosounds =
{
	scream = "pl/creatures/piko/scream",
	hurt = "pl/creatures/piko/scream",
}

local function updatebuild(inst, cheeks)
	local build = "squirrel_build"

	if cheeks then
		build = "squirrel_cheeks_build"
	end

	if inst:HasTag("orange") then
		build = "orange_"..build
	end

	inst.AnimState:SetBuild(build)
end

local function refreshbuild(inst)
    if inst.components.inventory:NumItems() >0 then
        inst.updatebuild(inst, true)
    else
        inst.updatebuild(inst, false)
    end
end

local function OnWake(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function OnSleep(inst)
	if inst.checktask ~= nil then
		inst.checktask:Cancel()
		inst.checktask = nil
	end
end

local function OnCooked(inst)
	inst.SoundEmitter:PlaySound("pl/creatures/piko/scream")
end

local function OnAttacked(inst, data)
	local x, y, z = inst.Transform:GetWorldPosition()
    local radis = 30
    local must_tags = {"piko"}
	local ents = TheSim:FindEntities(x, y, z, radis, must_tags)

	local num_friends = 0
	local maxnum = 5
	for k, v in pairs(ents) do
		v:PushEvent("gohome")
		num_friends = num_friends + 1

		if num_friends > maxnum then
			break
		end
	end
end

local function OnWentHome(inst)
    local teatree = inst.components.homeseeker and inst.components.homeseeker.home or nil

    if not teatree then
        return
    end

    if teatree.components.inventory then
        inst.components.inventory:TransferInventory(teatree)
        inst.updatebuild(inst, false)
    end

end

local function Retarget(inst)
    local dist = TUNING.PIKO_TARGET_DIST

    return FindEntity(inst, dist, function(guy)
		return not guy:HasTag("piko") and inst.components.combat:CanTarget(guy)
        and guy.components.inventory
        and (guy.components.inventory:NumItems() > 0)
    end)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function fadein(inst)
    inst.components.fader:StopAll()
	inst.AnimState:Show("eye_red")
	inst.AnimState:Show("eye2_red")
    inst.Light:Enable(true)
	if inst:IsAsleep() then
		inst.Light:SetIntensity(INTENSITY)
	else
		inst.Light:SetIntensity(0)
		inst.components.fader:Fade(0, INTENSITY, 3+math.random()*2, function(v) inst.Light:SetIntensity(v) end)
	end
end

local function fadeout(inst)
    inst.components.fader:StopAll()
	inst.AnimState:Hide("eye_red")
	inst.AnimState:Hide("eye2_red")
	if inst:IsAsleep() then
		inst.Light:SetIntensity(0)
	else
		inst.components.fader:Fade(INTENSITY, 0, 0.75+math.random()*1, function(v) inst.Light:SetIntensity(v) end)
	end
end

local function updatelight(inst)
    if inst.currentlyRabid then

        if not inst.lighton then
            inst:DoTaskInTime(math.random()*2, function()
                fadein(inst)
            end)

        else
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end

		inst.AnimState:Show("eye_red")
		inst.AnimState:Show("eye2_red")
        inst.lighton = true

    else
        if inst.lighton then
            inst:DoTaskInTime(math.random()*2, function()
                fadeout(inst)
            end)

        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end

		inst.AnimState:Hide("eye_red")
		inst.AnimState:Hide("eye2_red")
        inst.lighton = false

    end
end

local function DropItem(inst)
    if inst.components.inventory ~= nil then
        local items = inst.components.inventory:GetItems(true)
        for k, v in ipairs(items) do
            v.components.burnable:Ignite(true)
        end
    end
end

local function OnDeath(inst)
	inst.Light:Enable(false)
end

local function SetAsRabid(inst, rabid)
 	inst.currentlyRabid = rabid
 	-- inst.components.sleeper.nocturnal = rabid
 	updatelight(inst)
end

local function transformtest(inst)
    if TheWorld.state.isnight and  (TheWorld.state.moonphase == "full" and TheWorld.state.isnight) then
        if not inst.currentlyRabid then
            inst:DoTaskInTime(1 + (math.random() * 1), SetAsRabid(inst, true))
        end
    else
        if inst.currentlyRabid then
            inst:DoTaskInTime(1 + (math.random() * 1), SetAsRabid(inst, false))
        end
    end
end

local function converttoorange(inst)
    inst.updatebuild(inst)
end

local function OnSave(inst, data)
    if inst.lighton then
        data.lighton = inst.lighton
    end
    if inst:HasTag("orange") then
        data.orange = true
    end
end

local function OnLoad(inst, data)

    if data ~= nil then

        if data.lighton then
            fadein(inst)
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
            inst.AnimState:Show("eye_red")
            inst.AnimState:Show("eye2_red")
            inst.lighton = true
        end

        if data.orange then
            converttoorange(inst)
        end

    end

    if inst.spawntask then
        inst.spawntask:Cancel()
        inst.spawntask = nil
    end

    refreshbuild(inst)

end

local function OnHitOther(inst, other)
    inst.components.thief:StealItem(other)
end

local function OnDrop(inst)
	refreshbuild(inst)
	inst.sg:GoToState("stunned")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()
	inst.DynamicShadow:SetSize(1, 0.75)

	MakeCharacterPhysics(inst, 1, 0.12)
	MakePoisonableCharacter(inst)

    inst:AddTag("animal")
	inst:AddTag("prey")
	inst:AddTag("piko")
	inst:AddTag("smallcreature")
	inst:AddTag("canbetrapped")
	inst:AddTag("cannotstealequipped")
	inst:AddTag("cattoy")
	inst:AddTag("catfood")

    inst.Light:Enable(false)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetColour(150/255, 40/255, 40/255)
    inst.Light:SetFalloff(0.9)
    inst.Light:SetRadius(2)

	inst.AnimState:SetBank("squirrel")
	inst.AnimState:SetBuild("squirrel_build")
	inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("fader")
    inst:AddComponent("inspectable")
	inst:AddComponent("tradable")
	inst:AddComponent("sleeper")
	inst:AddComponent("sanityaura")
	inst:AddComponent("knownlocations")
    inst:AddComponent("inventory")
    inst:AddComponent("thief")

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.PIKO_RUN_SPEED

	-- Squirrels (ie. pikos), have the same diet as birds, mainly seeds,
	-- which is why this is being set on a non-avian creature.
	inst:AddComponent("eater")
	inst.components.eater:SetBird()

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(loot)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.PIKO_HEALTH)
	inst.components.health.murdersound = "pl/creatures/piko/death"

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.canbepickedup = false

	inst:AddComponent("cookable")
	inst.components.cookable.product = "cookedsmallmeat"
	inst.components.cookable:SetOnCookedFn(OnCooked)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.PIKO_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PIKO_ATTACK_PERIOD)
    inst.components.combat:SetRange(0.7)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat.hiteffectsymbol = "chest"
	inst.components.combat.onhitotherfn = OnHitOther

    local brain = require "brains/pikobrain"
    inst:SetBrain(brain)
	inst:SetStateGraph("SGpiko")

    inst:WatchWorldState("isday", function() transformtest(inst) end)
    inst:WatchWorldState("isnight", function() transformtest(inst) end)
    -- inst:WatchWorldState("isdusk", function() transformtest(inst) end)

	inst:ListenForEvent("death", OnDeath)
	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onwenthome", OnWentHome)
	inst:ListenForEvent("dropitem", OnDrop)

    MakeHauntableLaunch(inst)
	MakeSmallBurnableCharacter(inst, "chest")
	MakeTinyFreezableCharacter(inst, "chest")
	MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME*2, nil, OnDrop)

	inst.data = {}
    inst.force_onwenthome_message = true

	inst.currentlyRabid = false
	inst.sounds = pikosounds

	inst.OnEntityWake = OnWake
	inst.OnEntitySleep = OnSleep

	inst.updatebuild = updatebuild

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	SetAsRabid(inst, false)
	transformtest(inst)

    return inst
end

local function piko_orange()
    local inst = fn()

    inst:AddTag("orange")

    updatebuild(inst)

    return inst
end

return Prefab("piko", fn, assets, prefabs),
		Prefab("piko_orange", piko_orange, assets, prefabs)
