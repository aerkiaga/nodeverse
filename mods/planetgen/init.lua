--[[
Planetgen defines a custom map generator that can map arbitrary areas of planets
with various seeds into any part of the world. It overrides map generation and
provides an API to control it from other mods.

Read mapgen.lua to learn how this works. For the API reference, keep reading
this file.
]]--

dofile(minetest.get_modpath("planetgen") .. "/mapgen.lua")

--[[
# API REFERENCE

Coordinate format:
See https://minetest.gitlab.io/minetest/representations-of-simple-things/

Coordinate types:
https://minetest.gitlab.io/minetest/map-terminology-and-coordinates/
]]--

--[[    planetgen.add_planet(planet)
Adds a mapping from a rectangular chunk-aligned region of the world to the same
region in a "planet" with a certain seed, so that it generates terrain from that
planet. 'planet' is a table containing:
    minp        starting x, y and z node coordinates
    maxp        ending x, y and z node coordinates
    seed        planet seed; each seed represents a unique planet
For now, this function is meant to be used exactly once for each unique planet,
paired with a call to 'planetgen.remove_planet'. It generates all global planet
metadata and registers all nodes.
TODO: rewrite 'planetgen.add_planet' and 'planetgen.remove_planet' to support
multiple mappings to a single planet.
    Returns planet mapping index.
]]--

--[[    planetgen.remove_planet(index)
Removes a planet mapping from the list. 'index' is the index returned by
'planetgen.add_planet'. Unregisters all nodes specific to the planet.
]]--
