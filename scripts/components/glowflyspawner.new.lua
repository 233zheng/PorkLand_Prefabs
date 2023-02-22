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
-- 获取季节进度
local _seasonprogress = _worldstate.seasonprogress
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
        -- 默认下一次生成时间
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
    -- 最多可生成四只
    glowflycap = 4,
    -- 默认数量
    glowflycap_default = 4,
    -- 
    glowflycap_warm = 10,
    -- 冷却生成数量
    glowflycap_cold = 0
}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

-- 获取玩家周围的可生成点
local function GetSpawnPoint(player)
	local rad = 25
    local mindistance = 36
	local x,y,z = player.Transform:GetWorldPosition()
    local MUST_TAGS = {'flower_rainforest'}
	local flowers = TheSim:FindEntities(x,y,z, rad, MUST_TAGS)

    for i, v in ipairs(flowers) do
        while v ~= nil and player:GetDistanceSqToInst(v) <= mindistance do
            table.remove(flowers, i)
            v = flowers[i]
        end
    end

    return next(flowers) ~= nil and flowers[math.random(1, #flowers)] or nil
end

local function SetBugCocoonTimer(inst)
	inst.SetCocoontask(inst)
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

-- 设置萤火虫茧孵化
local function SetGlowflyhatchtask(inst, time)
	inst.glowflyhatchtask, inst.glowflyhatchtaskinfo = inst:ResumeTask(time, function()
        _world:PushEvent("glowflyhatch")
    end)
end

-- 在玩家周围的生成萤火虫
local function SpawnGlowflyForPlayer(player, reschedule)
    -- 获取玩家坐标
    local pt = player:GetPosition()
    -- 半径
    local radius = 64
    local glowfly = SpawnPrefab(prefab)
    local spawnflower = GetSpawnPoint(player)
    -- 获取半径64内带有glowfly标签的实体
    local glowflys = TheSim:FindEntities(pt.x, pt.y, pt.z, radius, {"glowfly"})

    if #glowflys < spawndata.glowflycap then
        if spawnflower ~= nil then
            if glowfly.components.pollinator ~= nil then
                glowfly.components.pollinator:Pollinate(spawnflower)
            end
        end
        glowfly.components.homeseeker:SetHome(spawnflower)
        glowfly.Physics:Teleport(spawnflower.Transform:GetWorldPosition())
        glowfly.OnBorn(glowfly)
    end

    _scheduledtasks[player] = nil
    reschedule(player)
end

-- 萤火虫结茧
local function GlowflyCocoon()
    -- 如果世界状态为秋天(温和季)
    if _world.state.isautumn then
		if _seasonprogress.isautumn > 0.3 and _seasonprogress.isautumn <= 0.8 then
			-- the glowgly pop grows starting at 30% season time to 80% season time where it reaches the max.
			-- so basically it takes half the season to go from default to the humid season settings and reaches max 80% into the season.
            -- 发光的pop从30%的季节时间开始增长到80%的季节时间，达到最大值。
            -- 因此，基本上，从默认设置到潮湿的季节设置需要半个季节的时间，并且在该季节中达到最高80%。

            _seasonprogress.isautumn = _seasonprogress.isautumn + 0.2

			local diff_percent =  1 - math.sin(PI * _seasonprogress.isautumn)

            spawndata.nexttimetospawndata.nexttimetospawn = math.floor(spawndata.nexttimetospawndata.nexttimetospawn_default + ( diff_percent * (spawndata.nexttimetospawndata.nexttimetospawn_warm - spawndata.nexttimetospawndata.nexttimetospawn_default) )  )
			spawndata.nexttimetospawndata.nexttimetospawnBase = math.floor(spawndata.nexttimetospawndata.nexttimetospawnBase_default + ( diff_percent * (spawndata.nexttimetospawndata.nexttimetospawnBase_warm - spawndata.nexttimetospawndata.nexttimetospawnBase_default) )  )
			spawndata.timetospawn = math.min(spawndata.timetospawn, spawndata.nexttimetospawndata.nexttimetospawnBase+ math.random() * spawndata.nexttimetospawndata.nexttimetospawn )
            glowflycapdata.glowflycap = math.floor(glowflycapdata.glowflycap_default + ( diff_percent * (glowflycapdata.glowflycap_warm - glowflycapdata.glowflycap_default) )  )

            -- 是谁这么傻？这样写print，为什么不用string.format呢？？
            print("nexttimetospawn：" .. spawndata.nexttimetospawndata.nexttimetospawn)
            print("nexttimetospawnBase：" .. spawndata.nexttimetospawndata.nexttimetospawnBase)
            print("timetospawn：" .. spawndata.timetospawn)
            print("glowflycap：" .. glowflycapdata.glowflycap)

        elseif _seasonprogress.isautumn > 0.88 then

            if not self.inst.glowflycocoontask then
                SetGlowflyCocoontask(self.inst, 2* TUNING.SEG_TIME +   (math.random()*TUNING.SEG_TIME*2))
            end
        end
    end
end

-- 萤火虫结茧孵化
local function Glowflyhatch()
    -- 如果世界状态为夏天(繁茂季)
    if _world.state.issummer then

        if not self.inst.glowflyhatchtask then
            SetGlowflyhatchtask(self.inst, 5)
        end

        -- 如果当前最大可生成数等于冷却生成数
        -- END GLOWFLY EXPLOSION
        if glowflycapdata.glowflycap ~= glowflycapdata.glowflycap_cold then
            spawndata.nexttimetospawndata.nexttimetospawn = spawndata.nexttimetospawndata.nexttimetospawn_cold
            spawndata.nexttimetospawndata.nexttimetospawnBase = spawndata.nexttimetospawndata.nexttimetospawnBase_cold
            glowflycapdata.glowflycap = glowflycapdata.glowflycap_cold
            spawndata.timetospawn = 0
        end

    elseif glowflycapdata.glowflycap ~= glowflycapdata.glowflycap_default then
        print("恢复正常", glowflycapdata.glowflycap, glowflycapdata.glowflycap_default)
        spawndata.nexttimetospawndata.nexttimetospawn =  spawndata.nexttimetospawndata.nexttimetospawn_default
        spawndata.nexttimetospawndata.nexttimetospawnBase =  spawndata.nexttimetospawndata.nexttimetospawnBase_default
        glowflycapdata.glowflycap = glowflycapdata.glowflycap_default
    end
end

local function func(inst ,season)
    if season == "autumn" then
        GlowflyCocoon()    
    elseif season == "summer" then
        Glowflyhatch()
    end
end

-- 计划在玩家周围生成
local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil then
        local basedelay = initialspawn and 0.3 or 10
        _scheduledtasks[player] = player:DoTaskInTime(basedelay + math.random() * 10, SpawnGlowflyForPlayer, ScheduleSpawn)
    end
end

-- 取消生成
local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

-- 切换生成
local function ToggleUpdate(force)
    if spawndata.glowflycap > 0 then
        if not _updating then
            _updating = true
            for k, v in ipairs(_activeplayers) do
                ScheduleSpawn(v, true)
            end
        elseif force then
            for k, v in ipairs(_activeplayers) do
                CancelSpawn(v)
                ScheduleSpawn(v, true)
            end
        end
    elseif _updating then
        _updating = true
        for k, v in ipairs(_activeplayers) do
            CancelSpawn(v)
        end
    end
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

-- 在萤火虫离开玩家加载范围时，自动移除萤火虫
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
inst:WatchWorldState("isautumn", GlowflyCocoon)
inst:WatchWorldState("issummer", Glowflyhatch)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

ToggleUpdate(true)

inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

-- function self:OnPostInit()
--     ToggleUpdate(true)
-- end

--------------------------------------------------------------------------
--[[ Public getters and setters ]]
--------------------------------------------------------------------------

function self:Setglowfly(prefab)
    prefab = prefab
end

function self:StartTrackingFn(inst)
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

function self:StartTracking(glowfly)
    self:StartTrackingFn(glowfly)
end

function self:StopTrackingFn(inst)
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

function self:StopTracking(glowfly)
    self:StopTrackingFn(glowfly)
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

    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    for k, v in pairs(glowflys) do
        numglowflys = numglowflys + 1
    end
    return string.format("updating:%s numglowflys:%d/%d", tostring(_updating), numglowflys, numglowflys)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
