local function surface_deposit_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local x = origin.x
    local z = origin.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local G = PcgRandom(custom.seed, origin.x + origin.z * 27)
    local ground = math.floor(nv_planetgen.get_ground_level(planet, x, z))
    if minp.y > ground + custom.height - mapping.offset.y + 1 or maxp.y < ground - mapping.offset.y - 3 then
        return
    end
    local size = custom.side / 3
    for z=minp.z,maxp.z,1 do
        for x=minp.x,maxp.x,1 do
            local distance = math.hypot(x - origin.x - 5, z - origin.z - 5)
            local G2 = PcgRandom(x, z)
            for y=math.max(ground - 3 - mapping.offset.y, minp.y),math.min(ground + custom.height - mapping.offset.y, maxp.y) do
                local v = G2:next(0, 100) / 100
                local level_size = size * (1 - (y - ground + mapping.offset.y) / custom.height)
                if distance - v < level_size then
                    local i = area:index(x, y, z)
                    local node_name = minetest.get_name_from_content_id(A[i])
                    if node_name ~= "nv_planetgen:stone" then
                        A[i] = custom.node
                        A2[i] = G2:next(0, 255) % 4
                    end
                end
            end
        end
    end
end

function nv_ores.get_surface_deposit_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    -- General
    r.density = 1/(G:next(1, 4)^2)
    r.index = index
    r.seed = 76578567 + index
    r.side = G:next(2, 9)
    r.order = 100
    r.callback = surface_deposit_callback
    -- Surface deposit-specific
    r.height = G:next(1, 7)
    if meta.atmosphere == "scorching" then
        r.node = nv_ores.node_types.sulfur
    end
    return r
end
