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
A single planet extending infinitely in all directions.
]]

function new_area_callback(minp, maxp, area, A, A1, A2)
    -- Simply map all new areas to the same planet
    local new_mapping = {
        minp = minp,
        maxp = maxp,
        offset = {x=0, y=100, z=0},
        seed = 0
    }
    generate_planet_chunk(minp, maxp, area, A, A1, A2, new_mapping)
end

register_on_not_generated(new_area_callback)
