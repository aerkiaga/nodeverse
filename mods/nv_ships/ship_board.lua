--[[
This file defines functions that perform conversion between node and entity
forms of a ship, as well as some related operations.
]]--

function nv_ships.try_board_ship(pos, player)
    local function identify_ship(pos, player_name)
        for index, ship in ipairs(nv_ships.players_list[player_name].ships) do
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
                    if ship.A[k] ~= nil then
                        return ship
                    end
                end
            end
        end
        return nil
    end

    ----------------------------------------------------------------------------

    local name = player:get_player_name()
    local ship = identify_ship(pos, name)
    if ship == nil then
        return false
    end
    if ship.cockpit_pos == nil then
        return false
    end
    local cockpit_pos_abs = {
        x = ship.cockpit_pos.x + ship.pos.x,
        y = ship.cockpit_pos.y + ship.pos.y,
        z = ship.cockpit_pos.z + ship.pos.z
    }
    player:set_pos(cockpit_pos_abs)

    local k = 1
    for z_abs=ship.pos.z, ship.pos.z + ship.size.z - 1 do
        local z_cockpit_rel = z_abs - cockpit_pos_abs.z
        for y_abs=ship.pos.y, ship.pos.y + ship.size.y - 1 do
            local y_cockpit_rel = y_abs - cockpit_pos_abs.y
            for x_abs=ship.pos.x, ship.pos.x + ship.size.x - 1 do
                local x_cockpit_rel = x_abs - cockpit_pos_abs.x
                local node_id = ship.A[k]
                local ent_name = nv_ships.node_id_to_ent_name_dict[node_id]
                if ent_name ~= nil then
                    local pos_abs = {x=x_abs, y=y_abs, z=z_abs}
                    minetest.remove_node(pos_abs)
                    local ent = minetest.add_entity(pos_abs, ent_name)
                    local pos_cockpit_rel = {
                        x = 10*x_cockpit_rel,
                        y = 10*y_cockpit_rel,
                        z = 10*z_cockpit_rel
                    }
                    ent:set_attach(player, "", pos_cockpit_rel, nil, true)
                end
                k = k + 1
            end
        end
    end
    return true
end

local function try_place_ship_at(pos, facing)
    -- 'facing' values: 0, 1, 2, 3
    -- +Z, +X, -Z, -X
    local node = minetest.get_node(pos)
    if minetest.registered_nodes[node.name].walkable then
        return false
    end
    minetest.set_node(pos, {
        name = "nv_ships:seat",
        param1 = 0, param2 = facing
    })
    return true
end

function nv_ships.remove_ship_entity(player)
    local children = player:get_children()
    for index, child in ipairs(children) do
        local properties = child:get_properties() or {}
        if true then
            child:set_detach(player)
            child:remove()
        end
    end
end

function nv_ships.try_unboard_ship(player)
    local pos = player:get_pos()
    local yaw = player:get_look_horizontal()
    local facing = math.floor(-2*yaw/math.pi + 0.5) % 4
    if try_place_ship_at(pos, facing) then
        nv_ships.remove_ship_entity(player)
        return true
    else
        return false
    end
end
