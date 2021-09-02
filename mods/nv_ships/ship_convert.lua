--[[
This file defines functions that perform conversion between node and entity
forms of a ship, as well as some related operations.

 # INDEX
    TO ENTITY
    TO NODE
]]--

--[[
 # TO ENTITY
]]--

function nv_ships.ship_to_entity(ship, player)
    local function to_player_coordinates(facing, pos)
        r = {x=10*pos.x, y=10*pos.y, z=10*pos.z}
        if facing / 2 >= 1 then
            r = {x=-r.x, y=r.y, z=-r.z}
        end
        if facing % 2 == 1 then
            r = {x=-r.z, y=r.y, z=r.x}
        end
        return r
    end

    ----------------------------------------------------------------------------

    local name = player:get_player_name()
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

    local k = 1
    for z_abs=ship.pos.z, ship.pos.z + ship.size.z - 1 do
        local z_cockpit_rel = z_abs - cockpit_pos_abs.z
        for y_abs=ship.pos.y, ship.pos.y + ship.size.y - 1 do
            local y_cockpit_rel = y_abs - cockpit_pos_abs.y
            for x_abs=ship.pos.x, ship.pos.x + ship.size.x - 1 do
                local x_cockpit_rel = x_abs - cockpit_pos_abs.x
                local pos_player_rel = to_player_coordinates(ship.facing, {
                    x = x_cockpit_rel, y = y_cockpit_rel, z = z_cockpit_rel
                })
                local node_id = ship.A[k]
                local ent_name = nv_ships.node_id_to_ent_name_dict[node_id]
                if ent_name ~= nil then
                    local pos_abs = {x=x_abs, y=y_abs, z=z_abs}
                    minetest.remove_node(pos_abs)
                    local ent = minetest.add_entity(pos_abs, ent_name)
                    ent:set_attach(player, "", pos_player_rel, nil, true)
                end
                k = k + 1
            end
        end
    end
    ship.state = "entity"
    return ship
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

--[[
 # TO NODE
]]--

function nv_ships.ship_to_node(ship, player)
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
