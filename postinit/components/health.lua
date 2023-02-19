local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Health = require("components/health")

function Health:DoGasDamage(amount, doer)
	if not self.invincible and self.vulnerabletogasdamage and self.gas_damage_scale > 0 then
		if amount > 0 then
			self:DoDelta(-amount * self.gas_damage_scale, false, "gas")
		end
	end
end

PLENV.AddComponentPostInit("health", function(self)
	-- gas damage
	self.vulnerabletogasdamage = true
	self.gas_damage_scale = 1
end)
