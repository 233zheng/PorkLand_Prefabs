--------------------------------------------------------------------------
--[[ GlowflySpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "GlowflySpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------1

--Public
self.inst = inst

--Private
local _world = TheWorld
local _worldstate = _world.state
local _ismastersim = _world.ismastersim
local _updating = false

-- 萤火虫数量
local numglowflys = 0

-- 正在活动的玩家
local _activeplayers = {}
local _scheduledtasks = {}

local glowflys = {}

-- 生成预制体
local prefab = "glowfly"

local spawndata = {
    -- 生成时间
    timetospawn = 10,

    nexttimetospawndata = {
        -- 下一次生成时间
        nexttimetospawn = 10,
        nexttimetospawnBase = 10,
        --
        nexttimetospawn_default = 10,
        nexttimetospawnBase_default = 10,
        -- 下一次生成警告时间?
        nexttimetospawn_warm = 2,
        nexttimetospawnBase_warm = 0,
        -- 冷却时间？
        nexttimetospawn_cold = 50,
        nexttimetospawnBase_cold = 50
    }
}

-- 看不懂啥意思
local glowflycapdata = {
    glowflycap = 4,
    glowflycap_default = 4,
    glowflycap_warm = 10,
    glowflycap_cold = 0
}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

-- 获取生成点
local function GetSpawnPoint(spawnerinst)
	local rad = 25
	local x,y,z = spawnerinst.Transform:GetWorldPosition()
    local MUST_TAGS = {'flower_rainforest'}
	local nearby_ents = TheSim:FindEntities(x,y,z, rad, MUST_TAGS)
	local mindistance = 36
	local validflowers = {}

	for k, flower in ipairs(nearby_ents) do
		if flower ~= nil and
		spawnerinst:GetDistanceSqToInst(flower) > mindistance then
			table.insert(validflowers, flower)
		end
	end

	if #validflowers > 0 then
		local f = validflowers[math.random(1, #validflowers)]
		return f
	else
		return nil
	end
end

-- 在玩家周围的生成萤火虫
local function SpawnGlowflyForFlower(player, reschedule)
    -- 获取玩家坐标
    local pt = player:GetPosition()
    -- 半径
    local rad = 64
    -- 获取半径64内带有glowfly标签的实体
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, rad, {"glowfly"})


end

-- 计划在玩家周围生成
local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil then
        local basedelay = initialspawn and 0.3 or 10
        _scheduledtasks[player] = player:DoTaskInTime(basedelay + math.random() * 10, SpawnButterflyForPlayer, ScheduleSpawn)
    end
end

-- 取消生成
local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function SetBugCocoonTimer(inst)
	inst.SetCocoontask(inst)
    -- cocoon_task = inst:DoTaskInTime(math.random()*3, function()
        -- inst.begincocoonstage(inst)
    -- end) --+ (math.random()*TUNING.SEG_TIME*2)
end

-- 切换生成
local function ToggleUpdate(dt)

end

-- 开始结茧
local function StartCocoonTimer()
	print("开始结茧")
	spawndata.nexttimetospawndata.nexttimetospawn = spawndata.nexttimetospawndata.nexttimetospawn_cold
	spawndata.nexttimetospawndata.nexttimetospawnBase = spawndata.nexttimetospawndata.nexttimetospawnBase_cold
	glowflycapdata.glowflycap = glowflycapdata.glowflycap_cold
	spawndata.timetospawn = 0

	for glowfly, i in pairs(glowflys) do
		SetBugCocoonTimer(glowfly)
	end

    -- seed the map with many more cocoons.
    _world:PushEvent("spawncocoons")
end

-- 设置萤火虫结茧
local function SetGlowflyCocoontask(inst, time)
	inst.glowflycocoontask, inst.glowflycocoontaskinfo = inst:ResumeTask(time, function()
        StartCocoonTimer()
    end)
end

-- 设置萤火虫卵孵化
local function SetGlowflyhatchtask(inst, time)
	inst.glowflyhatchtask, inst.glowflyhatchtaskinfo = inst:ResumeTask(time, function()
        _world:PushEvent("glowflyhatch")
    end)
end

-- 加载范围外自动移除
local function AutoRemoveTarget(inst, target)
    if glowflys[target] ~= nil and target:IsAsleep() then
        target:Remove()
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

--
local function OnGlowflySleep(target)
    inst:DoTaskInTime(0, AutoRemoveTarget, target)
end

-- 当有玩家加入游戏时
local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
    if _updating then
        ScheduleSpawn(player, true)
    end
end

-- 当有玩家离开游戏时
local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            CancelSpawn(player)
            table.remove(_activeplayers, i)
            return
        end
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

--Register events
-- inst:WatchWorldState("isday", ToggleUpdate)
-- inst:WatchWorldState("iswinter", ToggleUpdate)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Public getters and setters ]]
--------------------------------------------------------------------------

function self:Setglowfly(prefab)
    prefab = prefab
end

function self:StartTracking(inst)
    if glowflys[inst] == nil then
        local restore = inst.persists and 1 or 0
        inst.persists = false
        if inst.components.homeseeker == nil then
            inst:AddComponent("homeseeker")
        else
            restore = restore + 2
        end
        glowflys[inst] = restore
        inst:ListenForEvent("entitysleep", OnGlowflySleep, inst)
    end
end

function self:StartTrackingFn(glowfly)
    self:StartTracking(glowfly)
end

function self:StopTracking(inst)
    local restore = glowflys[inst]
    if restore ~= nil then
        inst.persists = restore == 1 or restore == 3
        if restore < 2 then
            inst:RemoveComponent("homeseeker")
        end
        glowflys[inst] = nil
        inst:RemoveEventCallback("entitysleep", OnGlowflySleep, inst)
    end
end

function self:StopTrackingFn(glowfly)
    self:StopTracking(glowfly)
end

function self:ToggleUpdate(dt)

-- 	local spawnerinst

--     if self.followplayer then
--     	spawnerinst = GetPlayer()
--     else
--     	spawnerinst = self.inst
--     end

--     if spawnerinst ~= nil then
-- 	   print("GLOWFLY TIME", spawndata.timetospawn, self.numglowflys, glowflycapdata.glowflycap)
-- 		if spawndata.timetospawn > 0 then
-- 			spawndata.timetospawn = spawndata.timetospawn - dt
-- 		end

-- 		if spawnerinst and self.prefab then
-- 			if spawndata.timetospawn <= 0 then

-- 				local spawnFlower = GetSpawnPoint(spawnerinst)

-- 				if spawnFlower and self.numglowflys < glowflycapdata.glowflycap then
-- 					local glowfly = SpawnPrefab(self.prefab)
-- 					local spawn_point = Vector3(spawnFlower.Transform:GetWorldPosition() )
-- 					glowfly.Physics:Teleport(spawn_point.x,spawn_point.y,spawn_point.z)
-- 					glowfly.components.pollinator:Pollinate(spawnFlower)
-- 					self:StartTracking(glowfly)
-- 					glowfly.components.homeseeker:SetHome(spawnFlower)
-- 					glowfly.OnBorn(glowfly)
-- 				end

-- 				if self.followplayer then
-- 					spawndata.timetospawn = spawndata.nexttimetospawndata.nexttimetospawnBase + math.random() * self.nexttimetospawn
-- 				else
-- 					spawndata.timetospawn = math.random()
-- 				end

--             end
-- 		end
-- 	end

-- 	local season_percent = GetWorld().components.seasonmanager:GetPercentSeason()

-- 	-- if GetWorld().components.seasonmanager:IsTemperateSeason() and not self.nocycle then

--     if _world.state.isautumn and not self.nocycle then

-- 		if season_percent > 0.3 and season_percent <= 0.8 then
-- 			-- the glowgly pop grows starting at 30% season time to 80% season time where it reaches the max.
-- 			-- so basically it takes half the season to go from default to the humid season settings and reaches max 80% into the season.
-- 			-- 联机无法获取季节百分比，所以这里需要重构
--             season_percent = season_percent + 0.2
-- 			local diff_percent =  1 - math.sin(PI * season_percent)

--             spawndata.nexttimetospawndata.nexttimetospawn = math.floor(self.nexttimetospawn_default + ( diff_percent * (self.nexttimetospawn_warm - self.nexttimetospawn_default) )  )
-- 			spawndata.nexttimetospawndata.nexttimetospawnBase = math.floor(self.nexttimetospawnBase_default + ( diff_percent * (self.nexttimetospawnBase_warm - self.nexttimetospawnBase_default) )  )
-- 			glowflycapdata.glowflycap = math.floor(glowflycapdata.glowflycap_default + ( diff_percent * (self.glowflycap_warm - self.glowflycap_default) )  )
-- 			spawndata.timetospawn = math.min(spawndata.timetospawn, self.nexttimetospawnBase+ math.random()*self.nexttimetospawn )

-- 		elseif season_percent > 0.88 then

-- 			if not self.inst.glowflycocoontask then

-- 				--self.inst.glowflycocoontask, self.inst.glowflycocoontaskinfo = self.inst:ResumeTask(2* TUNING.SEG_TIME +   (math.random()*TUNING.SEG_TIME*2), function() self:startCocoonTimer() end)
-- 				self:Setglowflycocoontask(self.inst, 2* TUNING.SEG_TIME +   (math.random()*TUNING.SEG_TIME*2))
-- 			end
-- 		end

--         -- 如果世界状态为夏天(繁茂季)
-- 		if _world.state.issummer and not self.nocycle then

-- 			if not self.inst.glowflyhatchtask then
-- 				--self.inst.glowflyhatchtask, self.inst.glowflyhatchtaskinfo = self.inst:ResumeTask(, function() GetWorld():PushEvent("glowflyhatch") end)
-- 				self:Setglowflyhatchtask(self.inst, 5)
-- 			end

-- 			if glowflycapdata.glowflycap ~= glowflycapdata.glowflycap_cold then
-- 				print("END GLOWFLY EXPLOSION")
-- 				spawndata.nexttimetospawndata.nexttimetospawn = spawndata.nexttimetospawndata.nexttimetospawn_cold
-- 				spawndata.nexttimetospawndata.nexttimetospawnBase = spawndata.nexttimetospawndata.nexttimetospawnBase_cold
-- 				glowflycapdata.glowflycap = glowflycapdata.glowflycap_cold
-- 				spawndata.timetospawn = 0
-- 			end

--         elseif glowflycapdata.glowflycap ~= glowflycapdata.glowflycap_default then
-- 			print("GLOWFLIES RETURN TO NORMAL", glowflycapdata.glowflycap, glowflycapdata.glowflycap_default)
-- 			spawndata.nexttimetospawndata.nexttimetospawn =  spawndata.nexttimetospawndata.nexttimetospawn_default
-- 			spawndata.nexttimetospawndata.nexttimetospawnBase =  spawndata.nexttimetospawndata.nexttimetospawnBase_default
-- 			glowflycapdata.glowflycap = glowflycapdata.glowflycap_default
-- 		end
-- 	end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	local data ={
		timetospawn = spawndata.timetospawn,
		nexttimetospawn = spawndata.nexttimetospawndata.nexttimetospawn,
		nexttimetospawnBase =  spawndata.nexttimetospawndata.nexttimetospawnBase,
    	glowflycap = glowflycapdata.glowflycap,
    	nocycle = glowflycapdata.nocycle,
	}

	if self.glowflycocoontask then
		data.glowflycocoontask = self.inst:TimeRemainingInTask(self.inst.glowflycocoontaskinfo)
	end

	if self.glowflyhatchtask then
		data.glowflyhatchtask = self.inst:TimeRemainingInTask(self.inst.glowflyhatchtaskinfo)
	end

	return data
end

function self:OnLoad(data)
    if data ~= nil then
        self.nocycle = data.nocycle
        spawndata.timetospawn = data.timetospawn or 10
        spawndata.nexttimetospawndata.nexttimetospawn = data.nexttimetospawn or 10
        glowflycapdata.glowflycap = data.glowflycap or 4

        if data.glowflycocoontask then
            SetGlowflyCocoontask(self.inst, data.glowflycocoontask)
        end

        if data.glowflyhatchtask then
            SetGlowflyhatchtask(self.inst, data.glowflyhatchtask)
        end
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local numglowflys = 0
    for k, v in pairs(glowflys) do
        numglowflys = numglowflys + 1
    end
    return string.format("updating:%s butterflies:%d/%d", tostring(_updating), numglowflys, numglowflys)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
