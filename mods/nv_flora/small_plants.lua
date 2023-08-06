local function small_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local x = minp.x
    local z = minp.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local k = (z - base.z) * extent.x + x - base.x + 1
    local ground = math.floor(ground_buffer[k])
    if ground < custom.min_height or ground > custom.max_height then
        return
    end
    if minp.y + mapping.offset.y > ground + (custom.max_plant_height or 256) or maxp.y + mapping.offset.y < ground - (custom.max_plant_depth or 256) then
        return
    end
    local yrot = (x * 23 + z * 749) % 24
    local color_index = (custom.color - 1) % 8
    for y=math.max(ground - mapping.offset.y, minp.y),math.min(ground + 1 - mapping.offset.y, maxp.y),1 do
        local i = area:index(x, y, z)
        local node_name = minetest.get_name_from_content_id(A[i])
        if y + mapping.offset.y == ground then
            if A[i] == nil
            or A[i] == minetest.CONTENT_AIR
            or node_name == "nv_planetgen:ice"
            or not minetest.registered_nodes[node_name].walkable then
                return
            end
        else
            if A[i] == nil
            or A[i] == minetest.CONTENT_AIR
            or node_name == "nv_planetgen:snow" then
                A[i] = custom.node
                A2[i] = yrot + color_index * 32
            end
        end
    end
end

function nv_flora.get_small_plant_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    if meta.life == "lush" then
        r.density = 1/(G:next(2, 8)^2)
    else
        r.density = 1/(G:next(8, 14)^2)
    end
    r.seed = 5646457
    r.side = 1
    r.order = 100
    r.callback = small_callback
    -- Small plant-specific
    r.color = colors[G:next(1, #colors)]
    r.is_mushroom = gen_weighted(G, {[true] = 1, [false] = 2})
    local plant_type_nodes
    if r.is_mushroom then
        if r.color > 32 then
            r.color = math.floor(r.color / 2)
        end
        plant_type_nodes = gen_weighted(G, {
            [nv_flora.node_types.thin_mushroom] = 1,
            [nv_flora.node_types.small_mushroom] = 1,
            [nv_flora.node_types.large_mushroom] = 1
        })
    else
        plant_type_nodes = gen_weighted(G, {
            [nv_flora.node_types.aloe_plant] = 1,
            [nv_flora.node_types.fern_plant] = 1
        })
    end
    local color_group = math.floor((r.color - 1) / 8) + 1
    r.node = plant_type_nodes[color_group]
    if meta.has_oceans then
        r.min_height = G:next(1, 4)^2
        r.max_height = r.min_height + G:next(1, 5)^2
    else
        r.min_height = G:next(1, 6)^2 - 18
        r.max_height = r.min_height + G:next(1, 6)^2
    end
    r.max_plant_height = 2
    r.max_plant_depth = 2
    return r
end
