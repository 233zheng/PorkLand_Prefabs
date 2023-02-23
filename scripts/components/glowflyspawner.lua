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
local _seasonprogress = _worldstate.seasonprogress

local _updating = false

local numglowflys = 0

local _activeplayers = {}
local _scheduledtasks = {}

local glowflys = {}

local prefab = "glowfly"

local spawndata = {

    timetospawn = 10,

    nexttimetospawndata = {
        nexttimetospawn = 10,
        nexttimetospawnBase = 10,

        nexttimetospawn_default = 10,
        nexttimetospawnBase_default = 10,

        nexttimetospawn_warm = 2,
        nexttimetospawnBase_warm = 0,

        nexttimetospawn_cold = 50,
        nexttimetospawnBase_cold = 50
    }
}

local glowflycapdata = {
    glowflycap = 4,

    glowflycap_default = 4,

    glowflycap_warm = 10,

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

local function SetGlowflyCocoontask(inst, time)
	inst.glowflycocoontask, inst.glowflycocoontaskinfo = inst:ResumeTask(time, function()
        StartCocoonTimer()
    end)
end

local function SetGlowflyhatchtask(inst, time)
	inst.glowflyhatchtask, inst.glowflyhatchtaskinfo = inst:ResumeTask(time, function()
        _world:PushEvent("glowflyhatch")
    end)
end

local function SpawnGlowflyForPlayer(player, reschedule)
    local pt = player:GetPosition()
    local radius = 64
    local glowfly = SpawnPrefab(prefab)
    local spawnflower = GetSpawnPoint(player)
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

local function GlowflyCocoon()
    if _seasonprogress.isautumn > 0.3 and _seasonprogress.isautumn <= 0.8 then
        -- the glowgly pop grows starting at 30% season time to 80% season time where it reaches the max.
        -- so basically it takes half the season to go from default to the humid season settings and reaches max 80% into the season.

        _seasonprogress.isautumn = _seasonprogress.isautumn + 0.2

        local diff_percent =  1 - math.sin(PI * _seasonprogress.isautumn)

        spawndata.nexttimetospawndata.nexttimetospawn = math.floor(spawndata.nexttimetospawndata.nexttimetospawn_default + ( diff_percent * (spawndata.nexttimetospawndata.nexttimetospawn_warm - spawndata.nexttimetospawndata.nexttimetospawn_default) )  )
        spawndata.nexttimetospawndata.nexttimetospawnBase = math.floor(spawndata.nexttimetospawndata.nexttimetospawnBase_default + ( diff_percent * (spawndata.nexttimetospawndata.nexttimetospawnBase_warm - spawndata.nexttimetospawndata.nexttimetospawnBase_default) )  )
        spawndata.timetospawn = math.min(spawndata.timetospawn, spawndata.nexttimetospawndata.nexttimetospawnBase+ math.random() * spawndata.nexttimetospawndata.nexttimetospawn )
        glowflycapdata.glowflycap = math.floor(glowflycapdata.glowflycap_default + ( diff_percent * (glowflycapdata.glowflycap_warm - glowflycapdata.glowflycap_default) )  )

    elseif _seasonprogress.isautumn > 0.88 then

        if not self.inst.glowflycocoontask then
            SetGlowflyCocoontask(self.inst, 2* TUNING.SEG_TIME +   (math.random()*TUNING.SEG_TIME*2))
        end
    end
end

local function Glowflyhatch()
    if not self.inst.glowflyhatchtask then
        SetGlowflyhatchtask(self.inst, 5)
    end

    if glowflycapdata.glowflycap ~= glowflycapdata.glowflycap_cold then
        spawndata.nexttimetospawndata.nexttimetospawn = spawndata.nexttimetospawndata.nexttimetospawn_cold
        spawndata.nexttimetospawndata.nexttimetospawnBase = spawndata.nexttimetospawndata.nexttimetospawnBase_cold
        glowflycapdata.glowflycap = glowflycapdata.glowflycap_cold
        spawndata.timetospawn = 0

    elseif glowflycapdata.glowflycap ~= glowflycapdata.glowflycap_default then
        print("恢复正常", glowflycapdata.glowflycap, glowflycapdata.glowflycap_default)
        spawndata.nexttimetospawndata.nexttimetospawn =  spawndata.nexttimetospawndata.nexttimetospawn_default
        spawndata.nexttimetospawndata.nexttimetospawnBase =  spawndata.nexttimetospawndata.nexttimetospawnBase_default
        glowflycapdata.glowflycap = glowflycapdata.glowflycap_default
    end
end

local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil then
        local basedelay = initialspawn and 0.3 or 10
        _scheduledtasks[player] = player:DoTaskInTime(basedelay + math.random() * 10, SpawnGlowflyForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

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

local function AutoRemoveTarget(inst, target)
    if glowflys[target] ~= nil and target:IsAsleep() then
        target:Remove()
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnGlowflySleep(target)
    inst:DoTaskInTime(0, AutoRemoveTarget, target)
end

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
-- inst:WatchWorldState("isautumn", GlowflyCocoon)
inst:WatchWorldState("iswinter", GlowflyCocoon)
inst:WatchWorldState("issummer", Glowflyhatch)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

ToggleUpdate(true)

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
