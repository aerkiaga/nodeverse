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
    storage.lua         Contains code to store and retrieve data from storage.

 # INDEX
    SETTINGS
    PLAYER LIST
    UTILITIES
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
dofile(minetest.get_modpath("nv_universe") .. "/storage.lua")
if minetest.register_mapgen_script then
    minetest.register_mapgen_script(minetest.get_modpath("nv_universe") .. "/mapgen.lua")
else
    dofile(minetest.get_modpath("nv_universe") .. "/mapgen.lua")
end

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
 # UTILITIES
]]

local on_visit_planet_callbacks = {}

function nv_universe.register_on_visit_planet(callback)
    table.insert(on_visit_planet_callbacks, callback)
end

local function on_visit_planet(player, planet)
    for n, callback in ipairs(on_visit_planet_callbacks) do
        callback(player, planet)
    end
end

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
    nv_universe.store_player_state(player)
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
        -- return to space
        layer = nv_universe.try_allocate_space(seed)
        nv_universe.place_in_layer(layer)
        return
    end
    local placing = nv_universe.place_in_layer(layer)
    on_visit_planet(player, placing.planet)
    nv_universe.players[name].in_space = placing.in_space
    nv_universe.players[name].planet = placing.planet
    player:set_pos(placing.pos)
    nv_universe.set_planet_sky(player, placing.planet)
    nv_player.set_relative_gravity(player, nv_universe.get_planet_gravity(placing.planet))
    nv_universe.store_player_state(player)
end

local allowed_differences = {-257, -256, -255, -1, 0, 1, 255, 256, 257}
function nv_universe.check_travel_capability(player, new_seed)
    local name = player:get_player_name()
    if not nv_universe.players[name].in_space then
        return false
    end
    local current_planet = nv_universe.players[name].planet
    if current_planet == new_seed then
        return false
    end
    local origin_system = system_from_planet(current_planet)
    local destination_system = system_from_planet(new_seed)
    local neighbor = false
    for _, diff in ipairs(allowed_differences) do
        if (origin_system + diff) % 65536 == destination_system then
            neighbor = true
            break
        end
    end
    if not neighbor then
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
    nv_universe.store_player_state(player)
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
    on_visit_planet(player, placing.planet)
    local new_player = {
        in_space = placing.in_space,
        planet = placing.planet
    }
    local name = player:get_player_name()
    nv_universe.players[name] = new_player
    player:set_pos(placing.pos)
    local formspec
    if placing.in_space then
        nv_universe.set_space_sky(player, placing.planet)
        formspec = nv_universe.create_system_formspec(placing.planet, placing.planet)
    else
        nv_universe.set_planet_sky(player, placing.planet)
        formspec = nv_universe.create_planet_formspec(placing.planet)
    end
	nv_gui.set_inventory_formspec(player, "universe", formspec)
	nv_universe.store_player_state(player)
end

minetest.register_on_newplayer(newplayer_callback)

local function joinplayer_callback(player, last_login)
    if last_login == nil then
        return
    end
    local name = player:get_player_name()
    nv_universe.load_player_state(player)
    local planet = nv_universe.players[name].planet
    local system = system_from_planet(planet)
    local formspec
    if nv_universe.players[name].in_space then
        nv_universe.set_space_sky(player, planet)
        formspec = nv_universe.create_system_formspec(system, planet)
    else
        nv_universe.set_planet_sky(player, planet)
        formspec = nv_universe.create_planet_formspec(planet)
    end
	nv_gui.set_inventory_formspec(player, "universe", formspec)
end

minetest.register_on_joinplayer(joinplayer_callback)

local function leaveplayer_callback(player, timed_out)
    nv_universe.store_player_state(player)
end

minetest.register_on_leaveplayer(leaveplayer_callback)

local function dignode_callback(pos, oldnode, digger)
    local def = minetest.registered_nodes[oldnode.name]
    if def.nv_managed then
        return
    end
    local unipos = nv_universe.get_universal_coordinates(pos.y)
    nv_universe.mark_dug_node(unipos.in_space, unipos.planet, pos.x, unipos.y, pos.z)
end

minetest.register_on_dignode(dignode_callback)
