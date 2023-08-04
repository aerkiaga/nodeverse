--[[
This pass adds a final touch to all nodes, including lighting, random rotation,
and correct colors.

 # INDEX
    ENTRY POINT
]]

--[[
 # ENTRY POINT
]]--

function nv_planetgen.pass_final(
    minp_abs, maxp_abs, area, offset, A, A1, A2, mapping, planet, ground_buffer
)
    local minpx, minpy, minpz = minp_abs.x, minp_abs.y, minp_abs.z
    local maxpx, maxpy, maxpz = maxp_abs.x, maxp_abs.y, maxp_abs.z

    local minp_x = mapping.minp.x
    local minp_z = mapping.minp.z
    local maxp_x = mapping.maxp.x
    local maxp_z = mapping.maxp.z

    local is_walled = mapping.walled
    local is_scorching = (planet.atmosphere == "scorching")
    local node_air = minetest.CONTENT_AIR
    local offset_x, offset_y, offset_z = offset.x, offset.y, offset.z

    local G = PcgRandom(5683749)

    local base = area.MinEdge
    local extent = area:getExtent()
    for z_abs=minpz, maxpz do
        for x_abs=minpx, maxpx do
            local k = (z_abs - base.z) * extent.x + x_abs - base.x + 1
            local ground = math.floor(ground_buffer[k])
            ground = math.max(ground, 0)
            local maxpy_new = math.min(maxpy, ground - offset.y + 10)
            if maxpy_new >= minpy then
                for y_abs=minpy, maxpy_new do
                    local i = area:index(x_abs, y_abs, z_abs)
                    local Ai = A[i]
                    if Ai ~= node_air then
                        local pos_x = x_abs + offset_x
                        local pos_y = y_abs + offset_y
                        local pos_z = z_abs + offset_z

                        -- Generate walls around mappings
                        if is_walled and (
                            x_abs == minp_x or x_abs == maxp_x
                            or z_abs == minp_z or z_abs == maxp_z
                        ) then
                            A[i] = planet.node_types.stone
                        end

                        -- Apply lighting
                        if is_scorching and A[i] == planet.node_types.liquid then
                            A1[i] = 143
                        else
                            A1[i] = 15
                        end

                        -- Apply random texture rotation to all supported nodes
                        local rot = nv_planetgen.random_yrot_nodes[A[i]]
                        local param2 = A2[i]
                        if rot ~= nil then
                            param2 = G:next() % rot
                            if rot == 2 then
                                param2 = param2 * 2
                            end
                        end

                        -- Apply palette color to all supported nodes
                        local color = planet.color_dictionary[A[i]]
                        if color ~= nil then
                            local multiplier = nv_planetgen.color_multiplier[A[i]] or 1
                            color = color * multiplier
                            param2 = param2 + color
                        end

                        A2[i] = param2
                    end -- if
                end -- for
            end --if
        end -- for
    end -- for
end
