local function ocean_grass_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local x = origin.x
    local z = origin.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local k = (z - base.z) * extent.x + x - base.x + 1
    local ground = math.floor(ground_buffer[k])
    if minp.y + mapping.offset.y > ground + (custom.max_plant_height or 256) or maxp.y + mapping.offset.y < ground - (custom.max_plant_depth or 256) then
        return
    end
    local grass_height = 2 + math.floor((x % 4) / 2 - 0.5)
    local yrot = (x * 23 + z * 749) % 4
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
            if not(A[i] == planet.node_types.liquid) then
                return
            end
        end
    end
    for y=math.max(ground + 1 - mapping.offset.y, minp.y),math.min(ground + grass_height - mapping.offset.y, maxp.y),1 do
        local i = area:index(x, y, z)
        if A[i] == planet.node_types.liquid then
            A[i] = custom.node
            A2[i] = yrot + color_index * 4
            nv_planetgen.set_meta(
                {x=x, y=y, z=z},
                {fields={seed=tostring(planet.seed), index=tostring(custom.index)}}
            )
        end
    end
end

local function ocean_grass_thumbnail(seed, custom)
    local color_group = math.floor((custom.color - 1) / 8) + 1
    local translation = {
        [nv_flora.node_types.thick_tube] = "nv_thick_tube.png",
        [nv_flora.node_types.thin_tubes] = "nv_thin_tubes.png",
    }
    local height = 3
    local r = ""
    for n=1,height,1 do
        local color = custom.color
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

function nv_flora.get_ocean_grass_meta(seed, index)
    local r = {}
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local colors = get_planet_plant_colors(seed)
    -- General
    if meta.life == "lush" then
        r.density = 1/(G:next(25, 40)^2)
    else
        r.density = 1/(G:next(40, 60)^2)
    end
    r.index = index
    r.seed = 638262 + index
    r.side = 1
    r.order = 100
    r.callback = ocean_grass_callback
    -- Ocean grass-specific
    r.color = colors[G:next(1, #colors)]
    local plant_type_nodes = gen_weighted(G, {
        thick_tube = 1,
        thin_tubes = 1,
    })
    local translation = {
        thick_tube = nv_flora.node_types.thick_tube,
        thin_tubes = nv_flora.node_types.thin_tubes,
    }
    r.node = translation[plant_type_nodes]
    r.max_plant_height = 4
    r.max_plant_depth = 2
    r.thumbnail = ocean_grass_thumbnail
    return r
end
