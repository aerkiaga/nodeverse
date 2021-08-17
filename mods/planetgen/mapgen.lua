--[[
This is the main file for the map generator.
Included files:
    util.lua            Probability distribution and math functions
    meta.lua            Generates global characteristics of a planet from a seed
    nodetypes.lua       Registers custom nodes for a new planet
    pass_elevation.lua  First pass: terrain elevation and layers, oceans
    pass_caves.lua      Second pass: caves

Files are tagged with keywords throughout to make jumping to important places
easier. In order to jump to a tag, simply search '# TAG NAME' in your editor or
IDE and jump to the one match. At the start of each file there is an INDEX with
a list of all tags in order.

 # INDEX
    ENTRY POINT
    INITIALIZATION
--]]

dofile(minetest.get_modpath("planetgen") .. "/util.lua")
dofile(minetest.get_modpath("planetgen") .. "/meta.lua")
dofile(minetest.get_modpath("planetgen") .. "/nodetypes.lua")
dofile(minetest.get_modpath("planetgen") .. "/pass_elevation.lua")
dofile(minetest.get_modpath("planetgen") .. "/pass_caves.lua")

-- Minimum and maximum height for a planet
-- Should be avoided in favor of storing the vertical bounds of each planet
-- TODO: store vertical bounds of planets
PLANET_MINY = -4000
PLANET_MAXY = 3999

--[[
Contains a list of all current mappings between chunk coordinate rectangles
and the same region on a planet with some seed. Entry format is:
    minchunk    starting x and z chunk coordinates
    maxchunk    ending x and z chunk coordinates
    seed        planet seed; each seed represents a unique planet
TODO: store chunk offset to generate a specific planet chunk anywhere
]]--
planet_list = {
}

function clear_planet_area(planet)
    minp = {x=planet.minchunk.x*80, y=PLANET_MINY, z=planet.minchunk.z*80}
    maxp = {x=planet.maxchunk.x*80+79, y=PLANET_MAXY, z=planet.maxchunk.z*80+79}
    minetest.delete_area(minp, maxp)
end

-- API
function add_planet(planet)
    generate_planet_metadata(planet)
    register_planet_nodes(planet)
    table.insert(planet_list, planet)
    clear_planet_area(planet)
    return #planet_list
end

-- API
function remove_planet(index)
    clear_planet_area(planet_list[index])
    unregister_planet_nodes(planet)
    table.remove(planet_list, index)
end

function generate_planet_chunk(minp, maxp, area, A, A2, planet)
    pass_elevation(minp, maxp, area, A, A2, planet)
    pass_caves(minp, maxp, area, A, A2, planet)
    -- Apply random texture rotation to all supported nodes
    for i in area:iter(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z) do
        pos = area:position(i)

        rot = random_yrot_nodes[A[i]]
        if rot ~= nil then
            hash = pos.x + pos.y*0x10 + pos.z*0x100
            hash = int_hash(hash)
            A2[i] = hash % 133757 % rot
            if rot == 2 then
                A2[i] = A2[i] * 2
            end
        else
            A2[i] = 0
        end
    end
end

--[[
# ENTRY POINT
]]--

function mapgen_callback(minp, maxp, blockseed)
    local VM, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    local A = VM:get_data()
    local A2 = VM:get_param2_data()

    local minchunk = {x=math.floor(minp.x/80), z=math.floor(minp.z/80)}
    local maxchunk = {x=math.floor(maxp.x/80), z=math.floor(maxp.z/80)}

    -- Find planet(s) for the generated region
    for key, planet in pairs(planet_list) do
        commonmin = {x=math.max(minp.x, planet.minchunk.x*80), y=minp.y, z=math.max(minp.z, planet.minchunk.z*80)}
        commonmax = {x=math.min(maxp.x, planet.maxchunk.x*80+79), y=maxp.y, z=math.min(maxp.z, planet.maxchunk.z*80+79)}
        if commonmax.x >= commonmin.x and commonmax.z >= commonmin.z then
            generate_planet_chunk(commonmin, commonmax, area, A, A2, planet)
        end
    end
    VM:set_data(A)
    VM:set_param2_data(A2)
    VM:calc_lighting()
    VM:write_to_map()
end

--[[
# INITIALIZATION
]]--

minetest.register_on_generated(mapgen_callback)

-- Nodes defined only to avoid errors from mapgens

minetest.register_node('planetgen:stone', {
    drawtype = "normal",
    visual_scale = 1.0,
    tiles = {
        "stone.png"
    },
    paramtype2 = "facedir",
    place_param2 = 8,
})
minetest.register_alias('mapgen_stone', 'planetgen:stone')

minetest.register_node('planetgen:water_source', {
    drawtype = "liquid",
    visual_scale = 1.0,
    tiles = {
        "liquid.png"
    },
    paramtype2 = "facedir",
    place_param2 = 8,
})
minetest.register_alias('mapgen_water_source', 'planetgen:water_source')

--[[
Dictionary, maps node IDs to random texture rotation modulo.
See 'generate_planet_chunk' in this file. Sensible values are:
    nil     No entry, random rotation disabled
    1       Effectively equivalent to 'nil'
    2       Rotate some blocks 90 deg around +Y vector
    4       Rotate all blocks a random multiple of 90 deg around +Y vector
    24      Rotate all blocks randomly around all axes
Here, add random texture rotation around Y axis to dummy stone block
]]--

random_yrot_nodes = {
    [minetest.get_content_id('planetgen:stone')] = 4
}

--[[
The following is some test code to try to generate some sample planets. It
generates 16 planets in a 4x4 pattern around the origin, each planet filling a 1
chunk wide square.
]]

add_planet {
    minchunk = {x=0, z=0},
    maxchunk = {x=0, z=0},
    seed=56748364,
}

add_planet {
    minchunk = {x=-1, z=0},
    maxchunk = {x=-1, z=0},
    seed=6592659,
}

add_planet {
    minchunk = {x=-1, z=-1},
    maxchunk = {x=-1, z=-1},
    seed=7603769,
}

add_planet {
    minchunk = {x=0, z=-1},
    maxchunk = {x=0, z=-1},
    seed=756037595639,
}
add_planet {
    minchunk = {x=1, z=0},
    maxchunk = {x=1, z=0},
    seed=65926595629574,
}
add_planet {
    minchunk = {x=1, z=1},
    maxchunk = {x=1, z=1},
    seed=6596593619576837,
}
add_planet {
    minchunk = {x=0, z=1},
    maxchunk = {x=0, z=1},
    seed=658923648967494674,
}
add_planet {
    minchunk = {x=-1, z=1},
    maxchunk = {x=-1, z=1},
    seed=6593265946295,
}
add_planet {
    minchunk = {x=1, z=-1},
    maxchunk = {x=1, z=-1},
    seed=7693658956382957582,
}
add_planet {
    minchunk = {x=1, z=-2},
    maxchunk = {x=1, z=-2},
    seed=6583658565638,
}
add_planet {
    minchunk = {x=0, z=-2},
    maxchunk = {x=0, z=-2},
    seed=65893684523769,
}
add_planet {
    minchunk = {x=-1, z=-2},
    maxchunk = {x=-1, z=-2},
    seed=6436786754367,
}
add_planet {
    minchunk = {x=-2, z=-2},
    maxchunk = {x=-2, z=-2},
    seed=65746746745367567,
}
add_planet {
    minchunk = {x=-2, z=-1},
    maxchunk = {x=-2, z=-1},
    seed=532642675436734,
}
add_planet {
    minchunk = {x=-2, z=0},
    maxchunk = {x=-2, z=0},
    seed=5725623757825632,
}
add_planet {
    minchunk = {x=-2, z=1},
    maxchunk = {x=-2, z=1},
    seed=4521573274389547,
}
