local function post_processing_callback(minp, maxp, area, offset, A, A1, A2, mapping, planet, ground_buffer)
    local dug = minetest.deserialize(minetest.get_mapgen_setting("nv_universe.dug"))
    if not dug[false] then
        return
    end
    for p, cur in pairs(dug[false]) do
        if p == planet.seed then
            for y, cur2 in pairs(cur) do
                if y - offset.y >= minp.y and y - offset.y <= maxp.y then
                    for z, cur3 in pairs(cur2) do
                        if z >= minp.z and z <= maxp.z then
                            for x, t in pairs(cur3) do
                                local i = area:index(x, y - offset.y, z)
                                local def = minetest.registered_nodes[minetest.get_name_from_content_id(A[i])]
                                if not def.nv_managed then
                                    A[i] = minetest.CONTENT_AIR
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

nv_planetgen.register_post_processing(post_processing_callback)
