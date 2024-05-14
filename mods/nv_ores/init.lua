--[[
NV Ores implements ores and stones for Nodeverse.

Included files:
    nodetypes.lua       Node definitions and registration
    itemtypes.lua       Dropped items are defined here
    other               Each file contains definitions for one kind of geological structure

 # INDEX
]]--

nv_ores = {}

dofile(minetest.get_modpath("nv_ores") .. "/nodetypes.lua")
dofile(minetest.get_modpath("nv_ores") .. "/itemtypes.lua")
dofile(minetest.get_modpath("nv_ores") .. "/large_veins.lua")
dofile(minetest.get_modpath("nv_ores") .. "/surface_deposits.lua")

if minetest.register_mapgen_script then
    minetest.register_mapgen_script(minetest.get_modpath("nv_ores") .. "/mapgen.lua")
else
    dofile(minetest.get_modpath("nv_ores") .. "/mapgen.lua")
end

local function get_plant_meta(seed, index)
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local ore_type_handler = nil
    ore_type_handler = "large_vein"
    local translation = {
        large_vein = nv_ores.get_large_vein_meta,
    }
    ore_type_handler = translation[ore_type_handler]
    return ore_type_handler(seed, index)
end

local function ore_handler(seed)
    local G = PcgRandom(seed, seed)
    local meta = generate_planet_metadata(seed)
    local ore_count = 0
    ore_count = G:next(15, 50)
    local r = {}
    for index=1,ore_count,1 do
        local ore_meta = get_ore_meta(seed, index)
        table.insert(r, {
            density = ore_meta.density,
            seed = ore_meta.seed,
            side = ore_meta.side,
            order = ore_meta.order,
            callback = ore_meta.callback,
            custom = ore_meta
        })
    end
    if meta.atmosphere == "scorching" or meta.atmosphere == "freezing" then
        local deposit_meta = nv_ores.get_surface_deposit_meta(seed, 0)
        table.insert(r, {
            density = deposit_meta.density,
            seed = deposit_meta.seed,
            side = deposit_meta.side,
            order = deposit_meta.order,
            callback = deposit_meta.callback,
            custom = deposit_meta
        })
    end
    return r
end

nv_ores.get_planet_ores = ore_handler
