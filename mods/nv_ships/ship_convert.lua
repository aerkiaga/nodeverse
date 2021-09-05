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
        local r = {x=10*pos.x, y=10*pos.y, z=10*pos.z}
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
    if ship.state ~= "node" then
        return ship
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
                local node_name = ship.An[k]
                local ent_name = nv_ships.node_name_to_ent_name_dict[node_name]
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
    ship.pos = nil
    return ship
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

function nv_ships.rotate_ship_nodes(ship, facing)
    local function get_apply_rotation(rot)
        if rot == 0 then
            return function (x_rel, z_rel)
                return x_rel, z_rel
            end
        elseif rot == 1 then
            return function (x_rel, z_rel)
                return z_rel, -x_rel
            end
        elseif rot == 2 then
            return function (x_rel, z_rel)
                return -x_rel, -z_rel
            end
        else
            return function (x_rel, z_rel)
                return -z_rel, x_rel
            end
        end
    end

    local function rotate_param2(param2, rot)
        if param2 == nil then
            return nil
        end
        local facedir = param2 % 2^5
        local other = param2 - facedir
        local axis = math.floor(facedir / 4)
        local facing = facedir % 4
        local new_axis = axis
        local new_facing = facing
        if axis == 0 then
            new_facing = (facing + rot) % 4
        elseif axis == 5 then
            new_facing = (facing - rot) % 4
        else
            -- TODO: support more axes in 'rotate_param2()'
        end
        return other + 4*new_axis + new_facing
    end

    ----------------------------------------------------------------------------

    -- Closure to rotate coordinates
    local rot = (facing - ship.facing) % 4
    if rot == 0 then
        return
    end
    local apply_rotation = get_apply_rotation(rot)
    -- New size
    local new_size
    if rot % 2 == 1 then
        new_size = {x=ship.size.z, y=ship.size.y, z=ship.size.x}
    else
        new_size = {x=ship.size.x, y=ship.size.y, z=ship.size.z}
    end
    local abs_pos = ship.pos or {x=0, y=0, z=0}
    local abs_cockpit_pos = { -- is constant
        x = abs_pos.x + ship.cockpit_pos.x,
        y = abs_pos.y + ship.cockpit_pos.y,
        z = abs_pos.z + ship.cockpit_pos.z
    }
    -- New cockpit position
    local new_cockpit_pos = {y=ship.cockpit_pos.y}
    new_cockpit_pos.x, new_cockpit_pos.z = apply_rotation(
        ship.cockpit_pos.x - (ship.size.x-1)/2, ship.cockpit_pos.z - (ship.size.z-1)/2
    )
    new_cockpit_pos.x = new_cockpit_pos.x + (new_size.x-1)/2
    new_cockpit_pos.z = new_cockpit_pos.z + (new_size.z-1)/2
    -- New absolute position
    local new_pos = {
        x = abs_cockpit_pos.x - new_cockpit_pos.x,
        y = abs_cockpit_pos.y - new_cockpit_pos.y,
        z = abs_cockpit_pos.z - new_cockpit_pos.z
    }
    -- New ship nodes
    local new_An, new_A2 = {}, {}
    local x_out_stride = new_size.x
    local y_out_stride = new_size.y
    local k = 1
    for z_rel=0, ship.size.z - 1 do
        for y_rel=0, ship.size.y - 1 do
            for x_rel=0, ship.size.x - 1 do
                -- Compute output location
                local x_out_rel, z_out_rel = apply_rotation(
                    x_rel - ship.cockpit_pos.x, z_rel - ship.cockpit_pos.z
                )
                x_out_rel = x_out_rel + new_cockpit_pos.x
                z_out_rel = z_out_rel + new_cockpit_pos.z
                -- Copy node
                local k_out = z_out_rel*y_out_stride*x_out_stride
                + y_rel*x_out_stride + x_out_rel + 1
                new_An[k_out] = ship.An[k]
                new_A2[k_out] = rotate_param2(ship.A2[k], rot)
                k = k + 1
            end
        end
    end
    -- Update ship
    ship.size = new_size
    ship.pos = new_pos
    ship.cockpit_pos = new_cockpit_pos
    ship.facing = facing
    ship.An = new_An
    ship.A2 = new_A2
end

--[[
 # TO NODE
]]--

function nv_ships.ship_to_node(ship, player, pos)
    pos = pos or player:get_pos()
    
    local function try_place_ship(ship, pos, facing)
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

    ----------------------------------------------------------------------------

    pos = {x=math.floor(pos.x+0.5), y=math.floor(pos.y+0.5), z=math.floor(pos.z+0.5)}
    local yaw = player:get_look_horizontal()
    local facing = math.floor(-2*yaw/math.pi + 0.5) % 4

    ship.pos = {
        x = pos.x - ship.cockpit_pos.x,
        y = pos.y - ship.cockpit_pos.y,
        z = pos.z - ship.cockpit_pos.z
    }

    nv_ships.rotate_ship_nodes(ship, facing)

    local k = 1
    for z_abs=ship.pos.z, ship.pos.z + ship.size.z - 1 do
        for y_abs=ship.pos.y, ship.pos.y + ship.size.y - 1 do
            for x_abs=ship.pos.x, ship.pos.x + ship.size.x - 1 do
                local pos_abs = {x=x_abs, y=y_abs, z=z_abs}
                local node_name = ship.An[k]
                if node_name ~= nil then
                    local node_param2 = ship.A2[k]
                    minetest.add_node(pos_abs, {
                        name = node_name,
                        param1 = 15,
                        param2 = node_param2
                    })
                end
                k = k + 1
            end
        end
    end
    ship.state = "node"
    nv_ships.remove_ship_entity(player)
end
