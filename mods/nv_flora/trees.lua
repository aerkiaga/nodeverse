local function tree_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local G = PcgRandom(custom.seed, origin.x + 6489 * origin.x)
    local base = area.MinEdge
    local extent = area:getExtent()
    local stem_x = origin.x + math.floor(custom.side / 2)
    local stem_z = origin.z + math.floor(custom.side / 2)
    
    -- Get uniformized ground height
    local uni_ground = nv_planetgen.get_ground_level(planet, stem_x, stem_z)
    if uni_ground < custom.min_height or uni_ground > custom.max_height then
        return
    end
    -- Attempt to create stem
    local stem_min_x = stem_x - math.floor((custom.stem_width - 1) / 2)
    local stem_min_z = stem_z - math.floor((custom.stem_width - 1) / 2)
    local stem_max_x = stem_x + math.floor(custom.stem_width / 2)
    local stem_max_z = stem_z + math.floor(custom.stem_width / 2)
    local stem_height = custom.stem_height + math.floor(((stem_x + stem_z * 45) % 4) / 2 - 0.5)
    for z=math.max(stem_min_z, minp.z),math.min(stem_max_z, maxp.z),1 do
        for x=math.max(stem_min_x, minp.x),math.min(stem_max_x, maxp.x),1 do
            local k = (z - base.z) * extent.x + x - base.x + 1
            local ground = math.floor(ground_buffer[k])
            for y=math.max(ground + 1 - mapping.offset.y, minp.y),math.min(uni_ground + stem_height - mapping.offset.y, maxp.y),1 do
                local i = area:index(x, y, z)
                local yrot = ((y * 547 + x + z) % 131) * 583 % 13 % 4
                if A[i] == nil
                or A[i] == minetest.CONTENT_AIR
                or minetest.registered_nodes[minetest.get_name_from_content_id(A[i])].buildable_to then
                    A[i] = custom.stem_node
                    A2[i] = yrot + custom.stem_color * 4
                end
            end
        end
    end
    -- Create rays
    if custom.stem_width % 2 == 0 then
        stem_x = stem_x + 0.5
        stem_z = stem_z + 0.5
    end
    for m=1,custom.row_count do
        local pitch = m * (custom.max_pitch - custom.min_pitch) / custom.row_count + custom.min_pitch
        for n=1,custom.ray_count do
            local angle = n * 2 * math.pi / custom.ray_count + m * custom.ray_twist
            local delta_x = math.cos(angle)
            local delta_y = math.sin(pitch)
            local delta_z = math.sin(angle)
            local length = 0
            local cur_x = stem_x
            local cur_y = uni_ground + stem_height - mapping.offset.y
            local cur_z = stem_z
            local number = gen_linear(G, 0, 1)
            while length <= custom.ray_length do
                if not(cur_x < minp.x or cur_x > maxp.x
                or cur_y < minp.y or cur_y > maxp.y
                or cur_z < minp.z or cur_z > maxp.z) then
                    local i = area:index(math.floor(cur_x + 0.5), math.floor(cur_y + 0.5), math.floor(cur_z + 0.5))
                    local yrot = math.floor((cur_x * 23 + cur_y * 67 + cur_z * 749) % 4)
                    if A[i] == nil
                    or A[i] == minetest.CONTENT_AIR then
                        A[i] = custom.leaves_node
                        if length > custom.leaves_inner * custom.ray_length and gen_linear(G, 0, 1) < custom.leaves_prob then
                            A2[i] = yrot + custom.leaves_color2 * 4
                        else
                            A2[i] = yrot + custom.leaves_color * 4
                        end
                    end
                    if A[i] == custom.leaves_node
                    and length < custom.branch_length
                    and number < custom.stem_ray_prob
                    and (custom.row_count == 1 or m ~= custom.row_count) then
                        A[i] = custom.stem_node
                        A2[i] = yrot + custom.stem_color * 4
                    end
                end
                length = length + math.sqrt(delta_x^2 + delta_y^2 + delta_z^2) / 2
                cur_x = cur_x + delta_x / 2
                cur_y = cur_y + delta_y / 2
                cur_z = cur_z + delta_z / 2
                delta_x = math.max(math.min(delta_x + gen_linear(G, -custom.ray_wiggle, custom.ray_wiggle), 1), -1)
                delta_z = math.max(math.min(delta_z + gen_linear(G, -custom.ray_wiggle, custom.ray_wiggle), 1), -1)
                delta_y = math.max(delta_y + custom.ray_fall / 2, -1)
            end
        end
    end
end

function nv_flora.get_tree_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    if meta.life == "lush" then
        r.density = 1/(G:next(1, 4)^2)
    else
        r.density = 1/(G:next(4, 13)^2)
    end
    r.seed = 638262 + index
    r.order = 100
    r.callback = tree_callback
    -- Tree-specific
    local planet_weirdness = gen_linear(PcgRandom(seed, seed), 0.6, 1.6) ^ 3
    r.is_mushroom = gen_weighted(G, {[true] = 1 * planet_weirdness, [false] = 2 / planet_weirdness})
    r.stem_color = colors[G:next(1, #colors)]
    r.stem_ray_prob = 0
    if r.stem_color > 16 then
        r.stem_color = math.floor(r.stem_color / 2)
    end
    r.leaves_color = colors[G:next(1, #colors)]
    r.leaves_color2 = colors[G:next(1, #colors)]
    r.leaves_inner = (G:next(0, 10)/10)^1.5
    r.leaves_prob = 0.8 - r.leaves_inner^2
    if r.leaves_prob < 0.67 then
        r.leaves_prob = 1
    end
    if r.is_mushroom then
        if r.leaves_color > 16 then
            r.leaves_color = math.floor(r.leaves_color / 2)
        end
        r.stem_node = gen_weighted(G, {
            [nv_flora.node_types.veiny_stem] = 1
        })
        r.leaves_node = gen_weighted(G, {
            [nv_flora.node_types.smooth_cap] = 1
        })
        r.ray_count = 100
        r.row_count = G:next(1, 2)^2
    else
        r.stem_node = gen_weighted(G, {
            [nv_flora.node_types.woody_stem] = 2,
            [nv_flora.node_types.veiny_stem] = 1
        })
        r.leaves_color2 = r.leaves_color
        r.leaves_node = gen_weighted(G, {
            [nv_flora.node_types.soft_leaves] = 1
        })
        r.ray_count = G:next(2, 6)^2 + G:next(1, 4)
        r.stem_ray_prob = 1 / (r.ray_count/gen_linear(G, 3, 5) + 1)
        if r.ray_count >= 9 then
            r.row_count = G:next(3, 5)^2
        else
            r.row_count = G:next(1, 4)^2
        end
    end
    if meta.has_oceans then
        r.min_height = G:next(1, 4)^2
        r.max_height = r.min_height + G:next(1, 3)^2
    else
        r.min_height = G:next(1, 6)^2 - 18
        r.max_height = r.min_height + G:next(1, 5)^2
    end
    r.stem_height = G:next(2, 5)^2
    r.ray_length = G:next(4, r.stem_height + 2)
    r.branch_length = r.ray_length * gen_linear(G, 0.2, 0.4)
    if r.ray_length < 9 then
        r.stem_width = 1
    else
        r.stem_width = 2
    end
    r.min_pitch = gen_linear(G, -math.pi / 2, 0)
    r.max_pitch = gen_linear(G, 2 * r.min_pitch / 3 + math.pi / 6, math.pi / 2)
    r.ray_twist = gen_linear(G, 0, 2 * math.pi / r.ray_count)
    if r.row_count == 1 then
        r.ray_fall = gen_linear(G, -0.7, -0.1)
    else
        r.ray_fall = gen_linear(G, -0.4, 0.1)
    end
    if r.is_mushroom then
        r.ray_wiggle = gen_linear(G, 0, 0.1) ^ 2
    else
        r.ray_wiggle = gen_linear(G, 0, 0.5) ^ 2
    end
    r.side = 2 * r.ray_length + 3
    return r
end
