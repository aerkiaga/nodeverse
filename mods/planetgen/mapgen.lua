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
    walled      (optional) builds stone walls around the mapped area
]]--
planet_mappings = {
}

--[[
Maps planet IDs (keys) to actual planet metadata tables (values).
]]--
planet_dictionary = {
}

function clear_planet_mapping_area(mapping)
    local minp = {x=mapping.minp.x, y=mapping.minp.y, z=mapping.minp.z}
    local maxp = {x=mapping.maxp.x, y=mapping.maxp.y, z=mapping.maxp.z}
    minetest.delete_area(minp, maxp)
end

function planet_from_mapping(mapping)
    local planet = planet_dictionary[mapping.seed]
    if planet == nil then
        planet = generate_planet_metadata(mapping.seed)
        choose_planet_nodes_and_colors(planet)
        planet_dictionary[mapping.seed] = planet
        planet.seed = mapping.seed
        planet.num_mappings = 1
    else
        planet.num_mappings = planet.num_mappings + 1
    end
    return planet
end

-- API
function add_planet_mapping(mapping)
    local planet = planet_from_mapping(mapping)
    table.insert(planet_mappings, mapping)
    return #planet_mappings
end

-- API
function remove_planet_mapping(index)
    local planet = planet_from_mapping(mapping)
    planet.num_mappings = planet.num_mappings - 1
    if planet.num_mappings == 0 then
        planet_dictionary[planet_mappings[index].seed] = nil
    end
    table.remove(planet_mappings, index)
end

-- API
function generate_planet_chunk(minp, maxp, area, A, A1, A2, mapping)
    local planet = planet_from_mapping(mapping)
    local offset = mapping.offset
    pass_elevation(minp, maxp, area, offset, A, A2, planet)

    local minp_x = mapping.minp.x
    local minp_z = mapping.minp.z
    local maxp_x = mapping.maxp.x
    local maxp_z = mapping.maxp.z
    if planet.caveness > 2^(-3) then
        local new_minp = minp
        local new_maxp = maxp
        if mapping.walled then
            new_minp = {
                x=math.max(minp.x, minp_x+1),
                y=minp.y,
                z=math.max(minp.z, minp_z+1)
            }
            new_maxp = {
                x=math.min(maxp.x, maxp_x-1),
                y=maxp.y,
                z=math.min(maxp.z, maxp_z-1)
            }
        end
        pass_caves(new_minp, new_maxp, area, offset, A, A2, planet)
    end

    local is_walled = mapping.walled
    local is_scorching = (planet.atmosphere == "scorching")
    local node_air = minetest.CONTENT_AIR
    local offset_x, offset_y, offset_z = offset.x, offset.y, offset.z
    for z_abs=minp.z, maxp.z do
        for y_abs=minp.y, maxp.y do
            for x_abs=minp.x, maxp.x do
                local i = area:index(x_abs, y_abs, z_abs)
                local Ai = A[i]
                if Ai ~= node_air then
                    local pos_x = x_abs + offset_x
                    local pos_y = y_abs + offset_y
                    local pos_z = z_abs + offset_z

                    -- Generate walls around mappings
                    if is_walled and (
                        x_abs == minp_x or x_abs == maxp_x
                        or z_abs == minp_z or z_abs == maxp_z
                    ) then
                        A[i] = planet.node_types.stone
                    end

                    -- Apply lighting
                    if is_scorching and Ai == planet.node_types.liquid then
                        A1[i] = 128
                    else
                        A1[i] = 15
                    end

                    -- Apply random texture rotation to all supported nodes
                    local rot = random_yrot_nodes[Ai]
                    local param2 = 0
                    if rot ~= nil then
                        local hash = pos_x + pos_y*471 + pos_z*3273
                        param2 = hash % 13357 % rot
                        if rot == 2 then
                            param2 = param2 * 2
                        end
                    end

                    -- Apply 'colorfacedir' color to all supported nodes
                    -- TODO: support 'color' and 'colorwallmounted' colors
                    local color = planet.color_dictionary[Ai]
                    if color ~= nil then
                        color = color * 0x20
                        param2 = param2 + color
                    end

                    A2[i] = param2
                end -- if
            end -- for
        end -- for
    end -- for
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

    local r = {}
    for index, box in ipairs(not_generated_boxes) do
        local commonmin = {
            x=math.max(minp.x, box.minp.x),
            y=math.max(minp.y, box.minp.y),
            z=math.max(minp.z, box.minp.z)
        }
        local commonmax = {
            x=math.min(maxp.x, box.maxp.x),
            y=math.min(maxp.y, box.maxp.y),
            z=math.min(maxp.z, box.maxp.z)
        }
        -- Box defined by 'minp' and 'maxp' intersects 'box'
        if commonmax.x >= commonmin.x and commonmax.z >= commonmin.z then
            local x_stops = {box.minp.x, commonmin.x-1, commonmax.x+1, box.maxp.x}
            local y_stops = {box.minp.y, commonmin.y-1, commonmax.y+1, box.maxp.y}
            local z_stops = {box.minp.z, commonmin.z-1, commonmax.z+1, box.maxp.z}
            for z_index=1, 3 do
                for y_index=1, 3 do
                    for x_index=1, 3 do
                        -- Avoid center box
                        if x_index ~= 2 or y_index ~= 2 or z_index ~= 2 then
                            local box2 = {
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

-- API
function register_on_not_generated(callback)
    on_not_generated_callback = callback
end

--[[
# ENTRY POINT
]]--

A, A1, A2 = nil

function mapgen_callback(minp, maxp, blockseed)
    local VM, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    if A == nil then
        A = VM:get_data()
        A2 = VM:get_param2_data()
    else
        VM:get_data(A)
        VM:get_param2_data(A2)
    end
    A1 = VM:get_light_data()

    -- A list of areas that are not mapped to a planet (yet)
    local not_generated_boxes = {{minp = minp, maxp = maxp}}

    -- Find mapping(s) for the generated region
    for key, mapping in pairs(planet_mappings) do
        local commonmin = {
            x=math.max(minp.x, mapping.minp.x),
            y=math.max(minp.y, mapping.minp.y),
            z=math.max(minp.z, mapping.minp.z)
        }
        local commonmax = {
            x=math.min(maxp.x, mapping.maxp.x),
            y=math.min(maxp.y, mapping.maxp.y),
            z=math.min(maxp.z, mapping.maxp.z)
        }
        if commonmax.x >= commonmin.x and commonmax.y >= commonmin.y and commonmax.z >= commonmin.z then
            generate_planet_chunk(commonmin, commonmax, area, A, A1, A2, mapping)
            not_generated_boxes = split_not_generated_boxes(not_generated_boxes, commonmin, commonmax)
        end
    end
    if on_not_generated_callback ~= nil then
        for index, box in ipairs(not_generated_boxes) do
            on_not_generated_callback(box.minp, box.maxp, area, A, A1, A2)
        end
    end
    VM:set_data(A)
    VM:set_light_data(A1)
    VM:set_param2_data(A2)
    VM:calc_lighting()
    VM:write_to_map()
end

--[[
# INITIALIZATION
]]--

minetest.register_on_generated(mapgen_callback)

register_on_not_generated(nil)

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

register_all_nodes()
