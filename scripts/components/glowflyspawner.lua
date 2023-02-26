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
local _seasonprogress = _worldstate.seasonprogress

local _updating = false

local numglowflys = 0

local _activeplayers = {}
local _scheduledtasks = {}

local glowflys = {}

local prefab = "glowfly"

local glowflydata = {
    glowfly_amount = TUNING.GDEFAULT_GLOWFLY,

    glowfly_amount_default = TUNING.DEFAULT_GLOWFLY,

    glowfly_amount_max = TUNING.MAX_GLOWFLY,

    glowfly_amount_min = TUNING.MIN_GLOWFLY
}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

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

local function StartCocoonTimer()
	glowflydata.glowfly_amount = glowflydata.glowfly_amount_min

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

    if #glowflys < glowflydata.glowfly_amount then
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
    if _seasonprogress.isautumn > 0.88 then
        if not self.inst.glowflycocoontask then
            SetGlowflyCocoontask(self.inst, 2 * TUNING.SEG_TIME +   (math.random() * TUNING.SEG_TIME * 2))
        end
    end
end

local function Glowflyhatch()
    if not self.inst.glowflyhatchtask then
        SetGlowflyhatchtask(self.inst, 5)
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
    if glowflydata.glowfly_amount > 0 then
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
    	glowfly_amount = glowflydata.glowfly_amount,
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
        glowflydata.glowfly_amount = data.glowfly_amount or TUNING.DEFAULT_GLOWFLY

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
