GLOBAL.setfenv(1, GLOBAL)

function ChangeToUndergroundCharacterPhysics(inst)
    local phy = inst.Physics
    phy:SetCollisionGroup(COLLISION.CHARACTERS)
    phy:ClearCollisionMask()
    phy:CollidesWith(COLLISION.WORLD)
    phy:CollidesWith(COLLISION.OBSTACLES)
    phy:CollidesWith(COLLISION.GROUND)
    return phy
end

function MakeAmphibiousCharacterPhysics(inst, mass, rad)
    local phy = inst.entity:AddPhysics()
    phy:SetMass(mass)
    phy:SetCapsule(rad, 1)
    phy:SetFriction(0)
    phy:SetDamping(5)
    phy:SetCollisionGroup(COLLISION.CHARACTERS)
    phy:ClearCollisionMask()
    phy:CollidesWith(COLLISION.OBSTACLES)
    phy:CollidesWith(COLLISION.CHARACTERS)
	-- phy:CollidesWith(COLLISION.WAVES)
    phy:CollidesWith(COLLISION.GROUND)
    return phy
end

function ANTLARVAPhysics(inst)
    local phy = inst.entity:AddPhysics()
    phy:SetMass(1)
    phy:SetCapsule(0.2, 0.2)
    phy:SetFriction(10)
    phy:SetDamping(5)
    phy:SetCollisionGroup(COLLISION.CHARACTERS)
    phy:ClearCollisionMask()
    phy:CollidesWith(COLLISION.WORLD)
    phy:CollidesWith(COLLISION.GROUND)
    return phy
end
