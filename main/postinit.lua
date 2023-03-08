local modimport = modimport

-- Update this list when adding files
local components_post = {
    "health",
    "eater",
    "inventory",
    "inventoryitem",
    "spawner",
    "plantregrowth",
    "equippable",
    "homeseeker",
}

local prefabs_post = {
    "player",
    "warningshadow",
    "meatrack"
}

local batch_prefabs_post = {
}

local scenarios_post = {
}

local stategraphs_post = {
    "wilson",
    "wilson_client",
}

local brains_post = {
}

local class_post = {
}

for _, file_name in ipairs(components_post) do
    modimport("postinit/components/" .. file_name)
end

for _, file_name in ipairs(prefabs_post) do
    modimport("postinit/prefabs/" .. file_name)
end

for _, file_name in ipairs(batch_prefabs_post) do
    modimport("postinit/batchprefabs/" .. file_name)
end

for _, file_name in ipairs(scenarios_post) do
    modimport("postinit/scenarios/" .. file_name)
end

for _, file_name in ipairs(stategraphs_post) do
    modimport("postinit/stategraphs/SG" .. file_name)
end

for _, file_name in ipairs(brains_post) do
    modimport("postinit/brains/" .. file_name)
end

for _, file_name in ipairs(class_post) do
    modimport("postinit/"  ..  file_name)
end
