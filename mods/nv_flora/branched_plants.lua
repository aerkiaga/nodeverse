local function branched_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local G = PcgRandom(custom.seed, origin.x + 6489 * origin.z)
    local x = origin.x + math.floor(custom.side / 2) + mapping.offset.x
    local z = origin.z + math.floor(custom.side / 2) + mapping.offset.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local ground = math.floor(nv_planetgen.get_ground_level(planet, x, z))
    if ground < custom.min_height or ground > custom.max_height then
        return
    end
    if minp.y + mapping.offset.y > ground + (custom.max_plant_height or 256) or maxp.y + mapping.offset.y < ground then
        return
    end
    local node_list = {}
    local current_nodes = {}
    local deltas = {
        {x=1, z=0},
        {x=0, z=1},
        {x=0, z=-1},
        {x=-1, z=0}
    }
    table.insert(current_nodes, {x=x - mapping.offset.x, z=z - mapping.offset.z})
    for y=ground + 1 - mapping.offset.y,ground + custom.max_plant_height - mapping.offset.y,1 do
        local next_nodes = {}
        for n, node in ipairs(current_nodes) do
            table.insert(node_list, {x=node.x, y=y, z=node.z})
            if node.branch == nil then
                local number = G:next(0, custom.linearity)
                if number < 1 then
                elseif number < custom.linearity - custom.branchiness then
                    table.insert(next_nodes, {x=node.x, z=node.z})
                else
                    table.insert(next_nodes, {x=node.x, z=node.z, branch=true})
                    local delta1 = G:next(1, 4)
                    table.insert(next_nodes, {x=node.x + deltas[delta1].x, z=node.z + deltas[delta1].z})
                    local delta2 = G:next(1, 4)
                    table.insert(next_nodes, {x=node.x + deltas[delta2].x, z=node.z + deltas[delta2].z})
                end
            end
        end
        current_nodes = next_nodes
    end
    for n, node in ipairs(node_list) do
        if node.x >= minp.x and node.x <= maxp.x
        and node.y >= minp.y and node.y <= maxp.y
        and node.z >= minp.z and node.z <= maxp.z then
            local i = area:index(node.x, node.y, node.z)
            if not (A[i] == nil
            or A[i] == minetest.CONTENT_AIR) then
                return
            end
        else
            return
        end
    end
    for n, node in ipairs(node_list) do
        if node.x >= minp.x and node.x <= maxp.x
        and node.y >= minp.y and node.y <= maxp.y
        and node.z >= minp.z and node.z <= maxp.z then
            local i = area:index(node.x, node.y, node.z)
            A[i] = custom.node
            local yrot = (node.x + 103*node.y + 3049*node.z)%4
            A2[i] = yrot + custom.color * 4
        end
    end
end

function nv_flora.get_branched_plant_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    r.density = 1/(G:next(5, 15)^2)
    r.seed = 6583 + index
    r.order = 100
    r.callback = branched_callback
    -- Branched-plant-specific
    r.color = colors[G:next(1, #colors)]
    r.node = gen_weighted(G, {
        [nv_flora.node_types.succulent_stem] = 1
    })
    r.linearity = G:next(10, 30)
    r.branchiness = r.linearity / G:next(5, 10)
    if meta.has_oceans then
        r.min_height = G:next(1, 2)^2
        r.max_height = r.min_height + G:next(2, 4)^2
    else
        r.min_height = G:next(1, 4)^2 - 18
        r.max_height = r.min_height + G:next(2, 6)^2
    end
    r.max_plant_height = G:next(2, 6)
    r.side = r.max_plant_height * 2
    return r
end
