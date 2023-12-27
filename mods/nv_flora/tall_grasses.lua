local function grass_callback(
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
    if minp.y + mapping.offset.y > ground + (custom.max_plant_height or 256) or maxp.y + mapping.offset.y < ground - (custom.max_plant_depth or 256) then
        return
    end
    local grass_height = 3 + math.floor((x % 4) / 2 - 0.5)
    local yrot = (x * 23 + z * 749) % 24
    local color_index = (custom.color - 1) % 8
    for y=math.max(ground - mapping.offset.y, minp.y),math.min(ground + grass_height - mapping.offset.y, maxp.y),1 do
        local i = area:index(x, y, z)
        if y + mapping.offset.y == ground then
            if A[i] == nil
            or A[i] == minetest.CONTENT_AIR
            or not minetest.registered_nodes[minetest.get_name_from_content_id(A[i])].walkable then
                return
            end
        else
            if not(A[i] == nil
            or A[i] == minetest.CONTENT_AIR
            or minetest.get_name_from_content_id(A[i]) == "nv_planetgen:snow") then
                return
            end
        end
    end
    for y=math.max(ground + 1 - mapping.offset.y, minp.y),math.min(ground + grass_height - mapping.offset.y, maxp.y),1 do
        local i = area:index(x, y, z)
        if A[i] == nil
        or A[i] == minetest.CONTENT_AIR
        or minetest.get_name_from_content_id(A[i]) == "nv_planetgen:snow" then
            A[i] = custom.node
            if custom.is_colorful then
                A2[i] = yrot + (color_index + math.floor((y + mapping.offset.y - ground) / 2)) % 48 * 32
            else
                A2[i] = yrot + color_index * 32
            end
            nv_planetgen.set_meta(
                {x=x, y=y, z=z},
                {fields={seed=tostring(planet.seed), index=tostring(custom.index)}}
            )
        end
    end
end

local function grass_thumbnail(seed, custom)
    local color_group = math.floor((custom.color - 1) / 8) + 1
    local translation = {
        [nv_flora.node_types.cane_grass[color_group]] = "nv_cane_grass.png",
        [nv_flora.node_types.thick_grass[color_group]] = "nv_thick_grass.png",
        [nv_flora.node_types.ball_grass[color_group]] = "nv_ball_grass.png",
    }
    local height = 4
    local r = ""
    for n=1,height,1 do
        local color = custom.color
        if custom.is_colorful then
            color = (color + math.floor(n / 2) - 1) % 48 + 1
        end
        local color_string = nv_universe.sRGB_to_string(fnColorGrass(color))
        r = r .. string.format(
            "(([combine:%dx%d:%d,%d=%s)^[multiply:%s)^",
            height * 16,
            height * 16,
            math.floor((height/2 - 0.5) * 16),
            height * 16 - n * 16,
            translation[custom.node],
            color_string
        )
    end
    return string.sub(r, 1, #r - 1)
end

function nv_flora.get_tall_grass_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    if meta.life == "lush" then
        r.density = 1/(G:next(2, 8)^2)
    else
        r.density = 1/(G:next(10, 16)^2)
    end
    r.index = index
    r.seed = 638262 + index
    r.side = 1
    r.order = 100
    r.callback = grass_callback
    -- Grass-specific
    r.color = colors[G:next(1, #colors)]
    local color_group = math.floor((r.color - 1) / 8) + 1
    local plant_type_nodes = gen_weighted(G, {
        cane_grass = 1,
        thick_grass = 1,
        ball_grass = 1
    })
    local translation = {
        cane_grass = nv_flora.node_types.cane_grass,
        thick_grass = nv_flora.node_types.thick_grass,
        ball_grass = nv_flora.node_types.ball_grass,
    }
    plant_type_nodes = translation[plant_type_nodes]
    r.node = plant_type_nodes[color_group]
    r.is_colorful = (G:next(0, 2) == 0)
    if meta.has_oceans then
        r.min_height = G:next(1, 4)^2
        r.max_height = r.min_height + G:next(2, 3)^2
    else
        r.min_height = G:next(1, 6)^2 - 18
        r.max_height = r.min_height + G:next(2, 5)^2
    end
    r.max_plant_height = 5
    r.max_plant_depth = 2
    r.thumbnail = grass_thumbnail
    return r
end
