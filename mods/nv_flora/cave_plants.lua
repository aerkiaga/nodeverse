local function cave_plant_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local x = minp.x
    local z = minp.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local k = (z - base.z) * extent.x + x - base.x + 1
    local ground = math.floor(ground_buffer[k])
    local yrot = (x * 23 + z * 749) % 24
    local color_index = (custom.color - 1) % 8
    local grounded = false
    for y=math.max(minp.y, custom.min_height - mapping.offset.y),math.min(math.min(maxp.y, ground - mapping.offset.y - 3), custom.max_height - mapping.offset.y),1 do
        local i = area:index(x, y, z)
        if grounded and (A[i] == nil
        or A[i] == minetest.CONTENT_AIR) then
            A[i] = custom.node
            A2[i] = yrot + color_index * 32
            grounded = false
        else
            grounded = not (A[i] == nil
            or A[i] == minetest.CONTENT_AIR
            or not minetest.registered_nodes[minetest.get_name_from_content_id(A[i])].walkable)
        end
    end
end

function nv_flora.get_cave_plant_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    if meta.life == "lush" then
        r.density = 1/(G:next(3, 5)^2)
    else
        r.density = 1/(G:next(5, 12)^2)
    end
    r.seed = 5646457 + index
    r.side = 1
    r.order = 100
    r.callback = cave_plant_callback
    -- Cave plant-specific
    r.color = colors[G:next(1, #colors)]
    local plant_type_nodes
    if r.color > 32 then
        r.color = math.floor(r.color / 2)
    end
    plant_type_nodes = gen_weighted(G, {
        [nv_flora.node_types.thin_mushroom] = 1,
        [nv_flora.node_types.trumpet_mushroom] = 1
    })
    local color_group = math.floor((r.color - 1) / 8) + 1
    r.node = plant_type_nodes[color_group]
    r.max_height = G:next(1, 5)^2 - 8
    r.min_height = -G:next(4, 8)^2
    return r
end
