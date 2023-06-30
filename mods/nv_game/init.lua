--[[
NV Game adds playable content to Nodeverse. It's the top-level mod that depends
on other NV mods. 

 # INDEX
    MAPGEN SETUP
    SHIPS SETUP
]]--

dofile(minetest.get_modpath("nv_game") .. "/nodetypes.lua")

-- Remove default starting planet
nv_planetgen.remove_planet_mapping(1)

--[[
 # SHIPS SETUP
]]

local default_ship = "0MAsingleplayerBAnFAEAEABAgAAABAgCABACAALAAUAAAAAXAUAAAbArAAAXAGBAAcAdBAAUA5BAATANCAATAgCAATAzCAAcAGDAAVAiDAAnv_ships:floor_hull4nv_ships:scaffold_hull5nv_ships:turbo_engine_hull6nv_ships:scaffold_hull6nv_ships:scaffold_edge_hull6nv_ships:landing_legnv_ships:seat_hull5nv_ships:glass_facenv_ships:glass_edgenv_ships:control_panel_hull6nv_ships:glass_vertex6AwAyA4BxCDBDCwEDEyFyDGDxHwHxIHI2EJExIHIxKIKwAAAAAAAACADAAADACAEAAAHAAAAAAAAADADAEAIAKABAAACABAAACAWANAVA"

nv_ships.set_default_ship(default_ship)


