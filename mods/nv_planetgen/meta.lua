function generate_planet_metadata(seed)
    local planet = {}
    local G = PcgRandom(seed, seed)
    -- Default input parameters
    planet.seed = seed
    -- NODE TYPES
    -- Contains node IDs for all planet node types
    planet.node_types = {}
    -- COLOR DICTIONARY
    -- Maps node IDs to param2 color indices
    planet.color_dictionary = {}
    -- RAW COLORS
    -- Maps node names to raw colors
    planet.raw_colors = {}
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
    local log2_caveness = gen_linear(G, -6, -0.5)
    planet.caveness = 2^log2_caveness
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
    -- CLIFF HEIGHT
    -- The height of cliffs whenever they appear
    planet.cliff_height = (1 - 2^gen_linear(G, 0, 4))
    
    -- CLIFF STEEPNESS
    -- The steepness of cliffs whenever they appear
    planet.cliff_steepness = 1 - 2^gen_linear(G, 0, 3)
    
    -- CLIFF ALTITUDE OFFSET
    -- Cliffs will be more pronounced near this altitude and multiples
    planet.cliff_altitude_offset = 2^gen_linear(G, 0, 3)
    
    -- CLIFF ALTITUDE PERIOD
    -- Cliffs will repeat every multiple of this altitude
    planet.cliff_altitude_period = 2^(gen_linear(G, 0.25, 64)^0.5)
    return planet
end

nv_planetgen.generate_planet_metadata = generate_planet_metadata
