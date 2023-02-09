name = "PorkLand_Prefabs"
description = ""
author = "Kivi"
version = "0.2"

forumthread = ""

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

-- Can specify a custom icon for this mod!

-- Specify compatibility with the game!
dont_starve_compatible = true
reign_of_giants_compatible = true
dst_compatible = true

all_clients_require_mod = true
clients_only_mod = false

mod_dependencies = {
    {  -- GEMCORE
        workshop = "workshop-1378549454",
        ["GemCore"] = false,
        ["[API] Gem Core - GitLab Version"] = true,
    },
}
