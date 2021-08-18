function generate_planet_metadata(planet)
    G = PcgRandom(planet.seed, planet.seed)
    -- HAS OCEANS
    -- Whether the planet has oceans full of liquid
    planet.has_oceans = gen_true_with_probability(G, 3/5)
    -- TERRESTRIALITY
    -- The elevation of mountainous terrain compared to flat terrain
    -- Low values create more ocean, with deep, rough floor and islands
    -- High values create less ocean, with higher and lower areas
    planet.terrestriality = gen_linear(G, -0.6, 1)
    planet.terrestriality = planet.terrestriality * math.abs(planet.terrestriality) / 2
    -- ROCKINESS
    -- The tendency to form exposed stone areas
    -- Values < 4 do not expose stone
    -- Values 4-5 can expose flat stone
    -- Values > 5 can form protruding rocks
    planet.rockiness = gen_linear(G, 0, 1.6)
    planet.rockiness = 5*math.abs(planet.rockiness-1) + 8*(planet.rockiness-1) + 3
    -- CAVENESS
    -- The tendency to form underground caves
    planet.caveness = 2^gen_linear(G, -9, -1.5)
    -- STONE COLOR
    -- Blended into stone, gravel and dust textures
    color_r = math.abs(G:next()) % 0x100
    color_g = math.abs(G:next()) % color_r
    color_b = math.abs(G:next()) % color_g
    planet.stone_color = string.format("#%.2X%.2X%.2X", color_r, color_g, color_b)
    -- LIQUID COLOR
    -- Blended into liquids
    if gen_true_with_probability(G, planet.terrestriality + 0.18) then
        planet.liquid_color = string.format("#%.6X", math.abs(G:next()) % 0x1000000)
    else
        color_r = math.abs(G:next()) % 0x40
        color_g = math.abs(G:next()) % 0x80
        planet.liquid_color = string.format("#%.2X%.2XFF", color_r, color_g)
    end
end
