local function tree_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local base = area.MinEdge
    local extent = area:getExtent()
    -- Get uniformized ground height
    local uni_ground = 0
    local count = 0
    for z=minp.z,maxp.z do
        for x=minp.x,maxp.x do
            local k = (z - base.z) * extent.x + x - base.x + 1
            local ground = ground_buffer[k]
            uni_ground = uni_ground + ground
            count = count + 1
        end
    end
    uni_ground = math.floor(uni_ground / count)
    uni_ground = uni_ground - (uni_ground % 4)
    if uni_ground < custom.min_height or uni_ground > custom.max_height then
        return
    end
    -- Attempt to create stem
    local stem_x = origin.x + math.floor(custom.side / 2)
    local stem_z = origin.z + math.floor(custom.side / 2)
    local stem_height = custom.stem_height + math.floor(((stem_x + stem_z * 45) % 4) / 2 - 0.5)
    if not (stem_x < minp.x or stem_x > maxp.x
    or stem_z < minp.z or stem_z > maxp.z) then
        local k = (stem_z - base.z) * extent.x + stem_x - base.x + 1
        local ground = math.floor(ground_buffer[k])
        for y=math.max(ground + 1 - mapping.offset.y, minp.y),math.min(uni_ground + stem_height - mapping.offset.y, maxp.y),1 do
            local i = area:index(stem_x, y, stem_z)
            local yrot = (stem_x * 23 + y * 67 + stem_z * 749) % 4
            if A[i] == nil
            or A[i] == minetest.CONTENT_AIR
            or minetest.registered_nodes[minetest.get_name_from_content_id(A[i])].buildable_to then
                A[i] = custom.stem_node
                A2[i] = yrot + custom.stem_color * 4
            end
        end
    end
    -- Create rays
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
            while length <= custom.ray_length do
                if not(cur_x < minp.x or cur_x > maxp.x
                or cur_y < minp.y or cur_y > maxp.y
                or cur_z < minp.z or cur_z > maxp.z) then
                    local i = area:index(math.floor(cur_x + 0.5), math.floor(cur_y + 0.5), math.floor(cur_z + 0.5))
                    local yrot = math.floor((cur_x * 23 + cur_y * 67 + cur_z * 749) % 4)
                    if A[i] == nil
                    or A[i] == minetest.CONTENT_AIR then
                        A[i] = custom.leaves_node
                        A2[i] = yrot + custom.leaves_color * 4
                    end
                end
                length = length + math.sqrt(delta_x^2 + delta_y^2 + delta_z^2)
                cur_x = cur_x + delta_x / 2
                cur_y = cur_y + delta_y / 2
                cur_z = cur_z + delta_z / 2
                delta_y = delta_y + custom.ray_fall / 2
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
        r.density = 1/(G:next(1, 5)^2)
    else
        r.density = 1/(G:next(5, 20)^2)
    end
    r.seed = 638262 + index
    r.order = 100
    r.callback = tree_callback
    -- Tree-specific
    r.stem_color = colors[G:next(1, #colors)]
    if r.stem_color > 16 then
        r.stem_color = math.floor(r.stem_color / 2)
    end
    r.leaves_color = colors[G:next(1, #colors)]
    r.stem_node = gen_weighted(G, {
        [nv_flora.node_types.woody_stem] = 2,
        [nv_flora.node_types.veiny_stem] = 1
    })
    r.leaves_node = gen_weighted(G, {
        [nv_flora.node_types.soft_leaves] = 1
    })
    if meta.has_oceans then
        r.min_height = G:next(1, 4)^2
        r.max_height = r.min_height + G:next(1, 3)^2
    else
        r.min_height = G:next(1, 6)^2 - 18
        r.max_height = r.min_height + G:next(1, 5)^2
    end
    r.stem_height = G:next(2, 4)^2
    r.ray_length = G:next(3, r.stem_height)
    r.ray_count = G:next(2, 6)^2 + G:next(1, 4)
    r.row_count = G:next(1, 5)^2
    r.min_pitch = gen_linear(G, -math.pi / 2, 0)
    r.max_pitch = gen_linear(G, r.min_pitch, math.pi / 2)
    r.ray_twist = gen_linear(G, 0, 2 * math.pi / r.ray_count)
    r.ray_fall = gen_linear(G, -0.5, 0)
    r.side = 2 * r.ray_length + 1
    return r
end
