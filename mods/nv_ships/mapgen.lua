local function post_processing_callback(minp, maxp, area, offset, A, A1, A2, mapping, planet, ground_buffer)
    local f = io.open(minetest.get_worldpath() .. "/nv_ships.players_list", "rt")
    local players_list = minetest.deserialize(f:read())
    f:close()
    for name, player_data in pairs(players_list) do
        for index, ship in ipairs(player_data.ships) do
            --nv_ships.poll_ship_pos(ship)
            if ship.pos ~= nil and ship.state == "node" then
                local x_stride = ship.size.x
                local y_stride = ship.size.y
                for z_abs=math.max(minp.z, ship.pos.z),math.min(maxp.z, ship.pos.z + ship.size.z - 1),1 do
                    for y_abs=math.max(minp.y, ship.pos.y),math.min(maxp.y, ship.pos.y + ship.size.y - 1),1 do
                        for x_abs=math.max(minp.x, ship.pos.x),math.min(maxp.x, ship.pos.x + ship.size.x - 1),1 do
                            local rel_pos = {
                                x = x_abs - ship.pos.x,
                                y = y_abs - ship.pos.y,
                                z = z_abs - ship.pos.z
                            }
                            local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
                            local i = area:index(x_abs, y_abs, z_abs)
                            if ship.An[k] ~= "" then
                                A[i] = minetest.get_content_id(ship.An[k])
                                A2[i] = ship.A2[k]
                            end
                        end
                    end
                end
            end
        end
    end
end

if nv_planetgen ~= nil then
    nv_planetgen.register_post_processing(post_processing_callback)
end
