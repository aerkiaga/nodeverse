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
