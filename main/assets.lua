local resolvefilepath = GLOBAL.resolvefilepath
local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "gold_dust",
    "antlarva",
    "adult_flytrap",
    "corkbat",
    "halberd",
    "mean_flytrap",
    "nectar_pod",
    "pog",
    "pog_spawner",
    "venus_stalk",
    "vine",
    "walkingstick",
    "chitin",
    "antman",
    "antman_warrior",
    "antman_warrior_egg",
    "antcombhome",
    "anthill_lamp",
    "giantgrub",
    "anthill_stalactite",
    "antqueen",
    "antqueen_throne",
    "antqueen_spawner",
    "pheromonestone",
    "rabid_beetle",
    "piko",
    "teatrees",
    "teatree_nut",
    "rainforesttrees",
    "scorpion",
    "snake_amphibious",
    "venomgland",
    "burr",
    "snakeoil",
    "snakeskin_scaly",
    "grabbing_vine",
    "hanging_vine",
    "tubertrees",
    "flower_rainforest",
}

Assets = {
    --Loading this here because the meatrack needs them
    Asset("ANIM", "anim/meat_rack_food_sw.zip"),

    Asset("ANIM", "anim/player_idles_poison.zip"),

}

-- AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/pl.fsb"))
    -- table.insert(Assets, Asset("SOUNDPACKAGE", "sound/pl.fev"))
end
