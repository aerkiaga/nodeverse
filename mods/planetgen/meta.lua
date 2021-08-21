function generate_planet_metadata(planet)
    local G = PcgRandom(planet.seed, planet.seed)
    -- Default input parameters
    if planet.walled == nil then planet.walled = false end
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
    local log2_caveness = gen_linear(G, -9, -1.8)
    if log2_caveness > 2.0 then
        log2_caveness = (log2_caveness + 2)*5 - 2
    end
    planet.caveness = 2^log2_caveness
    -- STONE COLOR
    -- Blended into stone, gravel and dust textures
    local color_r = math.abs(G:next()) % 0x100
    local color_g = math.abs(G:next()) % (color_r+1)
    local color_b = math.abs(G:next()) % (color_g+1)
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
    -- ATMOSPHERE
    -- vacuum       No liquids, no oxygen, extreme cold; can't sustain life
    -- freezing     Liquid hydrocarbon lakes, extreme cold; can't sustain life
    -- cold         Frozen water, cold
    -- normal       Mild climate; can be lush
    -- hot          Intense heat
    -- scorching    Molten metal lakes, extreme heat; can't sustain life
    -- reducing     Raw metals, no oxygen; silicon-based life, can be lush
    planet.atmosphere = gen_weighted(G, {
        vacuum = 1,
        freezing = 1,
        cold = 2,
        normal = 4,
        hot = 2,
        scorching = 1,
        reducing = 1
    })
    if planet.atmosphere == "vacuum" then
        planet.has_oceans = false
    end
    if planet.atmosphere == "freezing" or planet.atmosphere == "scorching" then
        -- We don't want large, useless hydrocarbon/lava oceans
        planet.terrestriality = math.max(0.3, math.abs(planet.terrestriality))
    end
    -- LIFE
    -- lush         Full of life, with thriving flora and fauna everywhere
    -- normal       More scattered flora and fauna
    -- dead         No living organisms
    local lush_weight = 0
    local normal_weight = 2
    local dead_weight = 1
    if planet.atmosphere == "vacuum"
    or planet.atmosphere == "freezing"
    or planet.atmosphere == "scorching" then
        normal_weight = 0
    elseif planet.atmosphere == "normal" then
        lush_weight = 2
        dead_weight = 0
    elseif planet.atmosphere == "reducing" then
        lush_weight = 1
        dead_weight = 4
    end
    planet.life = gen_weighted(G, {
        lush = lush_weight,
        normal = normal_weight,
        dead = dead_weight
    })
    -- GRASS COLOR
    -- Blended into grass_soil
    color_g = math.abs(G:next()) % 0x100
    if gen_true_with_probability(G, 1/2) then
        color_g = 0x80 + color_g % 0x80
        color_r = math.abs(G:next()) % (color_g+1)
        color_b = math.abs(G:next()) % (color_g+1)
        planet.grass_color = string.format("#%.2X%.2X%.2X", color_r, color_g, color_b)
    else
        color_r = math.abs(G:next()) % 0x100
        color_b = math.abs(G:next()) % 0x100
        planet.grass_color = string.format("#%.2X%.2X%.2X", color_r, color_g, color_b)
    end
end
