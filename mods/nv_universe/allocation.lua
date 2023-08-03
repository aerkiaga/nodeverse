--[[
This file contains routines that allocate different "layers" to
planets and outer space, so that multiple players can explore
the universe simultaneously.

 # INDEX
    LAYER CONSTANTS
    LAYER MAP
    ALLOCATION
    UTILITY
    MAPGEN SETUP
]]--

--[[
 # LAYER CONSTANTS
]]

-- Constant list of tables with 'min' and 'max' fields.
local layer_limits = {}

do
    local y = -30000 + nv_universe.settings.separator_height
    while y <= 30000 do
        limit = {
            min = y,
            max = y + nv_universe.settings.layer_height - 1
        }
        table.insert(layer_limits, limit)
        y = y + nv_universe.settings.layer_height
        y = y + nv_universe.settings.separator_height
    end
end

--[[
 # LAYER MAP
]]

--[[
Contains a dictionary of layers by integer index, with information
about their current status. Unallocated layers are nil. Format is:
    in_space    whether the layer represents outer space
    planet      the mapgen seed for the planet the layer is on/around
    n_players   number of players currently inhabiting the layer
    areas       list of generated areas, tables with 'minp' and 'maxp'
]]
local layers = {}
nv_universe.layers = layers

--[[
Contains a dictionary of layers by mapgen seed, with their mapping
to layers. Unmapped planets are nil. Format is:
    space       layer index for space around planet, or nil
    planet      layer index for planet itself, or nil
]]
local planets = {}
nv_universe.planets = planets

--[[
 # ALLOCATION
]]

-- Unloads an entire layer, forcing it to be re-generated later and freeing it
function nv_universe.free_layer(layer)
    for i, area in ipairs(layers[layer].areas) do
        minetest.delete_area(area.minp, area.maxp)
    end
    layers[layer].areas = {}
    local seed = layers[layer].planet
    planets[seed][layers[layer].is_space and "space" or "planet"] = nil
    if next(planets[seed]) == nil then
        planets[seed] = nil
    end
    nv_universe.store_global_state()
end

-- Returns layer index or nil.
function nv_universe.try_allocate_layer()
    for i, v in ipairs(layer_limits) do
        if not layers[i] then
            if layers[i] then
                nv_universe.free_layer(i)
            end
            return i
        end
    end
    for i, v in ipairs(layer_limits) do
        if layers[i].n_players <= 0 then
            if layers[i] then
                nv_universe.free_layer(i)
            end
            return i
        end
    end
    return nil
end

-- Takes planet seed, returns layer index or nil.
function nv_universe.try_allocate_planet(seed)
    if planets[seed] and planets[seed].planet then
        return planets[seed].planet
    else
        local layer = nv_universe.try_allocate_layer()
        if not layer then
            return nil
        end
        if not planets[seed] then
            planets[seed] = {}
        end
        planets[seed].planet = layer
        layers[layer] = {
            in_space = false,
            planet = seed,
            n_players = 0,
            areas = {}
        }
        nv_universe.store_global_state()
        return layer
    end
end

-- Takes planet seed, returns layer index or nil.
function nv_universe.try_allocate_space(seed)
    if planets[seed] and planets[seed].space then
        return planets[seed].space
    else
        local layer = nv_universe.try_allocate_layer()
        if not layer then
            return nil
        end
        if not planets[seed] then
            planets[seed] = {}
        end
        planets[seed].space = layer
        layers[layer] = {
            in_space = true,
            planet = seed,
            n_players = 0,
            areas = {}
        }
        nv_universe.store_global_state()
        return layer
    end
end

--[[
 # PLAYER OPERATIONS
]]

--[[
Takes layer index, returns table with information to warp player.
Format is:
    in_space    whether the player is in space now
    planet      what planet the player is on/around now
    pos         absolute position to place the player at
]]
function nv_universe.place_in_layer(layer)
    layers[layer].n_players = layers[layer].n_players + 1
    local limit = layer_limits[layer]
    local pos_y = nil
    if layers[layer].in_space then
        pos_y = limit.min + 100
    else
        pos_y = math.floor((limit.min + limit.max) / 2 + 50)
    end
    if pos_y > limit.max then
        pos_y = math.floor((limit.min + limit.max) / 2)
    end
    nv_universe.store_global_state()
    return {
        in_space = layers[layer].in_space,
        planet = layers[layer].planet,
        pos = {x = 0, y = pos_y, z = 0}
    }
end

--[[
Takes layer index, removes one player from it.
]]
function nv_universe.remove_from_layer(layer)
    layers[layer].n_players = layers[layer].n_players - 1
    --nv_universe.store_global_state()
end

--[[
Takes planet seed, removes one player from it.
]]
function nv_universe.remove_from_planet(seed)
    nv_universe.remove_from_layer(planets[seed].planet)
end

--[[
Takes planet seed, removes one player from its space.
]]
function nv_universe.remove_from_space(seed)
    nv_universe.remove_from_layer(planets[seed].space)
end

--[[
 # UTILITY
]]

--[[
Takes planet mapgen seed, returns nil or table with information.
Format is:
    min         minimum Y coordinate of planet layer
    max         maximum Y coordinate of planet layer
]]
function nv_universe.get_planet_limits(seed)
    if planets[seed] == nil or planets[seed].planet == nil then
        return nil
    end
    local limit = layer_limits[planets[seed].planet]
    return {
        min = limit.min,
        max = limit.max
    }
end

--[[
Takes planet mapgen seed, returns nil or table with information.
Format is:
    min         minimum Y coordinate of space layer
    max         maximum Y coordinate of space layer
]]
function nv_universe.get_space_limits(seed)
    if planets[seed] == nil or planets[seed].space == nil then
        return nil
    end
    local limit = layer_limits[planets[seed].space]
    return {
        min = limit.min,
        max = limit.max
    }
end

--[[
 # MAPGEN SETUP
]]

local post_processing = {}
function nv_universe.register_post_processing(fn)
    table.insert(post_processing, fn)
end

local function new_area_callback(minp, maxp, area, A, A1, A2)
    local min, max, offset, layer = nil
    for i, v in ipairs(layer_limits) do
        if minp.y <= v.max and maxp.y >= v.min then
            min = math.max(minp.y, v.min)
            max = math.min(maxp.y, v.max)
            offset = -math.floor((v.min + v.max) / 2)
            layer = i
            break
        end
    end
    if layer == nil then
        return
    end
    if layers[layer] == nil or layers[layer].in_space then
        return
    end
    minp.y = min
    maxp.y = max
    local planet_mapping = {
        minp = minp,
        maxp = maxp,
        offset = {x=0, y=offset, z=0},
        seed = layers[layer].planet,
        walled = false
    }
    nv_planetgen.generate_planet_chunk(
        minp, maxp, area, A, A1, A2, planet_mapping
    )
    for _, fn in ipairs(post_processing) do
        fn(planet_mapping, area, A, A1, A2)
    end
    table.insert(layers[layer].areas, {minp=minp, maxp=maxp})
end

nv_planetgen.register_on_not_generated(new_area_callback)
