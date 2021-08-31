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
    A           flat array of node IDs in ship bounding box (only part of ship)
    A2          flat array of param2's in ship bounding box (only part of ship)
]]--

dofile(minetest.get_modpath("nv_ships") .. "/ship_build.lua")
dofile(minetest.get_modpath("nv_ships") .. "/ship_board.lua")

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
