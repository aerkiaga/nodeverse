local function lilypad_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local x = origin.x
    local z = origin.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local k = (z - base.z) * extent.x + x - base.x + 1
    local ground = math.floor(ground_buffer[k])
    if ground < custom.min_height or ground > custom.max_height then
        return
    end
    if minp.y + mapping.offset.y > 1 or maxp.y + mapping.offset.y < -1 then
        return
    end
    local color_index = (custom.color - 1) % 8
    for y=math.max(-1 - mapping.offset.y, minp.y),math.min(0 - mapping.offset.y, maxp.y),1 do
        local i = area:index(x, y, z)
        local node_name = minetest.get_name_from_content_id(A[i])
        if y + mapping.offset.y == -1 then
            if A[i] ~= planet.node_types.liquid
            then
                return
            end
        else
            if A[i] == nil
            or A[i] == minetest.CONTENT_AIR
            or node_name == "nv_planetgen:snow" then
                A[i] = custom.node
                A2[i] = 1 + color_index * 8
                nv_planetgen.set_meta(
                    {x=x, y=y, z=z},
                    {fields={seed=tostring(planet.seed), index=tostring(custom.index)}}
                )
            end
        end
    end
end

local function lilypad_thumbnail(seed, custom)
    local color_group = math.floor((custom.color - 1) / 8) + 1
    local translation = {
        [nv_flora.node_types.classic_lilypad] = "nv_classic_lilypad.png",
    }
    local color_string = nv_universe.sRGB_to_string(fnColorWater(custom.color + 8))
    return string.format(
        "%s^[multiply:%s",
        translation[custom.node],
        color_string
    )
end

function nv_flora.get_lilypad_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    r.density = 1/(G:next(3, 6)^2)
    r.index = index
    r.seed = 765473 + index
    r.side = 1
    r.order = 100
    r.callback = lilypad_callback
    -- Lilypad-specific
    local planet_weirdness = gen_linear(PcgRandom(seed, seed), 0.6, 1.6) ^ 3
    r.color = colors[G:next(1, #colors)] % 8
    r.node = gen_weighted(G, {
        [nv_flora.node_types.classic_lilypad] = 1,
    })
    r.min_height = -G:next(1, 3)
    r.max_height = 0
    r.max_plant_height = 2
    r.max_plant_depth = 2
    r.thumbnail = lilypad_thumbnail
    return r
end
