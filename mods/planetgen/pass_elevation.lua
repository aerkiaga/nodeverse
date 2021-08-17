--[[
This pass creates all the actual terrain, as rough hills and flat areas,
oceans, islands, beaches... This terrain has a layered surface, and occasionally
rocky areas.

 # INDEX
    ENTRY POINT
]]

--[[
 # ENTRY POINT
]]--

function pass_elevation(minp, maxp, area, A, A2, planet)
    local Perlin_2d_ocean_elevation = PerlinNoise({offset=0, scale=0.5, spread={x=500, y=500}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_mountain_roughness = PerlinNoise({offset=0, scale=0.5, spread={x=300, y=300}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_mountain_elevation = PerlinNoise({offset=0, scale=0.5, spread={x=100, y=100}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    local Perlin_2d_terrain_roughness = PerlinNoise({offset=0, scale=0.5, spread={x=16, y=16}, seed=planet.seed, octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    for z=minp.z, maxp.z do
        for x=minp.x, maxp.x do
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

            for y=minp.y, maxp.y do
                local i = area:index(x, y, z)
                if y < math.floor(ground) - 3 - planet.rockiness*terrain_roughness then
                    A[i] = planet.node_types.stone -- Deep layer/rocks
                elseif y < math.floor(ground) then
                    A[i] = planet.node_types.gravel -- Intermediate layer
                elseif y == math.floor(ground) then
                    if planet.has_oceans and (ocean_elevation + mountain_elevation + mountain_roughness + y/20 < -0.4 or y < -1) then
                        A[i] = planet.node_types.sediment -- Beach/ocean floor
                    else
                        A[i] = planet.node_types.dust -- Normal land
                    end
                elseif planet.has_oceans and y < 0 then
                    A[i] = planet.node_types.liquid -- Ocean
                else
                    A[i] = minetest.CONTENT_AIR -- Atmosphere
                end
            end
        end
    end
end
