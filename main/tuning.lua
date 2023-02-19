GLOBAL.setfenv(1, GLOBAL)

local seg_time = TUNING.SEG_TIME
local day_time = TUNING.DAY_SEGS_DEFAULT * seg_time
local dusk_time = TUNING.DUSK_SEGS_DEFAULT * seg_time
local night_time = TUNING.NIGHT_SEGS_DEFAULT * seg_time
local total_day_time = TUNING.TOTAL_DAY_TIME

local wilson_attack = TUNING.SPEAR_DAMAGE
local wilson_health = TUNING.WILSON_HEALTH

local tuning = {

    WALKING_STICK_PERISHTIME = total_day_time*3,
    WALKING_STICK_SPEED_MULT = 1.3,
    WALKING_STICK_DAMAGE = wilson_attack*.6,

    HALBERD_DAMAGE = wilson_attack*1.3,
    HALBERD_USES = 100,

    CORK_BAT_DAMAGE = wilson_attack * 1.75,
    CORK_BAT_USES = 33,

    FLYTRAP_CHILD_HEALTH = 250,
    FLYTRAP_CHILD_DAMAGE = 15,
    FLYTRAP_CHILD_SPEED = 4,

    FLYTRAP_TARGET_DIST = 8,
    FLYTRAP_KEEP_TARGET_DIST= 15,
    FLYTRAP_ATTACK_PERIOD =3,
    FLYTRAP_TEEN_HEALTH = 300,
    FLYTRAP_TEEN_DAMAGE = 20,
    FLYTRAP_TEEN_SPEED = 3.5,
    FLYTRAP_HEALTH = 350,
    FLYTRAP_DAMAGE = 25,
    FLYTRAP_SPEED = 3,

    ADULT_FLYTRAP_HEALTH = 400,
    ADULT_FLYTRAP_DAMAGE = 30,
    ADULT_FLYTRAP_ATTACK_PERIOD = 5,
    ADULT_FLYTRAP_ATTACK_DIST = 4,
    ADULT_FLYTRAP_STOPATTACK_DIST = 6,

    POG_ATTACK_RANGE = 3,
    POG_MELEE_RANGE = 2.5,
    POG_TARGET_DIST = 25,
    POG_WALK_SPEED = 2,
    POG_RUN_SPEED = 4.5,
    POG_DAMAGE = 25,
    POG_HEALTH = 150,
    POG_ATTACK_PERIOD = 2,
    POG_REGEN_TIME = total_day_time * 20,
    POG_RELEASE_TIME = 5,
    POG_MAX = 2,
    MIN_POGNAP_INTERVAL = 30,
    MAX_POGNAP_INTERVAL = 120,
    MIN_POGNAP_LENGTH = 20,
    MAX_POGNAP_LENGTH = 40,
    POG_LOYALTY_MAXTIME = total_day_time,
    POG_LOYALTY_PER_ITEM = total_day_time*.1,
    POG_EAT_DELAY = 0.5,
    POG_SEE_FOOD = 30,

    RABID_BEETLE_HEALTH = 60,
    RABID_BEETLE_DAMAGE =  10,
    RABID_BEETLE_ATTACK_PERIOD = 2,
    RABID_BEETLE_TARGET_DIST = 20,
    RABID_BEETLE_SPEED = 12,
    RABID_BEETLE_FOLLOWER_TARGET_DIST = 10,
    RABID_BEETLE_FOLLOWER_TARGET_KEEP = 20,

    HONEY_CHEST_MINE = 6,
    HONEY_CHEST_MINE_MED = 4,
    HONEY_CHEST_MINE_LOW = 2,

    HONEY_LANTERN_MINE = 6,
    HONEY_LANTERN_MINE_MED = 4,
    HONEY_LANTERN_MINE_LOW = 2,

    ANTMAN_DAMAGE = wilson_attack * 2/3,
    ANTMAN_HEALTH = 250,
    ANTMAN_ATTACK_PERIOD = 3,
    ANTMAN_TARGET_DIST = 16,
    ANTMAN_LOYALTY_MAXTIME = 2.5*total_day_time,
    ANTMAN_LOYALTY_PER_HUNGER = total_day_time/25,
    ANTMAN_MIN_POOP_PERIOD = seg_time * .5,
    ANTMAN_RUN_SPEED = 5,
    ANTMAN_WALK_SPEED = 3,
    ANTMAN_MIN = 3,
    ANTMAN_MAX = 4,
    ANTMAN_REGEN_TIME = seg_time * 4,
    ANTMAN_RELEASE_TIME = seg_time,

    ANTMAN_ATTACK_ON_SIGHT_DIST = 4,
    ANTMAN_WARRIOR_DAMAGE = wilson_attack * 1.25,
    ANTMAN_WARRIOR_HEALTH = 300,
    ANTMAN_WARRIOR_ATTACK_PERIOD = 3,
    ANTMAN_WARRIOR_TARGET_DIST = 16,
    ANTMAN_WARRIOR_RUN_SPEED = 7,
    ANTMAN_WARRIOR_WALK_SPEED = 3.5,
    ANTMAN_WARRIOR_REGEN_TIME = seg_time,
    ANTMAN_WARRIOR_RELEASE_TIME = seg_time,
    ANTMAN_WARRIOR_ATTACK_ON_SIGHT_DIST = 8,
    ANTMAN_SHARE_TARGET_RANGE = 30,

    GIANT_GRUB_WALK_SPEED = 2,
    GIANT_GRUB_DAMAGE = 44,
    GIANT_GRUB_HEALTH = 600,
    GIANT_GRUB_ATTACK_PERIOD = 3,
    GIANT_GRUB_ATTACK_RANGE = 3,

    GLOWFLY_COCOON_HEALTH = 300,
    GLOWFLY_WALK_SPEED = 6,
    GLOWFLY_RUN_SPEED = 5,

    PIKO_HEALTH = 100,
    PIKO_RESPAWN_TIME = day_time*4,
    PIKO_RUN_SPEED = 4,
    PIKO_DAMAGE = 2,
    PIKO_ATTACK_PERIOD = 2,
    PIKO_TARGET_DIST = 20,
    PIKO_RABID_SANITY_THRESHOLD = 0.8,

    SNAKE_SPEED = 3,
    SNAKE_HEALTH = 100,
    SNAKE_DAMAGE = 10,
    SNAKE_ATTACK_PERIOD = 3,
    SNAKE_TARGET_DIST = 8,
    SNAKE_KEEP_TARGET_DIST= 15,
    SNAKE_POISON_START_DAY = 3, -- the day that poison snakes have a chance to show up
    SNAKE_JUNGLETREE_CHANCE = 0.5, -- chance of a normal snake
    SNAKE_JUNGLETREE_AMOUNT_TALL = 2, -- num of times to try and spawn a snake from a tall tree
    SNAKE_JUNGLETREE_AMOUNT_MED = 1, -- num of times to try and spawn a snake from a normal tree
    SNAKE_JUNGLETREE_AMOUNT_SMALL = 1, -- num of times to try and spawn a snake from a small tree

    SCORPION_WALK_SPEED = 3,
    SCORPION_RUN_SPEED = 5,
    SCORPION_HEALTH = 200,
    SCORPION_DAMAGE = 20,
    SCORPION_ATTACK_PERIOD = 3,
    SCORPION_ATTACK_RANGE = 3,
    SCORPION_FLAMMABILITY = .33,
    SCORPION_TARGET_DIST = 4,
    SCORPION_INVESTIGATETARGET_DIST = 6,
    SCORPION_STING_RANGE = 2,

    --grabbing_vine
    GRABBING_VINE_WALKSPEED = 4,
    GRABBING_VINE_RUNSPEED = 8,
    GRABBING_VINE_HEALTH = 100,
    GRABBING_VINE_DAMAGE = 10,
    GRABBING_VINE_ATTACK_PERIOD = 1,
    GRABBING_VINE_TARGET_DIST = 3,
    GRABBING_VINE_RANGE = 3,
    GRABBING_VINE_HITRANGE = 4,

    JUNGLETREE_GROW_TIME =
    {
        {base=4.5*day_time, random=0.5*day_time},   --tall to short
        {base=8*day_time, random=5*day_time},   --short to normal
        {base=8*day_time, random=5*day_time},   --normal to tall
    },

    SPAWN_ANTQUEEN = true,
    ANTQUEEN_HEALTH = 3500,
    ANTQUEEN_SPAWN_COUNT = 0,

    -- standard poison vars
    VENOM_GLAND_DAMAGE = 75,
    VENOM_GLAND_MIN_HEALTH = 5,

    TEATREE_REGROWTH_TIME_MULT = 1,
    TUBERTREE_REGROWTH_TIME_MULT = 1,
    RAINFORESTTREE_REGROWTH_TIME_MULT = 1,

    --appeasementvalue
    WRATH_SMALL = -8,
    APPEASEMENT_TINY = 4,

    GAS_DAMAGE_PER_INTERVAL = 5, -- the amount of health damage gas causes per interval
    GAS_INTERVAL = 1, -- how frequently damage is applied
}

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end