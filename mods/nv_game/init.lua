--[[
NV Game adds playable content to Nodeverse. It's the top-level mod that depends
on other NV mods. 

 # INDEX
    SHIPS SETUP
    UNIVERSE SETUP
]]--

dofile(minetest.get_modpath("nv_game") .. "/nodetypes.lua")

-- Remove default starting planet
nv_planetgen.remove_planet_mapping(1)

--[[
 # SHIPS SETUP
]]

local default_ship = "0MAsingleplayerBAnFAEAEABAgAAABAgCABACAALA________UAAAAAXAUAAAbArAAAXAGBAAcAdBAAUA5BAATANCAATAgCAATAzCAAcAGDAAVAiDAAnv_ships:floor_hull4nv_ships:scaffold_hull5nv_ships:turbo_engine_hull6nv_ships:scaffold_hull6nv_ships:scaffold_edge_hull6nv_ships:landing_legnv_ships:seat_hull5nv_ships:glass_facenv_ships:glass_edgenv_ships:control_panel_hull6nv_ships:glass_vertex6AwAyA4BxCDBDCwEDEyFyDGDxHwHxIHI2EJExIHIxKIKwAAAAAAAACADAAADACAEAAAHAAAAAAAAADADAEAIAKABAAACABAAACAWANAVA"

nv_ships.set_default_ship(default_ship)

--[[
 # DEFAULT TOOL
]]

minetest.register_item(":", {
	type = "none",
	wield_image = "wieldhand.png",
	wield_scale = {x=1,y=1,z=2.5},
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
		groupcaps={
            crumbly={maxlevel=1, times={[1]=1.30, [2]=0.80, [3]=0.50}},
            cracky={maxlevel=1, times={[1]=2.50, [2]=2.00, [3]=1.50}},
            snappy={maxlevel=1, times={[1]=0.60, [2]=0.40, [3]=0.20}},
            choppy={maxlevel=1, times={[1]=2.10, [2]=1.80, [3]=1.20}},
        },
		damage_groups = {fleshy=1},
	}
})

--[[
 # UNIVERSE SETUP
]]

local visited_planets = {}
local function post_processing_callback(planet_mapping, area, A, A1, A2)
    local G = PcgRandom(planet_mapping.seed, planet_mapping.seed)
    local loot_x = G:next(-100, 100)
    local loot_z = G:next(-100, 100)
    if loot_x < planet_mapping.minp.x or loot_x > planet_mapping.maxp.x
    or loot_z < planet_mapping.minp.z or loot_z > planet_mapping.maxp.z then
        return
    end
    for _, seed in ipairs(visited_planets) do
        if seed == planet_mapping.seed then
            return
        end
    end
    local meta = generate_planet_metadata(planet_mapping.seed)
    nv_planetgen.choose_planet_nodes_and_colors(meta)
    for y=planet_mapping.maxp.y,planet_mapping.minp.y,-1 do
        local i = area:index(loot_x, y, loot_z)
        local node = A[i]
        if node == meta.node_types.dust
        or node == meta.node_types.sediment
        or node == meta.node_types.grass_soil
        or node == meta.node_types.ice then
            if y < planet_mapping.maxp.y then
                i = area:index(loot_x, y + 1, loot_z)
            end
            A[i] = minetest.get_content_id("nv_game:pinata")
            A2[i] = A2[i] % 4
            table.insert(visited_planets, planet_mapping.seed)
        end
    end
end

nv_universe.register_post_processing(post_processing_callback)
