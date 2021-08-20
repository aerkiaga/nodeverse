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

--[[
Contains a list of all current mappings between chunk coordinate rectangles
and the same region on a planet with some seed. Entry format is:
    minp        starting x, y and z node coordinates
    maxp        ending x, y and z node coordinates
    offset      world position P will map to planet coordinates P + offset
    seed        planet seed; each seed represents a unique planet
]]--
planet_list = {
}

function clear_planet_area(planet)
    minp = {x=planet.minp.x, y=planet.minp.y, z=planet.minp.z}
    maxp = {x=planet.maxp.x, y=planet.maxp.y, z=planet.maxp.z}
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

function generate_planet_chunk(minp, maxp, area, A, A1, A2, planet)
    pass_elevation(minp, maxp, area, A, A2, planet)
    pass_caves(minp, maxp, area, A, A2, planet) --D
    for i in area:iter(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z) do
        pos = area:position(i)
        pos = vec3_add(pos, planet.offset)

        -- Apply lighting
        if A[i] == planet.node_types.liquid and planet.atmosphere == "scorching" then
            A1[i] = 128
        else
            A1[i] = 15
        end

        -- Apply random texture rotation to all supported nodes
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

function split_not_generated_boxes(not_generated_boxes, minp, maxp)
    --[[
    Takes a set of boxes and splits as many of them as necessary so that all of
    the remaining boxes are outside the area specified by 'minp' and 'maxp'.
    _____________________________
    |    :     :                |
    |    :     :                |
    |...._______................|
    |    |minp |                |
    |    |     |                |
    |....|_maxp|................|
    |    :     :                |
    |____:_____:________________|
    ]]

    r = {}
    for index, box in ipairs(not_generated_boxes) do
        commonmin = {
            x=math.max(minp.x, box.minp.x),
            y=math.max(minp.y, box.minp.y),
            z=math.max(minp.z, box.minp.z)
        }
        commonmax = {
            x=math.min(maxp.x, box.maxp.x),
            y=math.min(maxp.y, box.maxp.y),
            z=math.min(maxp.z, box.maxp.z)
        }
        -- Box defined by 'minp' and 'maxp' intersects 'box'
        if commonmax.x >= commonmin.x and commonmax.z >= commonmin.z then
            x_stops = {box.minp.x, commonmin.x-1, commonmax.x+1, box.maxp.x}
            y_stops = {box.minp.y, commonmin.y-1, commonmax.y+1, box.maxp.y}
            z_stops = {box.minp.z, commonmin.z-1, commonmax.z+1, box.maxp.z}
            for x_index=1, 3 do
                for y_index=1, 3 do
                    for z_index=1, 3 do
                        -- Avoid center box
                        if x_index ~= 2 or y_index ~= 2 or z_index ~= 2 then
                            box2 = {
                                minp = {x=x_stops[x_index], y=y_stops[y_index], z=z_stops[z_index]},
                                maxp = {x=x_stops[x_index+1], y=y_stops[y_index+1], z=z_stops[z_index+1]}
                            }
                            if x_index == 2 then
                                box2.minp.x = box2.minp.x + 1
                                box2.maxp.x = box2.maxp.x - 1
                            end
                            if y_index == 2 then
                                box2.minp.y = box2.minp.y + 1
                                box2.maxp.y = box2.maxp.y - 1
                            end
                            if z_index == 2 then
                                box2.minp.z = box2.minp.z + 1
                                box2.maxp.z = box2.maxp.z - 1
                            end
                            if box2.maxp.x >= box2.minp.x and box2.maxp.y >= box2.minp.y and box2.maxp.z >= box2.minp.z then
                                table.insert(r, box2)
                            end
                        end
                    end
                end
            end
        else
            table.insert(r, box)
        end
    end
    return r
end

on_not_generated_callback = nil

function register_on_not_generated(callback)
    on_not_generated_callback = callback
end

--[[
# ENTRY POINT
]]--

function mapgen_callback(minp, maxp, blockseed)
    local VM, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    local A = VM:get_data()
    local A1 = VM:get_light_data()
    local A2 = VM:get_param2_data()

    -- A list of areas that are not mapped to a planet (yet)
    local not_generated_boxes = {{minp = minp, maxp = maxp}}

    -- Find planet(s) for the generated region
    for key, planet in pairs(planet_list) do
        commonmin = {
            x=math.max(minp.x, planet.minp.x),
            y=math.max(minp.y, planet.minp.y),
            z=math.max(minp.z, planet.minp.z)
        }
        commonmax = {
            x=math.min(maxp.x, planet.maxp.x),
            y=math.min(maxp.y, planet.maxp.y),
            z=math.min(maxp.z, planet.maxp.z)
        }
        if commonmax.x >= commonmin.x and commonmax.y >= commonmin.y and commonmax.z >= commonmin.z then
            generate_planet_chunk(commonmin, commonmax, area, A, A1, A2, planet)
            not_generated_boxes = split_not_generated_boxes(not_generated_boxes, commonmin, commonmax)
        end
    end
    if on_not_generated_callback ~= nil then
        for index, box in ipairs(not_generated_boxes) do
            on_not_generated_callback(box.minp, box.maxp, area, A, A1, A2, planet)
        end
    end
    VM:set_data(A)
    VM:set_light_data(A1)
    VM:set_param2_data(A2)
    VM:calc_lighting()
    VM:write_to_map()
end

function infinite_ng_callback(minp, maxp, area, A, A1, A2)
    -- This should generate planets on the fly in all directions
    -- However, it can't, due to inability to register node types after startup
    -- TODO: work around this issue
    new_planets = {}
    -- Iterate through overlapping mapchunks
    for z=minp.z - minp.z%80, maxp.z - maxp.z%80 + 79, 80 do
        for x=minp.x - minp.x%80, maxp.x - maxp.x%80 + 79, 80 do
            found_planet = nil
            -- Has it been added in a previous iteration?
            for index, planet in ipairs(new_planets) do
                if x == planet.minp.x and z == planet.minp.z then
                    found_planet = planet
                    break
                end
            end
            -- Otherwise add it
            if found_planet == nil then
                found_planet = {
                    minp = {x=x, y=-640, z=z},
                    maxp = {x=x, y=639, z=z},
                    offset = {x=0, y=0, z=0},
                    seed = 1
                }
                table.insert(new_planets, found_planet)
                --add_planet(found_planet)
            end
            -- And generate the appropriate terrain with the new planet
            local_minp = {
                x=math.max(x, minp.x),
                y=math.max(-640, minp.y),
                z=math.max(z, minp.z)
            }
            local_maxp = {
                x=math.min(x+79, maxp.x),
                y=math.min(639, maxp.y),
                z=math.min(z+79, maxp.z)
            }
            if local_maxp.y > local_minp.y then
                --generate_planet_chunk(local_minp, local_maxp, area, A, A1, A2, found_planet)
            end
        end
    end
end

--[[
# INITIALIZATION
]]--

minetest.register_on_generated(mapgen_callback)

register_on_not_generated(infinite_ng_callback)

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
        "water.png"
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
