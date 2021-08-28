--[[
This pass creates all the actual terrain, as rough hills and flat areas,
oceans, islands, beaches... This terrain has a layered surface, and occasionally
rocky areas.

 # INDEX
    ENTRY POINT
]]

local function elevation_compute_craters(x, z, planet)
    local floor = math.floor
    local max = math.max
    local min = math.min
    local chunk_x = floor(x/80)
    local chunk_z = floor(z/80)
    local hash = chunk_x + chunk_z*0x1000
    local hash = int_hash(hash)
    local G = PcgRandom(planet.seed, hash)
    local num_craters = floor(gen_linear_sum(G, 0, 2, 3))

    local r = 0
    for n=1, num_craters do
        local crater_r = gen_linear(G, 3, 15)
        local crater_x = gen_linear(G, crater_r, 80 - crater_r)
        local crater_z = gen_linear(G, crater_r, 80 - crater_r)
        local rel_x = (x % 80) - crater_x
        local rel_z = (z % 80) - crater_z
        local radius = (rel_x^2 + rel_z^2)^(1/2)
        if radius < crater_r then
            local new_r = -(max(0, crater_r^2 - radius^2)^(1/2))
            local flatness = 1 + crater_r / 15
            new_r = new_r / flatness
            r = min(r, new_r)
        end
    end
    return r
end

local function elevation_compute_soil_layer(G, y, ground, ground_comp, planet)
    if planet.has_oceans and (ground_comp.ocean_elevation + ground_comp.mountain_elevation
    + ground_comp.mountain_roughness + y/20 < -0.4 or y < -1) then
        if planet.atmosphere ~= "scorching" then
            return planet.node_types.sediment --Beach/ocean floor
        else
            return planet.node_types.gravel
        end
    else
        -- Normal soil
        if planet.life == "dead" then
            if not planet.has_oceans and ground_comp.ocean_elevation
            + ground_comp.terrain_roughness/10 < 0 then
                return planet.node_types.sediment
            else
                return planet.node_types.dust
            end
        elseif planet.atmosphere == "hot" then
            if planet.has_oceans and ground_comp.ocean_elevation
            - ground_comp.terrain_roughness/10 > 0.3 then
                return planet.node_types.dust
            elseif not planet.has_oceans and ground_comp.ocean_elevation
            + ground_comp.terrain_roughness/10 < 0 then
                return planet.node_types.sediment -- Desert
            else
                return planet.node_types.grass_soil
            end
        else
            return planet.node_types.grass_soil
        end
    end
end

local function elevation_compute_cover_layer(G, y, ground, ground_comp, planet)
    local air_weight = 100
    local grass_weight = 0
    local dry_grass_weight = 0
    local tall_grass_weight = 0
    local snow_weight = 0
    if planet.has_oceans and (ground_comp.ocean_elevation + ground_comp.mountain_elevation
    + ground_comp.mountain_roughness + (y-1)/20 < -0.4 or (y-1) < -1) then
        --
    elseif planet.life ~= "dead" then
        if planet.atmosphere == "hot" then
            if planet.has_oceans and ground_comp.ocean_elevation
            - ground_comp.terrain_roughness/10 > 0.3 then
                grass_weight = 1
                dry_grass_weight = 5
            elseif not planet.has_oceans and ground_comp.ocean_elevation
            + ground_comp.terrain_roughness/10 < 0 then
                grass_weight = 0
                dry_grass_weight = 1
            else
                grass_weight = 8
                dry_grass_weight = 4
            end
        elseif planet.atmosphere == "cold" then
            if ground_comp.mountain_elevation >= 0 then
                snow_weight = 50 + 50*(ground_comp.mountain_elevation^(1/5))
            else
                snow_weight = 50 - 50*((-ground_comp.mountain_elevation)^(1/5))
            end
            air_weight = 100 - snow_weight
            grass_weight = air_weight / 4
        elseif planet.life == "lush" then
            grass_weight = 25
            tall_grass_weight = 15
        else
            grass_weight = 15
            tall_grass_weight = 2
        end
    else
        if planet.atmosphere == "cold" then
            snow_weight = 100
            air_weight = 0
        elseif planet.atmosphere == "freezing" then
            snow_weight = 90
            air_weight = 10
        end
    end
    local options = {
        [minetest.CONTENT_AIR] = air_weight
    }
    if planet.node_types.grass ~= nil then
        options[planet.node_types.grass] = grass_weight
    end
    if planet.node_types.dry_grass ~= nil then
        options[planet.node_types.dry_grass] = dry_grass_weight
    end
    if planet.node_types.tall_grass ~= nil then
        options[planet.node_types.tall_grass] = tall_grass_weight
    end
    if planet.node_types.snow ~= nil then
        options[planet.node_types.snow] = snow_weight
    end
    return gen_weighted(G, options)
end

local function elevation_gen_node_column(
    x_abs, minp_abs_y, maxp_abs_y, z_abs, area, offset, G, ground, ground_comp, planet, A
)
    for y_abs=minp_abs_y, maxp_abs_y do
        local y = y_abs + offset.y
        local i = area:index(x_abs, y_abs, z_abs)
        if y < math.floor(ground) - 3 - planet.rockiness*ground_comp.terrain_roughness then
            A[i] = planet.node_types.stone -- Deep layer/rocks
        elseif y < math.floor(ground) then
            A[i] = planet.node_types.gravel -- Intermediate layer
        elseif y == math.floor(ground) then
            A[i] = elevation_compute_soil_layer(G, y, ground, ground_comp, planet)
        elseif planet.has_oceans and y < 0 then
            A[i] = planet.node_types.liquid -- Ocean
        elseif y == math.floor(ground) + 1 then
            A[i] = elevation_compute_cover_layer(G, y, ground, ground_comp, planet)
        else
            A[i] = minetest.CONTENT_AIR -- Atmosphere
        end
    end
end

--[[
 # ENTRY POINT
]]--

local elevation_ground_buffer = {}

function nv_planetgen.pass_elevation(minp_abs, maxp_abs, area, offset, A, A2, planet)
    local r = elevation_ground_buffer
    local Perlin_2d_ocean_elevation = PerlinWrapper({offset=0, scale=0.5, spread={x=500, y=500}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_mountain_roughness = PerlinWrapper({offset=0, scale=0.5, spread={x=300, y=300}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_mountain_elevation = PerlinWrapper({offset=0, scale=0.5, spread={x=100, y=100}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_terrain_roughness = PerlinWrapper({offset=0, scale=0.5, spread={x=16, y=16}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local is_wall_z = false
    local is_wall_x = false
    local abs = math.abs
    local fast_int_hash = fast_int_hash
    for z_abs=minp_abs.z, maxp_abs.z do
        local z = z_abs + offset.z
        for x_abs=minp_abs.x, maxp_abs.x do
            local x = x_abs + offset.x
            local ground_comp = {}
            local ground = 0
            local k = (z_abs - minp_abs.z)*(maxp_abs.x - minp_abs.x + 1) + x_abs - minp_abs.x + 1

            -- Use land/ocean elevation as initial ground level
            ground_comp.ocean_elevation = Perlin_2d_ocean_elevation:get_2d({x=x, y=z})
            ground = ground + ground_comp.ocean_elevation * 25

            -- Compute mountain roughness and elevation into ground level
            ground_comp.mountain_roughness = Perlin_2d_mountain_roughness:get_2d({x=x, y=z})
            ground_comp.mountain_elevation = Perlin_2d_mountain_elevation:get_2d({x=x, y=z})
            ground = ground + (ground_comp.mountain_elevation+planet.terrestriality)
            * (ground_comp.mountain_roughness/(abs(ground_comp.mountain_roughness)+0.5) + 1)^2 * 25

            -- Add terrain roughness for high-frequency details
            ground_comp.terrain_roughness = Perlin_2d_terrain_roughness:get_2d({x=x, y=z})
            ground = ground + ground_comp.terrain_roughness * 2

            if planet.atmosphere == "vacuum" then
                ground = ground + elevation_compute_craters(x, z, planet)
            end

            local hash = x + z*4713
            hash = fast_int_hash(hash)
            local G = PcgRandom(planet.seed, hash)

            elevation_gen_node_column(
                x_abs, minp_abs.y, maxp_abs.y, z_abs, area,
                offset, G, ground, ground_comp, planet, A
            )

            r[k] = ground
        end
    end
    return r
end
