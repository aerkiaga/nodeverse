--[[
NV Game adds playable content to Nodeverse. It's the top-level mod that depends
on other NV mods. 

 # INDEX
    MAPGEN SETUP
    SHIPS SETUP
]]--

dofile(minetest.get_modpath("nv_game") .. "/nodetypes.lua")

--[[
 # MAPGEN SETUP
]]

local block_size = 300
local planets_per_block = 4
local planet_size = 60

local function new_area_callback(minp, maxp, area, A, A1, A2)
    local world_seed = minetest.get_mapgen_setting("seed") % 65536
    local planet_mapping = {
        minp = minp,
        maxp = maxp,
        offset = {x=0, y=0, z=0},
        seed = world_seed,
        walled = false
    }
    nv_planetgen.generate_planet_chunk(
        minp, maxp, area, A, A1, A2, planet_mapping
    )
end

nv_planetgen.register_on_not_generated(new_area_callback)

-- Remove default starting planet
nv_planetgen.remove_planet_mapping(1)

--[[
 # SHIPS SETUP
]]

local default_ship = "0MAsingleplayerBAnFAEAEABAgAAABAgCABACAALAAUAAAAAXAUAAAbArAAAXAGBAAcAdBAAUA5BAATANCAATAgCAATAzCAAcAGDAAVAiDAAnv_ships:floor_hull4nv_ships:scaffold_hull5nv_ships:turbo_engine_hull6nv_ships:scaffold_hull6nv_ships:scaffold_edge_hull6nv_ships:landing_legnv_ships:seat_hull5nv_ships:glass_facenv_ships:glass_edgenv_ships:control_panel_hull6nv_ships:glass_vertex6AwAyA4BxCDBDCwEDEyFyDGDxHwHxIHI2EJExIHIxKIKwAAAAAAAACADAAADACAEAAAHAAAAAAAAADADAEAIAKABAAACABAAACAWANAVA"

nv_ships.set_default_ship(default_ship)


