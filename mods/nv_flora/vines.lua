local function vine_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local G = PcgRandom(custom.seed, origin.x + 546466 * origin.z)
    local x = minp.x
    local z = minp.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local color_index = (custom.color - 1) % 8
    
    for z=minp.z,maxp.z,1 do
        for x=minp.x,maxp.x,1 do
            local point_count = 0
            local saved_p2 = nil
            local threshold = G:next(1, 2)
            for y=math.min(maxp.y, custom.max_height - mapping.offset.y),math.max(minp.y, custom.min_height - mapping.offset.y),-1 do
                local i = area:index(x, y, z)
                if (A[i] == nil or A[i] == minetest.CONTENT_AIR) then
                    local p2 = nil
                    if x > minp.x and minetest.registered_nodes[minetest.get_name_from_content_id(A[area:index(x - 1, y, z)])].nv_vineable ~= nil then
                        p2 = 3
                    elseif z > minp.z and minetest.registered_nodes[minetest.get_name_from_content_id(A[area:index(x, y, z - 1)])].nv_vineable ~= nil then
                        p2 = 5
                    elseif x < maxp.x and minetest.registered_nodes[minetest.get_name_from_content_id(A[area:index(x + 1, y, z)])].nv_vineable ~= nil then
                        p2 = 2
                    elseif z < maxp.z and minetest.registered_nodes[minetest.get_name_from_content_id(A[area:index(x, y, z + 1)])].nv_vineable ~= nil then
                        p2 = 4
                    end
                    if p2 ~= nil or point_count > G:next(2, 3) then
                        if p2 ~= nil then
                            point_count = point_count + 1
                            saved_p2 = p2
                        else
                            point_count = point_count - G:next(1, 2)
                        end
                        if point_count > threshold and (p2 == nil or gen_linear(G, 0, 1) < custom.vine_density) then
                            A[i] = custom.nodes[G:next(1, 2)]
                            A2[i] = saved_p2 + color_index * 8
                        end
                    end
                end
            end
        end
    end
end

function nv_flora.get_vine_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    r.density = 1/G:next(2, 6)
    r.seed = 7583893 + index
    r.side = 8
    r.order = 100
    r.callback = vine_callback
    -- Cave plant-specific
    r.color = colors[G:next(1, #colors)] % 8
    r.nodes = gen_weighted(G, {
        [nv_flora.node_types.vine] = 1
    })
    r.vine_density = gen_linear(G, 0.4, 0.8)
    r.max_height = G:next(3, 6)^2
    r.min_height = -G:next(1, 5)^2
    return r
end
