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
    local log2_caveness = gen_linear(G, -4, -0.5)
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
    -- CAVE WETNESS
    -- The tendency to waterlog underground caves
    planet.cave_wetness = 0.35
    if planet.atmosphere == "vacuum" then
        planet.has_oceans = false
        planet.cave_wetness = 0
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

local function fnExtractBits(n, lower, num)
    return math.floor(n / (2^lower)) % (2^num)
end

local function fnBitsDistribution(n, lower, num, max)
    return math.floor(max * fnExtractBits(n, lower, num) / ((2^num) - 1))
end

local function fnLighten(n, m)
    return 255 - math.floor((255 - n) / m)
end

-- Matches 'fnColorStone' in 'textures/palettes/generate.scm'
local function fnColorStone(n)
    n = n - 1
    local r = fnBitsDistribution(n, 0, 2, 192)
    local g = fnBitsDistribution(n, 2, 1, r)
    local b = fnBitsDistribution(n, 3, 1, g)
    return {r=fnLighten(r, 4), g=fnLighten(g, 4), b=fnLighten(b, 4)}
end

-- Matches 'fnColorWaterRandom' in 'textures/palettes/generate.scm'
local function fnColorWaterRandom(n)
    local r = fnBitsDistribution(n, 0, 2, 192)
    local g = fnBitsDistribution(n, 2, 2, 255)
    local b = fnBitsDistribution(n, 4, 1, 255)
    return {r=fnLighten(r, 2), g=fnLighten(g, 2), b=fnLighten(b, 2)}
end

-- Matches 'fnColorWaterNormal' in 'textures/palettes/generate.scm'
local function fnColorWaterNormal(n)
    local r = fnBitsDistribution(n, 0, 1, 64)
    local g = fnBitsDistribution(n, 1, 2, 192)
    local b = 255
    return {r=fnLighten(r, 2), g=fnLighten(g, 2), b=fnLighten(b, 2)}
end

-- 32 colors
-- Matches 'fnColorWater' in 'textures/palettes/generate.scm'
function fnColorWater(n)
    n = n - 1 -- make 0-based
    if n < 24 then
        return fnColorWaterRandom(n)
    else
        return fnColorWaterNormal(n)
    end
end

-- Matches 'fnColorGrassRandom' in 'textures/palettes/generate.scm'
local function fnColorGrassRandom(n)
    local r = fnBitsDistribution(n, 0, 2, 255)
    local g = fnBitsDistribution(n, 2, 2, 255)
    local b = fnBitsDistribution(n, 4, 1, 255)
    return {r=fnLighten(r, 1.7), g=fnLighten(g, 1.7), b=fnLighten(b, 1.7)}
end

-- Matches 'fnColorGrassNormal' in 'textures/palettes/generate.scm'
local function fnColorGrassNormal(n)
    local g = 128 + fnBitsDistribution(n, 0, 1, 127)
    local r = fnBitsDistribution(n, 1, 2, g - 64)
    local b = fnBitsDistribution(n, 3, 1, g - 128)
    return {r=fnLighten(r, 1.7), g=fnLighten(g, 1.7), b=fnLighten(b, 1.7)}
end

-- 48 colors
-- Matches 'fnColorGrass' in 'textures/palettes/generate.scm'
function fnColorGrass(n)
    n = n - 1 -- make 0-based
    if n < 32 then
        return fnColorGrassRandom(n)
    else
        return fnColorGrassNormal(n)
    end
end

function nv_planetgen.choose_planet_nodes_and_colors(planet)
    local G = PcgRandom(planet.seed, planet.seed)
    local stone_color = G:next(1, 16)
    planet.raw_colors.stone = fnColorStone(stone_color)
    planet.node_types.dust = minetest.get_content_id("nv_planetgen:dust" .. math.floor((stone_color - 1) / 8 + 1))
    planet.color_dictionary[planet.node_types.dust] = (stone_color - 1) % 8
    planet.node_types.sediment = minetest.get_content_id("nv_planetgen:sediment" .. math.floor((stone_color - 1) / 8 + 1))
    planet.color_dictionary[planet.node_types.sediment] = (stone_color - 1) % 8
    planet.node_types.gravel = minetest.get_content_id("nv_planetgen:gravel" .. math.floor((stone_color - 1) / 8 + 1))
    planet.color_dictionary[planet.node_types.gravel] = (stone_color - 1) % 8
    planet.node_types.stone = minetest.get_content_id("nv_planetgen:stone")
    planet.color_dictionary[planet.node_types.stone] = stone_color - 1
    if planet.atmosphere == "freezing" then
        planet.node_types.liquid = minetest.get_content_id("nv_planetgen:hydrocarbon")
        planet.raw_colors.liquid = {r = 113, g = 113, b = 113}
    elseif planet.atmosphere == "scorching" then
        planet.node_types.liquid = minetest.get_content_id("nv_planetgen:lava")
        planet.raw_colors.liquid = {r = 255, g = 169, b = 0}
    elseif gen_true_with_probability(G, planet.terrestriality + 0.18) then
        local water_color = G:next(1, 24)
        planet.node_types.liquid = minetest.get_content_id("nv_planetgen:water" .. water_color)
        planet.raw_colors.liquid = fnColorWater(water_color)
    else
        local water_color = G:next(25, 32)
        planet.node_types.liquid = minetest.get_content_id("nv_planetgen:water" .. water_color)
        planet.raw_colors.liquid = fnColorWater(water_color)
    end
    planet.node_types.snow = minetest.get_content_id("nv_planetgen:snow")
    planet.node_types.ice = minetest.get_content_id("nv_planetgen:ice")
    local grass_color
    if gen_true_with_probability(G, 1/2) then
        grass_color = G:next(1, 32)
    else
        grass_color = G:next(33, 48)
    end
    planet.node_types.grass_soil = minetest.get_content_id("nv_planetgen:grass_soil" .. stone_color)
    planet.color_dictionary[planet.node_types.grass_soil] = grass_color - 1
    planet.raw_colors.grass = fnColorGrass(grass_color)
    planet.node_types.grass = minetest.get_content_id("nv_planetgen:grass" .. math.floor((grass_color - 1) / 8 + 1))
    planet.color_dictionary[planet.node_types.grass] = (grass_color - 1) % 8
    planet.node_types.dry_grass = minetest.get_content_id("nv_planetgen:dry_grass" .. math.floor((grass_color - 1) / 8 + 1))
    planet.color_dictionary[planet.node_types.dry_grass] = (grass_color - 1) % 8
    planet.node_types.tall_grass = minetest.get_content_id("nv_planetgen:tall_grass" .. math.floor((grass_color - 1) / 8 + 1))
    planet.color_dictionary[planet.node_types.tall_grass] = (grass_color - 1) % 8
end
