--[[
This pass creates all the actual terrain, as rough hills and flat areas,
oceans, islands, beaches... This terrain has a layered surface, and occasionally
rocky areas.

 # INDEX
    ENTRY POINT
]]

function pass_elevation_compute_craters(x, z, planet)
    local chunk_x = math.floor(x/80)
    local chunk_z = math.floor(z/80)
    local hash = chunk_x + chunk_z*0x1000
    local hash = int_hash(hash)
    local G = PcgRandom(planet.seed, hash)
    local num_craters = math.floor(gen_linear_sum(G, 0, 2, 3))

    local r = 0
    for n=1, num_craters do
        local crater_r = gen_linear(G, 3, 15)
        local crater_x = gen_linear(G, crater_r, 80 - crater_r)
        local crater_z = gen_linear(G, crater_r, 80 - crater_r)
        local rel_x = (x % 80) - crater_x
        local rel_z = (z % 80) - crater_z
        local radius = (rel_x^2 + rel_z^2)^(1/2)
        if radius < crater_r then
            local new_r = -(math.max(0, crater_r^2 - radius^2)^(1/2))
            local flatness = 1 + crater_r / 15
            new_r = new_r / flatness
            r = math.min(r, new_r)
        end
    end
    return r
end

--[[
 # ENTRY POINT
]]--

function pass_elevation(minp, maxp, area, A, A2, planet)
    local Perlin_2d_ocean_elevation = PerlinNoise({offset=0, scale=0.5, spread={x=500, y=500}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_mountain_roughness = PerlinNoise({offset=0, scale=0.5, spread={x=300, y=300}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_mountain_elevation = PerlinNoise({offset=0, scale=0.5, spread={x=100, y=100}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_terrain_roughness = PerlinNoise({offset=0, scale=0.5, spread={x=16, y=16}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    for z_abs=minp.z, maxp.z do
        local z = z_abs + planet.offset.z
        for x_abs=minp.x, maxp.x do
            local x = x_abs + planet.offset.x
            local ground = 0

            -- Use land/ocean elevation as initial ground level
            local ocean_elevation = Perlin_2d_ocean_elevation:get_2d({x=x, y=z})
            ground = ground + ocean_elevation * 25

            -- Compute mountain roughness and elevation into ground level
            local mountain_roughness = Perlin_2d_mountain_roughness:get_2d({x=x, y=z})
            local mountain_elevation = Perlin_2d_mountain_elevation:get_2d({x=x, y=z})
            ground = ground + (mountain_elevation+planet.terrestriality) * (mountain_roughness/(math.abs(mountain_roughness)+0.5) + 1)^2 * 25

            -- Add terrain roughness for high-frequency details
            local terrain_roughness = Perlin_2d_terrain_roughness:get_2d({x=x, y=z})
            ground = ground + terrain_roughness * 2

            if planet.atmosphere == "vacuum" then
                ground = ground + pass_elevation_compute_craters(x, z, planet)
            end

            local hash = x + z*0x100
            hash = int_hash(hash)
            local G = PcgRandom(planet.seed, hash)

            for y_abs=minp.y, maxp.y do
                local y = y_abs + planet.offset.y
                local i = area:index(x_abs, y_abs, z_abs)
                if y < math.floor(ground) - 3 - planet.rockiness*terrain_roughness then
                    A[i] = planet.node_types.stone -- Deep layer/rocks
                elseif y < math.floor(ground) then
                    A[i] = planet.node_types.gravel -- Intermediate layer
                elseif y == math.floor(ground) then
                    if planet.has_oceans and (ocean_elevation + mountain_elevation + mountain_roughness + y/20 < -0.4 or y < -1) then
                        if planet.atmosphere ~= "scorching" then
                            A[i] = planet.node_types.sediment --Beach/ocean floor
                        else
                            A[i] = planet.node_types.gravel
                        end
                    else
                        -- Normal land
                        if planet.life == "dead" then
                            if not planet.has_oceans and ocean_elevation + terrain_roughness/10 < 0 then
                                A[i] = planet.node_types.sediment
                            else
                                A[i] = planet.node_types.dust
                            end
                        elseif planet.atmosphere == "hot" then
                            if planet.has_oceans and ocean_elevation - terrain_roughness/10 > 0.3 then
                                A[i] = planet.node_types.dust
                            elseif not planet.has_oceans and ocean_elevation + terrain_roughness/10 < 0 then
                                A[i] = planet.node_types.sediment -- Desert
                            else
                                A[i] = planet.node_types.grass_soil
                            end
                        else
                            A[i] = planet.node_types.grass_soil
                        end
                    end
                elseif planet.has_oceans and y < 0 then
                    A[i] = planet.node_types.liquid -- Ocean
                elseif y == math.floor(ground) + 1 then
                    local air_weight = 100
                    local grass_weight = 0
                    local dry_grass_weight = 0
                    local tall_grass_weight = 0
                    local snow_weight = 0
                    if planet.has_oceans and (ocean_elevation + mountain_elevation + mountain_roughness + (y-1)/20 < -0.4 or (y-1) < -1) then
                        --
                    elseif planet.life ~= "dead" then
                        if planet.atmosphere == "hot" then
                            if planet.has_oceans and ocean_elevation - terrain_roughness/10 > 0.3 then
                                grass_weight = 1
                                dry_grass_weight = 5
                            elseif not planet.has_oceans and ocean_elevation + terrain_roughness/10 < 0 then
                                grass_weight = 0
                                dry_grass_weight = 1
                            else
                                grass_weight = 8
                                dry_grass_weight = 4
                            end
                        elseif planet.atmosphere == "cold" then
                            if mountain_elevation >= 0 then
                                snow_weight = 50 + 50*(mountain_elevation^(1/5))
                            else
                                snow_weight = 50 - 50*((-mountain_elevation)^(1/5))
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
                    A[i] = gen_weighted(G, options)
                else
                    A[i] = minetest.CONTENT_AIR -- Atmosphere
                end
            end
        end
    end
end
