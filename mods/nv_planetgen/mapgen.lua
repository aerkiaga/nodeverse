--[[
This is the main file for the map generator. It should be run in a mapgen environment.
Included files:
    util.lua            Probability distribution and math functions
    meta.lua            Generates global characteristics of a planet from a seed
    pass_elevation.lua  First pass: terrain elevation and layers, oceans
    pass_caves.lua      Second pass: caves
    pass_structures.lua Third pass: trees and other structures
    pass_final.lua      Final pass: random rotation, lighting, colors...

 # INDEX
    ENTRY POINT
    INITIALIZATION
--]]

nv_planetgen = {}

dofile(minetest.get_modpath("nv_planetgen") .. "/util.lua")
dofile(minetest.get_modpath("nv_planetgen") .. "/meta.lua")
dofile(minetest.get_modpath("nv_planetgen") .. "/pass_elevation.lua")
dofile(minetest.get_modpath("nv_planetgen") .. "/pass_caves.lua")
dofile(minetest.get_modpath("nv_planetgen") .. "/pass_structures.lua")
dofile(minetest.get_modpath("nv_planetgen") .. "/pass_final.lua")

local generator_dirty_flag = false

function nv_planetgen.set_dirty_flag()
    generator_dirty_flag = true
end

local post_processing = {}
function nv_planetgen.register_post_processing(callback)
    table.insert(post_processing, callback)
end

local function planet_from_mapping(mapping)
    local f = io.open(minetest.get_worldpath() .. "/nv_planetgen.planet_dictionary", "rt")
    local planet_dictionary = minetest.deserialize(f:read())
    f:close()
    local planet = planet_dictionary[mapping.seed]
    return planet
end

function nv_planetgen.generate_planet_chunk(minp, maxp, area, A, A1, A2, mapping)
    local max = math.max
    local min = math.min

    nv_planetgen.set_dirty_flag()
    local planet = planet_from_mapping(mapping)
    local offset = mapping.offset
    local ground_buffer = nv_planetgen.pass_elevation(
        minp, maxp, area, offset, A, planet
    )

    if planet.caveness > 2^(-3) then
        local new_minp = minp
        local new_maxp = maxp
        if mapping.walled then
            new_minp = {
                x=max(minp.x, mapping.minp.x+1),
                y=minp.y,
                z=max(minp.z, mapping.minp.z+1)
            }
            new_maxp = {
                x=min(maxp.x, mapping.maxp.x-1),
                y=maxp.y,
                z=min(maxp.z, mapping.maxp.z-1)
            }
        end
        nv_planetgen.pass_caves(new_minp, new_maxp, area, offset, A, A2, planet)
    end
    nv_planetgen.pass_structures(minp, maxp, area, offset, A, A1, A2, mapping, planet, ground_buffer)
    nv_planetgen.pass_final(minp, maxp, area, offset, A, A1, A2, mapping, planet, ground_buffer)
    for n, callback in ipairs(post_processing) do
        callback(minp, maxp, area, offset, A, A1, A2, mapping, planet, ground_buffer)
    end
end

local function split_not_generated_boxes(not_generated_boxes, minp, maxp)
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
    local max = math.max
    local min = math.min
    local tinsert = table.insert

    local r = {}
    for index, box in ipairs(not_generated_boxes) do
        local commonmin = {
            x=max(minp.x, box.minp.x),
            y=max(minp.y, box.minp.y),
            z=max(minp.z, box.minp.z)
        }
        local commonmax = {
            x=min(maxp.x, box.maxp.x),
            y=min(maxp.y, box.maxp.y),
            z=min(maxp.z, box.maxp.z)
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
                            if box2.maxp.x >= box2.minp.x
                            and box2.maxp.y >= box2.minp.y
                            and box2.maxp.z >= box2.minp.z then
                                tinsert(r, box2)
                            end
                        end
                    end
                end
            end
        else
            tinsert(r, box)
        end
    end
    return r
end

--[[
# ENTRY POINT
]]--

local A, A1, A2 = nil, nil, nil

local function mapgen_callback(VM, minp, maxp, blockseed)
    local max = math.max
    local min = math.min
    local emin, emax = VM:get_emerged_area()
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
    local f = io.open(minetest.get_worldpath() .. "/nv_planetgen.planet_mappings", "rt")
    local planet_mappings = minetest.deserialize(f:read())
    f:close()
    for key, mapping in pairs(planet_mappings) do
        local commonmin = {
            x=max(minp.x, mapping.minp.x),
            y=max(minp.y, mapping.minp.y),
            z=max(minp.z, mapping.minp.z)
        }
        local commonmax = {
            x=min(maxp.x, mapping.maxp.x),
            y=min(maxp.y, mapping.maxp.y),
            z=min(maxp.z, mapping.maxp.z)
        }
        if commonmax.x >= commonmin.x and commonmax.y >= commonmin.y and commonmax.z >= commonmin.z then
            nv_planetgen.generate_planet_chunk(commonmin, commonmax, area, A, A1, A2, mapping)
            not_generated_boxes = split_not_generated_boxes(not_generated_boxes, commonmin, commonmax)
        end
    end
    if generator_dirty_flag then
        generator_dirty_flag = false
        VM:set_data(A)
        VM:set_light_data(A1)
        VM:set_param2_data(A2)
        VM:calc_lighting()
    end
    nv_planetgen.refresh_meta()
end

function nv_planetgen.refresh_meta()
    return
    -- TODO: implement using gennotify
    --[[for n, entry in ipairs(meta_nodes) do
        local meta = minetest.get_meta(entry.pos)
        local tab = meta:to_table()
        for k, v in pairs(entry.meta.fields) do
            tab.fields[k] = v
        end
        meta:from_table(tab)
    end
    meta_nodes = {}]]--
end

--[[
# INITIALIZATION
]]--

minetest.register_on_generated(mapgen_callback)
