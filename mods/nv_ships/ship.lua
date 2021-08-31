--[[
This file defines ships as objects that can be converted between a node form and
an entity form. Each ship uniquely belongs to a player, and can be built (in
node form) boarded (converted to entity form), flown (in entity form) and
unboarded (converted to node form).
Most of this functionality is defined in the files included from here, not in
this file itself, which only contains functions that relate to flying (see
'control.lua' for the actual flying code).
Included files:
    ship_build.lua      Code for building ships
    ship_board.lua      Code for boarding/unboarding ships
]]

dofile(minetest.get_modpath("nv_ships") .. "/ship_build.lua")
dofile(minetest.get_modpath("nv_ships") .. "/ship_board.lua")

--[[
A table of players, indexed by name. Each value contains the following fields:
    ships       List of ships owned by player; see below for format
]]--
nv_ships.players_list = {}

--[[
Ship format:
    owner       name of the player that owns this ship
    index       index of ship in player's ship list
    state       what the ship currently is made of, "entity" or "node"
    size        size in nodes, as xyz vector
    pos         if state == "node", lowest xyz of ship bounding box in world
    cockpit_pos relative xyz of cockpit base node, or 'nil' if no cockpit
    facing      copy of param2 value at cockpit base node, modulo 4 (or nil)
    A           flat array of node IDs in ship bounding box (only part of ship)
    A2          flat array of param2's in ship bounding box (only part of ship)
]]--

function nv_ships.get_landing_position(player)
    local pos = player:get_pos()
    for y=pos.y, pos.y - 64, -1 do
        pos.y = y
        local node = minetest.get_node(pos)
        if minetest.registered_nodes[node.name].walkable then
            return pos
        end
    end
    return nil
end

function nv_ships.get_ship_collisionbox(ship)
    local function rotate_coordinates(facing, coords)
        r = {x=coords.x, y=coords.y, z=coords.z}
        if facing / 2 >= 1 then
            r = {x=-r.x, y=r.y, z=-r.z}
        end
        if facing % 2 == 1 then
            r = {x=-r.z, y=r.y, z=r.x}
        end
        return r
    end

    ----------------------------------------------------------------------------

    local mincoords = {
        x = -ship.cockpit_pos.x - 0.5,
        y = -ship.cockpit_pos.y - 0.5,
        z = -ship.cockpit_pos.z - 0.5
    }
    local maxcoords = {
        x = ship.size.x - ship.cockpit_pos.x - 0.5,
        y = ship.size.y - ship.cockpit_pos.y - 0.5,
        z = ship.size.z - ship.cockpit_pos.z - 0.5
    }
    mincoords = rotate_coordinates(ship.facing, mincoords)
    maxcoords = rotate_coordinates(ship.facing, maxcoords)
    return {
        mincoords.x, mincoords.y, mincoords.z,
        maxcoords.x, maxcoords.y, maxcoords.z
    }
end
