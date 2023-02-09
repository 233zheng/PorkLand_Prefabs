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
