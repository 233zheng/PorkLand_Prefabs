require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.GOHOME, "action"),
}

local events = {
    EventHandler("cocoon", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst:RemoveTag("wantstococoon")
            inst.ChangeToCocoon(inst, false)
        end
    end),

    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("doattack", function(inst)
        if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("attack")
        end
    end),

    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),

    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),

    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
			local wants_to_move = inst.components.locomotor:WantsToMoveForward()
			if not inst.sg:HasStateTag("attack") then
				if wants_to_move then
					inst.sg:GoToState("moving")
				else
					inst.sg:GoToState("idle")
				end
			end
        end
    end),
}

local states = {
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
		    inst.SoundEmitter:PlaySound(inst.sounds.death)
            inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
			if inst.components.lootdropper ~= nil then
				inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			end
        end,

		events=
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "action",

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
            inst:PerformBufferedAction()
        end,

        events = {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", false)
        end,

        timeline= {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
        },

        events=
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("moving")
            end),
        }
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("walk_loop", false)
        end,

        timeline = {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/buzz") end),
        },

        events = {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "attack",
        tags = {"attack"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline = {
            TimeEvent(10*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.attack)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.components.combat:DoAttack()
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hit)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonStates.AddSleepStates(states, {
    starttimeline = {
        TimeEvent(23*FRAMES, function(inst)
            inst.SoundEmitter:KillSound("buzz")
        end)
    },
    waketimeline = {
        TimeEvent(1*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
        end)
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("glowfly", states, events, "idle", actionhandlers)

