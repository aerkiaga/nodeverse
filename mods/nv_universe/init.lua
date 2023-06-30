--[[
NV Universe implements a huge universe by allocating different
parts of the map to different mapgen settings. If a player exits
one planet, they are transported into outer space, and can use
a GUI to move into another planet.

 # INDEX
    SETTINGS
    PLAYER LIST
    CALLBACKS
]]--

nv_universe = {}

--[[
 # SETTINGS
]]

nv_universe.settings = {
    starting_planet = nil,
    layer_height = 500,
    separator_height = 1000
}

-- Allocates slices of the world to different planets
dofile(minetest.get_modpath("nv_universe") .. "/allocation.lua")

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
 # CALLBACKS
]]

local function globalstep_callback(dtime)
    local players = minetest.get_connected_players()
    for i, player in ipairs(players) do
        local name = player:get_player_name()
        local pos = player:get_pos()
        --
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
end

minetest.register_on_newplayer(newplayer_callback)
