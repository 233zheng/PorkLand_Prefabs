GLOBAL.setfenv(1, GLOBAL)

function GetAporkalypse()
    return false
end

function SilenceEvent(event, data, ...)
    return event.."_silenced", data
end

function EntityScript:AddPushEventPostFn(event, fn, source)
    source = source or self

    if not source.pushevent_postfn then
        source.pushevent_postfn = {}
    end

    source.pushevent_postfn[event] = fn
end

function CleanUpGlowFlies()
	-- one time cleanup of surplus glowflies.
	if TheWorld.culledGlowFlies then
		return
	end
	print("Cleaning up suprlus glowflies")
	local glowflies = {}
	for i,v in pairs(Ents) do
		if v.prefab == "glowfly" and not v:IsInLimbo() then
			table.insert(glowflies, v)
		end
	end
	local overage = #glowflies - 800
	if overage > 0 then
		glowflies = shuffleArray(glowflies)
		for i=1, overage do
			glowflies[i]:Remove()
		end
		print(string.format("Removed %d surplus glowflies",overage))
	end
	TheWorld.culledGlowFlies = true
end
