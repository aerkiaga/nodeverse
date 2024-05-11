--[[
NV Ores implements ores and stones for Nodeverse.

Included files:
    nodetypes.lua       Node definitions and registration
    other               Each file contains definitions for one kind of geological structure

 # INDEX
]]--

nv_ores = {}

dofile(minetest.get_modpath("nv_ores") .. "/large_veins.lua")
dofile(minetest.get_modpath("nv_ores") .. "/nodetypes.lua")

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
    if meta.life == "dead" then
        ore_count = G:next(10, 15)
    elseif meta.life == "lush" then
        ore_count = G:next(5, 10)
    end
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
    return r
end

nv_ores.get_planet_ores = ore_handler
