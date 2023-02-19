local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function BeginGas(inst)
	if inst.gasTask == nil then
		inst.gasTask = inst:DoPeriodicTask(TUNING.GAS_INTERVAL, function()
            local safe = false

            -- check armour
            if inst.components.inventory then
                for k,v in pairs(inst.components.inventory.equipslots) do
                    if v.components.equippable and v.components.equippable:IsPoisonGasBlocker() then
                        safe = true
                    end
                end
            end

            if inst:HasTag("has_gasmask") then
                safe = true
            end

            -- 我们暂时还没有这个
            -- if IsPoisonDisabled() then
            --     safe = true
            -- end

            if not safe then
                inst.components.health:DoGasDamage(TUNING.GAS_DAMAGE_PER_INTERVAL)
                inst:PushEvent("poisondamage")
                inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_GAS_DAMAGE"))
            end
        end)
	end
end

local function EndGas(inst)
	if inst.gasTask then
		inst.gasTask:Cancel()
		inst.gasTask = nil
	end
end

local function OnGasChange(inst, onGas)
	if not inst.gassources then
		inst.gassources = 0
	end

	if onGas then
		inst.gassources = inst.gassources +1
		if inst.gassources > 0 and not inst.gasTask then
			BeginGas(inst)
		end
	else
		inst.gassources = math.max(0,inst.gassources - 1)
		if inst.gassources < 1 then
			EndGas(inst)
		end
	end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("tiletracker")
    inst.components.tiletracker:SetOnGasChangeFn(OnGasChange)
    inst.components.tiletracker:Start()

    inst.OnGasChange = OnGasChange

end)
