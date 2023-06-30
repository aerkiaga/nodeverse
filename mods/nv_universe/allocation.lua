--[[
This file contains routines that allocate different "layers" to
planets and outer space, so that multiple players can explore
the universe simultaneously.

 # INDEX
    LAYER CONSTANTS
    LAYER MAP
    ALLOCATION
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
]]
local layers = {}

--[[
Contains a dictionary of layers by mapgen seed, with their mapping
to layers. Unmapped planets are nil. Format is:
    space       layer index for space around planet, or nil
    planet      layer index for planet itself, or nil
]]
local planets = {}

--[[
 # ALLOCATION
]]

-- Returns layer index or nil.
function nv_universe.try_allocate_layer()
    for i, v in ipairs(layer_limits) do
        if not layers[i] or layers[i].n_players <= 0 then
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
        if planets[seed] then
            planets[seed].planet = layer
        end
        layers[layer] = {
            in_space = false,
            planet = seed,
            n_players = 0
        }
        return layer
    end
end

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
        pos_y = math.floor((limit.min + limit.max) / 2 + 100)
    end
    if pos_y > limit.max then
        pos_y = math.floor((limit.min + limit.max) / 2)
    end
    return {
        in_space = layers[layer].in_space,
        planet = layers[layer].planet,
        pos = {x = 0, y = pos_y, z = 0}
    }
end

--[[
 # MAPGEN SETUP
]]

local function new_area_callback(minp, maxp, area, A, A1, A2)
    local min, max, offset = nil
    for i, v in ipairs(layer_limits) do
        if minp.y <= v.max and maxp.y >= v.min then
            min = math.max(minp.y, v.min)
            max = math.min(maxp.y, v.max)
            offset = -math.floor((v.min + v.max) / 2)
            break
        end
    end
    if offset == nil then
        return
    end
    minp.y = min
    maxp.y = max
    local world_seed = minetest.get_mapgen_setting("seed") % 65536
    local planet_mapping = {
        minp = minp,
        maxp = maxp,
        offset = {x=0, y=offset, z=0},
        seed = world_seed,
        walled = false
    }
    nv_planetgen.generate_planet_chunk(
        minp, maxp, area, A, A1, A2, planet_mapping
    )
end

nv_planetgen.register_on_not_generated(new_area_callback)
