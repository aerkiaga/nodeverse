--[[
This is the regular environment API to the map generator.
Included files:
    util.lua            Probability distribution and math functions
    meta.lua            Generates global characteristics of a planet from a seed
    nodetypes.lua       Registers custom nodes for a new planet

 # INDEX
    INITIALIZATION
--]]

-- Namespace for all the API functions
nv_planetgen = {}

dofile(minetest.get_modpath("nv_planetgen") .. "/util.lua")
dofile(minetest.get_modpath("nv_planetgen") .. "/meta.lua")
dofile(minetest.get_modpath("nv_planetgen") .. "/nodetypes.lua")

--[[
Contains a list of all current mappings between chunk coordinate rectangles
and the same region on a planet with some seed. Entry format is:
    minp        starting x, y and z node coordinates
    maxp        ending x, y and z node coordinates
    offset      world position P will map to planet coordinates P + offset
    seed        planet seed; each seed represents a unique planet
    walled      (optional) builds stone walls around the mapped area
]]--
nv_planetgen.planet_mappings = {}
local planet_mappings = nv_planetgen.planet_mappings
minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.planet_mappings", minetest.serialize(planet_mappings))

--[[
Maps planet IDs (keys) to actual planet metadata tables (values).
]]--
nv_planetgen.planet_dictionary = {}
local planet_dictionary = nv_planetgen.planet_dictionary
minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.planet_dictionary", minetest.serialize(planet_dictionary))

function nv_planetgen.clear_planet_mapping_area(mapping)
    local minp = {x=mapping.minp.x, y=mapping.minp.y, z=mapping.minp.z}
    local maxp = {x=mapping.maxp.x, y=mapping.maxp.y, z=mapping.maxp.z}
    minetest.delete_area(minp, maxp)
end

local function planet_from_mapping(mapping)
    local planet = planet_dictionary[mapping.seed]
    if planet == nil then
        planet = generate_planet_metadata(mapping.seed)
        nv_planetgen.choose_planet_nodes_and_colors(planet)
        planet_dictionary[mapping.seed] = planet
        minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.planet_dictionary", minetest.serialize(planet_dictionary))
        planet.seed = mapping.seed
        planet.num_mappings = 1
    else
        planet.num_mappings = planet.num_mappings + 1
    end
    return planet
end

-- API
function nv_planetgen.add_planet_mapping(mapping)
    table.insert(planet_mappings, mapping)
    planet_from_mapping(mapping) -- Memoize and pass to mapgen env
    minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.planet_mappings", minetest.serialize(planet_mappings))
    return #planet_mappings
end

-- API
function nv_planetgen.remove_planet_mapping(index)
    local mapping = planet_mappings[index]
    local planet = planet_from_mapping(mapping)
    planet.num_mappings = planet.num_mappings - 1
    if planet.num_mappings == 0 then
        planet_dictionary[planet_mappings[index].seed] = nil
        minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.planet_dictionary", minetest.serialize(planet_dictionary))
    end
    minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.planet_mappings", minetest.serialize(planet_mappings))
    table.remove(planet_mappings, index)
end

--[[
Contains a list of all node metadata to add in the next emerge. Entry format is:
    pos         node position
    meta        metadata, as table
]]--
local meta_nodes = {}

-- API
function nv_planetgen.set_meta(pos, meta)
    table.insert(meta_nodes, {
        pos = pos,
        meta = meta,
    })
end

local registered_structures = {}
local function register_structure(seed, def)
    registered_structures[seed] = registered_structures[seed] or {}
    for n, structure in ipairs(registered_structures[seed]) do
        if structure.order > def.order then
            table.insert(registered_structures[seed], n, def)
            break
        end
    end
    table.insert(registered_structures[seed], def)
end

local structure_handlers = {}
-- The callback will get a seed and must return a list of structures
function nv_planetgen.register_structure_handler(callback)
    table.insert(structure_handlers, callback)
end

--[[
# INITIALIZATION
]]--

-- Nodes defined only to avoid errors from mapgens

minetest.register_node('nv_planetgen:stone', {
    drawtype = "normal",
    visual_scale = 1.0,
    tiles = {
        "nv_stone.png"
    },
    paramtype2 = "facedir",
    place_param2 = 8,
})
minetest.register_alias('mapgen_stone', 'nv_planetgen:stone')

minetest.register_node('nv_planetgen:water_source', {
    drawtype = "liquid",
    visual_scale = 1.0,
    tiles = {
        "nv_water.png"
    },
    paramtype2 = "facedir",
    place_param2 = 8,
})
minetest.register_alias('mapgen_water_source', 'nv_planetgen:water_source')

--[[
Dictionary, maps node IDs to random texture rotation modulo.
See 'pass_final.lua'. Sensible values are:
    nil     No entry, random rotation disabled
    1       Effectively equivalent to 'nil'
    2       Rotate some blocks 90 deg around +Y vector
    4       Rotate all blocks a random multiple of 90 deg around +Y vector
    24      Rotate all blocks randomly around all axes
Here, add random texture rotation around Y axis to dummy stone block
]]--

nv_planetgen.random_yrot_nodes = {
    [minetest.get_content_id('nv_planetgen:stone')] = 4
}

--[[
Dictionary, maps node IDs to color param2 multiplier.
See 'pass_final.lua'. Sensible values are:
    nil     No entry, equivalent to 1
    1       Useful for param2 = 'color'
    4       Useful for param2 = 'color4dir'
    8       Useful for param2 = 'colorwallmounted'
    32      Useful for param2 = 'colorfacedir' or 'colordegrotate'
Here, add random texture rotation around Y axis to dummy stone block
]]--

nv_planetgen.color_multiplier = {}

nv_planetgen.register_all_nodes()
minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.random_yrot_nodes", minetest.serialize(nv_planetgen.random_yrot_nodes))
minetest.safe_file_write(minetest.get_worldpath() .. "/nv_planetgen.color_multiplier", minetest.serialize(nv_planetgen.color_multiplier))
