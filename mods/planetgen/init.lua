--[[
Planetgen defines a custom map generator that can map arbitrary areas of planets
with various seeds into any part of the world. It overrides map generation and
provides an API to control it from other mods or from within this file.

Read mapgen.lua to learn how this works. For the API reference, keep reading
this file. To see or edit the default game setup, search '# GAME SETUP' in your
editor or IDE.
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
    offset      world position P will map to planet coordinates P + offset
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

--[[
# GAME SETUP

Default game setup:
Generate a number of planets following a conic spiral with Archimedean floor
plan, trying to keep distances even. A Fermat spiral with golden angle step was
also attempted, but the results were noticeably worse in terms of balance. The
first two planets overlap, while the rest are laid out with large gaps between
them.
]]

num_planets = 100
planet_size = 80
function seed_from_n(n)
    return n
end

current_pos = {x=1, y=-100, z=0}
elevation_per_turn = planet_size
separation_per_turn = 2*planet_size
separation = 2*planet_size
for n=1, num_planets do
    current_node = {
        x=math.floor(current_pos.x),
        y=math.floor(current_pos.y),
        z=math.floor(current_pos.z)
    }
    r_min = math.floor(planet_size / 2)
    r_max = math.ceil(planet_size / 2) - 1
    add_planet {
        minp = {x=current_node.x-r_min, y=current_node.y-2*r_min, z=current_node.z-r_min},
        maxp = {x=current_node.x+r_max, y=current_node.y+4*r_max, z=current_node.z+r_max},
        offset = {x=-current_node.x, y=-current_node.y, z=-current_node.z},
        seed = seed_from_n(n)
    }
    delta_angle = math.sqrt(2*math.pi*separation / (n*separation_per_turn))
    current_pos = vec3_rotate(current_pos, delta_angle, {x=0, y=1, z=0})
    outward = {x=current_pos.x, y=0, z=current_pos.z}
    outward = vec3_scale(outward, 1/vec3_modulo(outward))
    outward = vec3_scale(outward, separation_per_turn * delta_angle / (2*math.pi))
    outward.y = elevation_per_turn * delta_angle / (2*math.pi)
    current_pos = vec3_add(current_pos, outward)
end
