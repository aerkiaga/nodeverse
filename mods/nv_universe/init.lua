--[[
NV Universe implements a huge universe by allocating different
parts of the map to different mapgen settings. If a player exits
one planet, they are transported into outer space, and can use
a GUI to move into another planet.

Included files:
    util.lua            Color management functions
    allocation.lua      Allocates slices of the world to different planets
    sky.lua       		Sets sky parameters according to location
    menu.lua			Implements a GUI to travel across the universe

 # INDEX
    SETTINGS
    PLAYER LIST
    PLAYER OPERATIONS
    CALLBACKS
]]--

nv_universe = {}

--[[
 # SETTINGS
]]

nv_universe.settings = {
    starting_planet = nil,
    layer_height = 256,
    separator_height = 512
}

dofile(minetest.get_modpath("nv_universe") .. "/util.lua")
dofile(minetest.get_modpath("nv_universe") .. "/allocation.lua")
dofile(minetest.get_modpath("nv_universe") .. "/sky.lua")
dofile(minetest.get_modpath("nv_universe") .. "/menu.lua")

--[[
 # PLAYER LIST
]]

--[[
Contains a dictionary of all players by name, with some information
to manage their location within the universe. Format is:
    in_space    whether the player is in space or a planet
    planet      the mapgen seed for the planet the player is on/around
]]--

nv_universe.players = {}

--[[
 # PLAYER OPERATIONS
]]

local function send_into_space(player)
    local name = player:get_player_name()
    if nv_universe.players[name].in_space then
        return
    end
    local seed = nv_universe.players[name].planet
    nv_universe.remove_from_planet(seed)
    local layer = nv_universe.try_allocate_space(seed)
    if not layer then
        -- return to planet
        layer = nv_universe.try_allocate_planet(seed)
        nv_universe.place_in_layer(layer)
        return
    end
    local placing = nv_universe.place_in_layer(layer)
    nv_universe.players[name].in_space = placing.in_space
    nv_universe.players[name].planet = placing.planet
    player:set_pos(placing.pos)
    nv_universe.set_space_sky(player, placing.planet)
    nv_player.set_relative_gravity(player, 0)
end

local function send_into_planet(player)
    local name = player:get_player_name()
    if not nv_universe.players[name].in_space then
        return
    end
    local seed = nv_universe.players[name].planet
    nv_universe.remove_from_space(seed)
    local layer = nv_universe.try_allocate_planet(seed)
    if not layer then
        -- return to planet
        layer = nv_universe.try_allocate_space(seed)
        nv_universe.place_in_layer(layer)
        return
    end
    local placing = nv_universe.place_in_layer(layer)
    nv_universe.players[name].in_space = placing.in_space
    nv_universe.players[name].planet = placing.planet
    player:set_pos(placing.pos)
    nv_universe.set_planet_sky(player, placing.planet)
    nv_player.set_relative_gravity(player, nv_universe.get_planet_gravity(placing.planet))
end

function nv_universe.check_travel_capability(player, new_seed)
    local name = player:get_player_name()
    if not nv_universe.players[name].in_space then
        return false
    end
    return true
end

function nv_universe.send_to_new_space(player, new_seed)
    local name = player:get_player_name()
    if not nv_universe.check_travel_capability(player, new_seed) then
        return
    end
    local old_seed = nv_universe.players[name].planet
    nv_universe.remove_from_space(old_seed)
    local layer = nv_universe.try_allocate_space(new_seed)
    if not layer then
        -- return to planet
        layer = nv_universe.try_allocate_space(old_seed)
        nv_universe.place_in_layer(layer)
        return
    end
    local placing = nv_universe.place_in_layer(layer)
    nv_universe.players[name].in_space = placing.in_space
    nv_universe.players[name].planet = placing.planet
    player:set_pos(placing.pos)
    nv_universe.set_space_sky(player, placing.planet)
end

--[[
 # CALLBACKS
]]

local function globalstep_callback(dtime)
    local players = minetest.get_connected_players()
    for i, player in ipairs(players) do
        local name = player:get_player_name()
        local pos = player:get_pos()
        local func = nv_universe.players[name].in_space
            and nv_universe.get_space_limits
            or nv_universe.get_planet_limits
        local limits = func(nv_universe.players[name].planet)
        if limits ~= nil then
            if pos.y > limits.max then
                player:set_pos({x=pos.x, y=limits.max, z=pos.z})
                if not nv_universe.players[name].in_space then
                    send_into_space(player)
                end
            elseif pos.y < limits.min then
                player:set_pos({x=pos.x, y=limits.min, z=pos.z})
                if nv_universe.players[name].in_space then
                    send_into_planet(player)
                end
            end
        end
    end
end

minetest.register_globalstep(globalstep_callback)

local function newplayer_callback(player)
    local starting_planet = nv_universe.settings.starting_planet or math.random(0, 65535)
    local layer = nv_universe.try_allocate_planet(starting_planet)
    if not layer then
        layer = 1
    end
    local placing = nv_universe.place_in_layer(layer)
    local new_player = {
        in_space = placing.in_space,
        planet = placing.planet
    }
    local name = player:get_player_name()
    nv_universe.players[name] = new_player
    player:set_pos(placing.pos)
    if placing.in_space then
        nv_universe.set_space_sky(player, placing.planet)
    else
        nv_universe.set_planet_sky(player, placing.planet)
    end
    local formspec = nv_universe.create_planet_formspec(placing.planet)
	player:set_inventory_formspec(formspec)
end

minetest.register_on_newplayer(newplayer_callback)
