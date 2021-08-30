function nv_ship_building.get_landing_position(player)
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

function nv_ship_building.try_board_ship(pos, player)
    minetest.remove_node(pos)
    local ent_seat = minetest.add_entity(pos, "nv_ship_building:ent_seat")
    player:set_pos(pos)
    ent_seat:set_attach(player)
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
        name = "nv_ship_building:seat",
        param1 = 0, param2 = facing
    })
    return true
end

function nv_ship_building.try_unboard_ship(player)
    local pos = player:get_pos()
    local yaw = player:get_look_horizontal()
    local facing = math.floor(-2*yaw/math.pi + 0.5) % 4
    if try_place_ship_at(pos, facing) then
        local children = player:get_children()
        for index, child in ipairs(children) do
            local properties = child:get_properties() or {}
            if true then
                child:set_detach(player)
                child:remove()
            end
        end
        player:set_local_animation(
            {x = 0,   y = 79},
            {x = 168, y = 187},
            {x = 189, y = 198},
            {x = 200, y = 219},
            30
        )
        return true
    else
        return false
    end
end
