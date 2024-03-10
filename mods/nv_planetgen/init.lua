--[[
NV Planetgen defines a custom map generator that can map arbitrary areas of
planets with various seeds into any part of the world. It overrides map
generation and provides an API to control it from other mods or from within this
file.

Read 'mapgen.lua' to learn how this works. For the API reference, keep reading
this file. To see or edit the default game setup, search '# GAME SETUP' in your
editor or IDE and jump to it; you can also see the '# EXAMPLES'.

Files are tagged with keywords throughout to make jumping to important places
easier. In order to jump to a tag, simply search '# TAG NAME' in your editor or
IDE and jump to the one match. At the start of each file there is an INDEX with
a list of all tags in order.

 # INDEX
    API REFERENCE
    EXAMPLES
]]--

dofile(minetest.get_modpath("nv_planetgen") .. "/api.lua")
if minetest.register_mapgen_script then
    minetest.register_mapgen_script(minetest.get_modpath("nv_planetgen") .. "/mapgen.lua")
end

--[[
# API REFERENCE
Planetgen is a configurable mapgen that can be used in many ways. The API it
offers can be used from this file (see GAME SETUP) and have this mod generate
custom terrain, or from a different mod to integrate it into a game.

There are two basic ways to use this API. The simplest one is simply to call
'nv_planetgen.add_planet_mapping()' at startup to place one or more planets at
certain locations in the world. These can be as large as necessary (e.g.
vertically stacked but filling the world horizontally), and many thousands of
planets can be created (e.g. 10k floating planets).

The second basic way to use the API is to register a callback function via
'nv_planetgen.register_on_not_generated()', and within that generate new areas with
'nv_planetgen.generate_planet_chunk()'. This allows one to generate an infinite
world with as many planets as desired, and add or remove planet areas
programmatically (e.g. to simulate a larger universe).

Coordinate format:
See https://minetest.gitlab.io/minetest/representations-of-simple-things/

Coordinate types:
https://minetest.gitlab.io/minetest/map-terminology-and-coordinates/
]]--

--[[    nv_planetgen.register_on_not_generated(callback)
Registers a function that will be called whenever an area not mapped to any
planet has been unsuccessfully generated. This allows to generate the area via
'nv_planetgen.generate_planet_chunk()', and/or manually generate custom content in
that area and then call 'nv_planetgen.set_dirty flag()' to acknowledge it.
'nv_planetgen.add_planet_mapping()' can also be called here to prevent further
calls to the callback for this area, but note that it does not automatically
call 'nv_planetgen.generate_planet_chunk()'.
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

--[[    nv_planetgen.add_planet_mapping(mapping)
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

--[[    nv_planetgen.remove_planet_mapping(index)
Removes a planet mapping from the list. Further attempts to generate the area
will result in the 'on not generated' callback being called if registered (see
'nv_planetgen.register_on_not_generated()').
    index       mapping index returned by 'nv_planetgen.add_planet'
]]--

--[[    nv_planetgen.generate_planet_chunk(minp, maxp, area, A, A1, A2, mapping)
Uses the map generation code provided by this mod to generate planet terrain
within an area. The generated area will be the intersection of the boxes
delimited by [minp .. maxp] and [mapping.minp .. mapping.maxp].
    minp        starting x, y and z node coordinates
    maxp        ending x, y and z node coordinates
    area        value from 'on not generated' callback or 'VoxelArea:new()'
    A           value from 'on not generated' callback or 'VoxelArea:get_data()'
    A1          value from 'on not generated' callback or 'VoxelArea:get_light_data()'
    A2          value from 'on not generated' callback or 'VoxelArea:get_param2_data()'
    mapping     see 'nv_planetgen.add_planet_mapping()' for format
]]

--[[    nv_planetgen.set_dirty_flag(callback)
Must be called when generating custom terrain directly via the 'on not
generated' callback. It is not necessary to call it if the new area is generated
using 'nv_planetgen.generate_planet_chunk()' or if no terrain is generated.
]]

--[[
# EXAMPLES
]]--

--[[
This function generates the same planet in all directions, indefinitely.
]]
local function example_infinite_callback(minp, maxp, area, A, A1, A2)
    local planet_mapping = {
        minp = minp,
        maxp = maxp,
        offset = {x=0, y=0, z=0},
        seed = 0
    }
    nv_planetgen.generate_planet_chunk(
        minp, maxp, area, A, A1, A2, planet_mapping
    )
end
