--[[
Planetgen defines a custom map generator that can map arbitrary areas of planets
with various seeds into any part of the world. It overrides map generation and
provides an API to control it from other mods or from within this file.

Read 'mapgen.lua' to learn how this works. For the API reference, keep reading
this file. To see or edit the default game setup, search '# GAME SETUP' in your
editor or IDE and jump to it.
]]--

dofile(minetest.get_modpath("planetgen") .. "/mapgen.lua")

--[[
# API REFERENCE
Planetgen is a configurable mapgen that can be used in many ways. The API it
offers can be used from this file (see GAME SETUP) and have this mod generate
custom terrain, or from a different mod to integrate it into a game.

All functions in the API must be prefixed with 'planetgen.' if used from a
different mod, while functions called from within this mod must not.

There are two basic ways to use this API. The simplest one is simply to call
'planetgen.add_planet_mapping()' at startup to place one or more planets at
certain locations in the world. These can be as large as necessary (e.g.
vertically stacked but filling the world horizontally), and many thousands of
planets can be created (e.g. 10k floating planets).

The second basic way to use the API is to register a callback function via
'planetgen.register_on_not_generated()', and within that generate new areas with
'planetgen.generate_planet_chunk()'. This allows one to generate an infinite
world with as many planets as desired, and add or remove planet areas
programmatically (e.g. to simulate a larger universe).

Coordinate format:
See https://minetest.gitlab.io/minetest/representations-of-simple-things/

Coordinate types:
https://minetest.gitlab.io/minetest/map-terminology-and-coordinates/
]]--

--[[    planetgen.register_on_not_generated(callback)
Registers a function that will be called whenever an area not mapped to any
planet has been unsuccessfully generated. This allows to generate the area via
'planetgen.generate_planet_chunk()', and/or manually generate custom content in
that area. 'planetgen.add_planet_mapping()' can also be called here to prevent
further calls to the callback for this area, but note that it does not
automatically call 'planetgen.generate_planet_chunk()'.
    callback    function (minp, maxp, area, A, A1, A2)
    Will be passed the extents of the unmapped area, as well as objects useful
    for overriding map generation.
        minp        starting x, y and z node coordinates
        maxp        ending x, y and z node coordinates
        area        value returned by Minetest's 'VoxelArea:new()'
        A           value returned by Minetest's 'VoxelManip:get_data()'
        A1          value returned by Minetest's 'VoxelManip:get_light_data()'
        A2          value returned by Minetest's 'VoxelManip:get_param2_data()'
]]

--[[    planetgen.add_planet_mapping(mapping)
Adds a mapping from a rectangular chunk-aligned region of the world to some
region in a "planet" with a certain seed, so that it generates terrain from that
planet upon following generation attemps. 'mapping' is a table containing:
    minp        starting x, y and z node coordinates
    maxp        ending x, y and z node coordinates
    offset      world position P will map to planet coordinates P + offset
    seed        planet seed; each seed represents a unique planet
    walled      (optional) builds stone walls around the mapped area
When this function is called with no other mappings to the same planet (seed),
all planet metadata is generated and node variants are chosen. This function can
be called either at startup or at any later time, as it performs no actual
registrations.
    Returns planet mapping index.
]]--

--[[    planetgen.remove_planet_mapping(index)
Removes a planet mapping from the list. The area mapped by it will be
immediately cleared and unloaded, and further attempts to load it will result in
the 'on not generated' callback being called, if registered (see
'planetgen.register_on_not_generated()').
    index       mapping index returned by 'planetgen.add_planet'
]]--

--[[    generate_planet_chunk(minp, maxp, area, A, A1, A2, mapping)
Uses the map generation code provided by this mod to generate planet terrain
within an area. The generated area will be the intersection of the boxes
delimited by [minp .. maxp] and [mapping.minp .. mapping.maxp].
    minp        starting x, y and z node coordinates
    maxp        ending x, y and z node coordinates
    area        value from 'on not generated' callback or 'VoxelArea:new()'
    A           value from 'on not generated' callback or 'VoxelArea:get_data()'
    A1          value from 'on not generated' callback or 'VoxelArea:get_light_data()'
    A2          value from 'on not generated' callback or 'VoxelArea:get_param2_data()'
    mapping     see 'planetgen.add_planet_mapping()' for format
]]

--[[
# GAME SETUP

Default game setup:
An infinite cloud of floating planets.
]]

block_size = 200
planets_per_block = 1
planet_size = 100

function new_area_callback(minp, maxp, area, A, A1, A2)
    -- Iterate over all overlapping block_size * block_size * block_size blocks
    for block_x=minp.x - minp.x%block_size, maxp.x - maxp.x%block_size, block_size do
        for block_y=minp.y - minp.y%block_size, maxp.y - maxp.y%block_size, block_size do
            for block_z=minp.z - minp.z%block_size, maxp.z - maxp.z%block_size, block_size do
                -- Get overlapping area
                local common_minp = {
                    x=math.max(minp.x, block_x),
                    y=math.max(minp.y, block_y),
                    z=math.max(minp.z, block_z)
                }
                local common_maxp = {
                    x=math.min(maxp.x, block_x + block_size - 1),
                    y=math.min(maxp.y, block_y + block_size - 1),
                    z=math.min(maxp.z, block_z + block_size - 1)
                }
                -- Check overlap with randomly placed planets
                local seed = block_x + 0x10*block_y + 0x1000*block_z
                local G = PcgRandom(seed, seed)
                for n=1, planets_per_block do
                    local planet_pos = {
                        x=block_x + G:next(math.ceil(planet_size/2), block_size - math.ceil(planet_size/2)),
                        y=block_y + G:next(math.ceil(planet_size/2), block_size - math.ceil(planet_size/2)),
                        z=block_z + G:next(math.ceil(planet_size/2), block_size - math.ceil(planet_size/2))
                    }
                    local planet_mapping = {
                        minp = {
                            x=planet_pos.x - math.floor(planet_size/2),
                            y=planet_pos.y - 4*math.floor(planet_size/2),
                            z=planet_pos.z - math.floor(planet_size/2),
                        },
                        maxp = {
                            x=planet_pos.x + math.floor(planet_size/2),
                            y=planet_pos.y + 4*math.floor(planet_size/2),
                            z=planet_pos.z + math.floor(planet_size/2),
                        }
                    }
                    local common_minp2 = {
                        x=math.max(common_minp.x, planet_mapping.minp.x),
                        y=math.max(common_minp.y, planet_mapping.minp.y),
                        z=math.max(common_minp.z, planet_mapping.minp.z)
                    }
                    local common_maxp2 = {
                        x=math.min(common_maxp.x, planet_mapping.maxp.x),
                        y=math.min(common_maxp.y, planet_mapping.maxp.y),
                        z=math.min(common_maxp.z, planet_mapping.maxp.z)
                    }
                    if common_maxp2.x > common_minp2.x
                    and common_maxp2.y > common_minp2.y
                    and common_maxp2.z > common_minp2.z then
                        -- Generate planet
                        planet_mapping.offset = {x=0, y=-planet_pos.y, z=0}
                        planet_mapping.seed = seed + n
                        planet_mapping.walled = true
                        generate_planet_chunk(
                            common_minp2, common_maxp2, area, A, A1, A2, planet_mapping
                        )
                    end
                end
            end
        end
    end
end

register_on_not_generated(new_area_callback)

-- Add starting planet
add_planet_mapping {
    minp = {
        x=-math.floor(planet_size/2),
        y=-4*math.floor(planet_size/2),
        z=-math.floor(planet_size/2)
    },
    maxp = {
        x=math.floor(planet_size/2),
        y=4*math.floor(planet_size/2),
        z=math.floor(planet_size/2)
    },
    offset = {x=0, y=100, z=0},
    seed = 0,
    walled = true
}
