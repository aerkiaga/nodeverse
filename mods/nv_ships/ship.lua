--[[
This file defines ships as objects that can be converted between a node form and
an entity form. Each ship uniquely belongs to a player, and can be built (in
node form), boarded (entered in node form), lifted off (converted to entity
form), flown (in entity form), landed (converted to node form) and unboarded
(exited in node form).
Most of this functionality is defined in the files included from here, not in
this file itself, which only contains functions that relate to flying (see
'control.lua' for the actual flying code).
Included files:
    ship_build.lua      Code for building ships
    ship_check.lua      Code for scanning and checking ship nodes
    ship_convert.lua    Code for converting ships between node and entity forms

 # INDEX
    LANDING HELPER
    BOARDING
]]

dofile(minetest.get_modpath("nv_ships") .. "/ship_build.lua")
dofile(minetest.get_modpath("nv_ships") .. "/ship_check.lua")
dofile(minetest.get_modpath("nv_ships") .. "/ship_convert.lua")

--[[
A table of players, indexed by name. Each value contains the following fields:
    ships       List of ships owned by player; see below for format
    state       Either 'nil', "landed", "flying" or "landing"
    cur_ship    If 'state' is not 'nil', this is the ship boarded by the player
    sound       Handle to the ship sound currently playing
]]--
nv_ships.players_list = {}
minetest.safe_file_write(minetest.get_worldpath() .. "/nv_ships.players_list", minetest.serialize(nv_ships.players_list))

--[[
Ship format:
    owner       name of the player that owns this ship
    index       index of ship in player's ship list (if present in list)
    state       what the ship currently is made of, "entity" or "node"
    size        size in nodes, as xyz vector
    pos         if state == "node", lowest xyz of ship bounding box in world
    unipos      optional; if 'nv_universe' is enabled, universal coordinates
    An          flat array of node names in ship bounding box (only part of ship)
    A2          flat array of param2's in ship bounding box (only part of ship)
    ----------- The remaining values are calculated in 'ship_check.lua'
    cockpit_pos relative xyz of cockpit base node, or 'nil' if no cockpit
    facing      copy of param2 value at cockpit base node, modulo 4 (or nil)
]]--

--[[
 # LANDING HELPER

Given a ship in entity form and a player flying on it, computes a suitable
landing position below it. This is the position where the cockpit base node
should lie so that:
 - No node of the ship overlaps with a walkable or liquid node.
 - At least one node of the ship is right on top of a walkable or liquid node.
It can be shown that such a location always exists for every ship and terrain
vertically below it.
]]

function nv_ships.get_landing_position(ship, player, pos)
    pos = pos or player:get_pos()

    local function how_should_move_vertically()
        local x_stride = ship.size.x
        local y_stride = ship.size.y
        local there_is_resting_block = false
        local ship_pos = {
            x = pos.x - ship.cockpit_pos.x,
            y = pos.y - ship.cockpit_pos.y,
            z = pos.z - ship.cockpit_pos.z
        }
        for z_rel=0, ship.size.z-1 do
            for x_rel=0, ship.size.x-1 do
                local block_below = false
                for y_rel=-1, ship.size.y-1 do
                    local abs_pos = {
                        x = x_rel + ship_pos.x,
                        y = y_rel + ship_pos.y,
                        z = z_rel + ship_pos.z,
                    }
                    local world_node = minetest.get_node(abs_pos)
                    local world_node_def = minetest.registered_nodes[world_node.name]
                    local ship_node = nil
                    if y_rel ~= -1 then
                        local k = z_rel*y_stride*x_stride + y_rel*x_stride + x_rel + 1
                        ship_node = ship.An[k]
                    end
                    if (world_node_def.walkable or world_node_def.drawtype == "liquid")
                    and (world_node_def.groups.can_replace or 0) == 0 then
                        if ship_node ~= nil and ship_node ~= "" then
                            return 1 -- must move up
                        end
                        block_below = true
                    else
                        if block_below and ship_node ~= nil then
                            there_is_resting_block = true
                        end
                        block_below = false
                    end
                end
            end
        end
        if there_is_resting_block then
            return 0 -- perfect
        else
            return -1 -- move down
        end
    end

    ----------------------------------------------------------------------------

    local yaw = player:get_look_horizontal()
    local facing = math.floor(-2*yaw/math.pi + 0.5) % 4
    nv_ships.rotate_ship_nodes(ship, facing)

    pos = {x=math.floor(pos.x+0.5), y=math.floor(pos.y+0.5), z=math.floor(pos.z+0.5)}
    -- Move down to the ground
    local found_ground = false
    for y=pos.y, pos.y - 64, -1 do
        pos.y = y
        local node = minetest.get_node(pos)
        local node_def = minetest.registered_nodes[node.name]
        if node_def.walkable or node_def.drawtype == "liquid" then
            found_ground = true
            break
        end
    end
    if not found_ground then
        return nil
    end
    -- Move up or down until the ship lies nicely on the ground
    while true do
        local delta_y = how_should_move_vertically()
        if delta_y == 0 then
            break
        end
        pos.y = pos.y + delta_y
    end
    return pos
end

function nv_ships.get_ship_collisionbox(ship)
    local function rotate_coordinates(facing, coords)
        local r = {x=coords.x, y=coords.y, z=coords.z}
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

--[[
 # BOARDING
]]--

function nv_ships.load_ship_pos(ship)
    if nv_universe ~= nil and ship.pos ~= nil and ship.unipos ~= nil then
        ship.pos.y = nv_universe.get_absolute_coordinates(ship.unipos)
    end
end

function nv_ships.poll_ship_pos(ship)
    if nv_universe ~= nil and ship.pos ~= nil and ship.unipos ~= nil then
        ship.pos.y = nv_universe.poll_absolute_coordinates(ship.unipos)
    end
end

function nv_ships.load_ship_unipos(ship)
    if nv_universe ~= nil then
        ship.unipos = nv_universe.get_universal_coordinates(ship.pos.y)
    end
end

function nv_ships.try_board_ship(pos, player)
    -- Identify what ship the particular node belongs to
    -- Must belong to the given player
    local function identify_ship(player_name)
        for index, ship in ipairs(nv_ships.players_list[player_name].ships) do
            nv_ships.load_ship_pos(ship)
            if ship.state == "node" then
                local ship_maxp = {
                    x = ship.pos.x + ship.size.x - 1,
                    y = ship.pos.y + ship.size.y - 1,
                    z = ship.pos.z + ship.size.z - 1,
                }
                -- Check bounding box
                if ship.pos.x <= pos.x and pos.x <= ship_maxp.x
                and ship.pos.y <= pos.y and pos.y <= ship_maxp.y
                and ship.pos.z <= pos.z and pos.z <= ship_maxp.z then
                    local rel_pos = {
                        x = pos.x - ship.pos.x,
                        y = pos.y - ship.pos.y,
                        z = pos.z - ship.pos.z
                    }
                    local x_stride = ship.size.x
                    local y_stride = ship.size.y
                    local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
                    -- Check actual node (bounding boxes can overlap, nodes can't!)
                    if ship.An[k] ~= "" then
                        return ship
                    end
                end
            end
        end
        return nil
    end

    ----------------------------------------------------------------------------

    local name = player:get_player_name()
    local ship = identify_ship(name)
    if ship == nil then
        return nil
    end
    if ship.cockpit_pos == nil then
        return nil
    end
    local cockpit_pos_abs = {
        x = ship.cockpit_pos.x + ship.pos.x,
        y = ship.cockpit_pos.y + ship.pos.y,
        z = ship.cockpit_pos.z + ship.pos.z
    }
    player:set_pos(cockpit_pos_abs)
    return ship
end

function nv_ships.try_unboard_ship(player)
    local name = player:get_player_name()
    local ship = nv_ships.players_list[name].cur_ship
    nv_ships.load_ship_pos(ship)
    local player_pos = player:get_pos()
    local ship_min_pos = ship.pos
    local ship_max_pos = {
        x = ship_min_pos.x + ship.size.x - 1,
        y = ship_min_pos.y + ship.size.y - 1,
        z = ship_min_pos.z + ship.size.z - 1
    }
    local best_pos = nil
    local best_distance = 9999
    local best_is_liquid = true
    local best_is_ship = true
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    for current_z = ship_min_pos.z - 3, ship_max_pos.z + 3 do
        for current_x = ship_min_pos.x - 3, ship_max_pos.x + 3 do
            local vertical_space = 0
            for current_y = ship_max_pos.y + 3, ship_min_pos.y - 4, -1 do
                local abs_pos = {
                    x = current_x,
                    y = current_y,
                    z = current_z
                }
                local world_node = minetest.get_node(abs_pos)
                local world_node_def = minetest.registered_nodes[world_node.name]

                -- Stepping on liquid nodes has lowest priority
                local candidate_is_liquid = (world_node_def.drawtype == "liquid")
                if candidate_is_liquid and not best_is_liquid then
                    break
                end

                if world_node_def.walkable or world_node_def.drawtype == "liquid" then
                    if vertical_space >= 2 then
                        -- Stepping on ship nodes has lower priority
                        local candidate_is_ship = false
                        local rel_pos = {
                            x = current_x - ship_min_pos.x,
                            y = current_y - ship_min_pos.y,
                            z = current_z - ship_min_pos.z
                        }
                        if rel_pos.x >= 0 and rel_pos.x <= ship.size.x
                        and rel_pos.y >= 0 and rel_pos.y <= ship.size.y
                        and rel_pos.z >= 0 and rel_pos.z <= ship.size.z then
                            local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
                            local ship_node = ship.An[k]
                            candidate_is_ship = (ship_node ~= "")
                        end
                        if candidate_is_ship and not best_is_ship then
                            break
                        end

                        -- The nearest position is chosen
                        local candidate_pos = {
                            x = current_x,
                            y = current_y + 1,
                            z = current_z
                        }
                        local candidate_distance = math.sqrt(
                            (current_x - player_pos.x)^2
                            + (current_y - player_pos.y)^2
                            + (current_z - player_pos.z)^2
                        )
                        if candidate_distance >= best_distance
                        and not (best_is_liquid and not candidate_is_liquid) then
                            break
                        end
                        best_pos = candidate_pos
                        best_distance = candidate_distance
                        best_is_liquid = candidate_is_liquid
                        best_is_ship = candidate_is_ship or candidate_is_liquid
                    end
                    break
                else
                    vertical_space = vertical_space + 1
                end
            end
        end
    end
    if best_pos == nil then
        return false
    end
    player:set_pos(best_pos)
    return true
end
