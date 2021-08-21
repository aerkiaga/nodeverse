--[[
This file must register all custom node types used by a planet, before any of
those nodes is actually placed in the map, and then unregister them when no
longer needed.

 # INDEX
    REGISTRATION
]]

function register_base_nodes(G, planet, prefix)
    local stone_color = planet.stone_color
    -- DUST
    -- Covers a planet's surface
    -- Made of the same material as STONE
    minetest.register_node(prefix .. 'dust', {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "dust.png^[colorize:" .. stone_color .. ":64",
            "dust2.png^[colorize:" .. stone_color .. ":64",
            "dust.png^[colorize:" .. stone_color .. ":64", "dust2.png^[colorize:" .. stone_color .. ":64", "dust2.png^[colorize:" .. stone_color .. ":64", "dust.png^[colorize:" .. stone_color .. ":64"
        },
        paramtype2 = "colorfacedir",
        place_param2 = 8,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'dust')] = 24
    -- SEDIMENT
    -- Covers a planet's ocean floor and beaches
    -- Made of the same material as STONE
    -- Deposited by LIQUID over time
    minetest.register_node(prefix .. 'sediment', {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "sediment.png^[colorize:" .. stone_color .. ":48",
            "sediment2.png^[colorize:" .. stone_color .. ":48",
            "sediment.png^[colorize:" .. stone_color .. ":48", "sediment2.png^[colorize:" .. stone_color .. ":48", "sediment2.png^[colorize:" .. stone_color .. ":48", "sediment.png^[colorize:" .. stone_color .. ":48"
        },
        paramtype2 = "colorfacedir",
        place_param2 = 8,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'sediment')] = 24
    -- GRAVEL
    -- Lies under a layer of DUST
    -- Less granular than DUST
    minetest.register_node(prefix .. 'gravel', {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "gravel.png^[colorize:" .. stone_color .. ":48",
            "gravel.png^[colorize:" .. stone_color .. ":48",
            "(gravel.png^[transformR180)^[colorize:" .. stone_color .. ":48", "(gravel.png^[transformR90)^[colorize:" .. stone_color .. ":48","(gravel.png^[transformR270)^[colorize:" .. stone_color .. ":48", "gravel.png^[colorize:" .. stone_color .. ":48",
        },
        paramtype2 = "colorfacedir",
        place_param2 = 8,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'gravel')] = 4
    -- STONE
    -- Main material to make up a planet
    -- Is entirely solid and anisotropic
    minetest.register_node(prefix .. 'stone', {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "stone.png^[colorize:" .. stone_color .. ":32",
            "stone.png^[colorize:" .. stone_color .. ":32",
            "(stone.png^[transformR180)^[colorize:" .. stone_color .. ":32", "stone.png^[colorize:" .. stone_color .. ":32","(stone.png^[transformR180)^[colorize:" .. stone_color .. ":32", "stone.png^[colorize:" .. stone_color .. ":32",
        },
        paramtype2 = "colorfacedir",
        place_param2 = 8,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'stone')] = 2

    planet.node_types.dust = minetest.get_content_id(prefix .. 'dust')
    planet.node_types.sediment = minetest.get_content_id(prefix .. 'sediment')
    planet.node_types.gravel = minetest.get_content_id(prefix .. 'gravel')
    planet.node_types.stone = minetest.get_content_id(prefix .. 'stone')
end

function register_liquid_nodes(G, planet, prefix)
    local liquid_color = planet.liquid_color
    local liquid_type = "water"
    local liquid_style = "^[colorize:" .. liquid_color .. ":128)^[opacity:160"
    local liquid_animation_length = 2.0
    if planet.atmosphere == "freezing" then
        liquid_type = "hydrocarbon"
        liquid_style = ")^[opacity:160"
        liquid_animation_length = 4.0
    elseif planet.atmosphere == "scorching" then
        liquid_type = "lava"
        liquid_style = ")"
        liquid_animation_length = 8.0
    end

    -- LIQUID
    -- The liquid that fills a planet's oceans
    -- Might be water, or something else:
    -- water        Most common; essential for life
    -- hydrocarbon  Extremely cold, liquid short-chain hydrocarbon mix
    -- lava         Molten mix of rocks at high temperature
    minetest.register_node(prefix .. 'liquid', {
        drawtype = "liquid",
        visual_scale = 1.0,
        tiles = {
            {
                name = "(" .. liquid_type .. "_animation.png" .. liquid_style,
                backface_culling = false,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = liquid_animation_length
                }
            },
            {
                name = "(" .. liquid_type .. "_animation.png" .. liquid_style,
                backface_culling = true,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = liquid_animation_length
                }
            }
        },
        use_texture_alpha = "blend",
        paramtype = "light",
        paramtype2 = "colorfacedir",
        place_param2 = 8,
        is_ground_content = false,
        walkable = false,
        liquidtype = "source",
        liquid_alternative_flowing = prefix .. 'flowing_liquid',
	    liquid_alternative_source = prefix .. 'liquid',
        waving = 3,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'liquid')] = 4

    minetest.register_node(prefix .. 'flowing_liquid', {
        drawtype = "flowingliquid",
        visual_scale = 1.0,
        tiles = {liquid_type .. ".png"},
        special_tiles = {
            {
                name = "(" .. liquid_type .. "_animation.png" .. liquid_style,
                backface_culling = false,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = liquid_animation_length
                }
            },
            {
                name = "(" .. liquid_type .. "_animation.png" .. liquid_style,
                backface_culling = true,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = liquid_animation_length
                }
            }
        },
        use_texture_alpha = "blend",
        paramtype = "light",
        paramtype2 = "flowingliquid",
        place_param2 = 8,
        is_ground_content = false,
        walkable = false,
        liquidtype = "flowing",
        liquid_alternative_flowing = prefix .. 'flowing_liquid',
	    liquid_alternative_source = prefix .. 'liquid',
        waving = 3,
    })

    planet.node_types.liquid = minetest.get_content_id(prefix .. 'liquid')
    planet.node_types.flowing_liquid = minetest.get_content_id(prefix .. 'flowing_liquid')
end

function register_base_icy_nodes(G, planet, prefix)
    -- SNOW
    -- Covers planets with very low temperatures
    minetest.register_node(prefix .. 'snow', {
        drawtype = "nodebox",
        visual_scale = 1.0,
        tiles = {
            "snow_top.png",
            "snow_top.png",
            "snow_side.png^[transformFX",
            "snow_side.png^[transformFX",
            "snow_side.png",
            "snow_side.png"
        },
        paramtype2 = "colorfacedir",
        place_param2 = 8,
        walkable = false,
        leveled = 16,
        node_box = {
            type = "leveled",
            fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
        },
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'snow')] = 4

    planet.node_types.snow = minetest.get_content_id(prefix .. 'snow')
end

function register_base_floral_nodes(G, planet, prefix)
    local stone_color = planet.stone_color
    local grass_color = planet.grass_color

    -- GRASS SOIL
    -- A surface node for planets supporting life
    minetest.register_node(prefix .. 'grass_soil', {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            {name = "grass_soil_top.png", color = grass_color},
            "dust.png^[colorize:" .. stone_color .. ":64",
            "dust2.png^[colorize:" .. stone_color .. ":64",
            "dust.png^[colorize:" .. stone_color .. ":64",
            "dust2.png^[colorize:" .. stone_color .. ":64",
            "dust2.png^[colorize:" .. stone_color .. ":64"
        },
        overlay_tiles = {
            "",
            "",
            {name = "grass_soil_side.png", color = grass_color},
            {name = "grass_soil_side.png^[transformFX", color = grass_color},
            {name = "grass_soil_side.png^[transformFX", color = grass_color},
            {name = "grass_soil_side.png", color = grass_color}
        },
        paramtype2 = "colorfacedir",
        place_param2 = 8,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'grass_soil')] = 4

    -- GRASS
    -- A short grassy plant
    minetest.register_node(prefix .. 'grass', {
        drawtype = "plantlike",
        visual_scale = 1.0,
        tiles = {
            {name = "grass.png", color = grass_color},
        },
        paramtype2 = "degrotate",
        place_param2 = 0,
        sunlight_propagates = true,
        walkable = false,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'grass')] = 20

    -- DRY GRASS
    -- A dry grassy plant
    if planet.atmosphere == "hot" then
        minetest.register_node(prefix .. 'dry_grass', {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                {name = "grass_dry.png", color = grass_color},
            },
            paramtype2 = "degrotate",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = false,
        })
        random_yrot_nodes[minetest.get_content_id(prefix .. 'dry_grass')] = 20
    end

    -- TALL GRASS
    -- A tall grassy plant
    if planet.atmosphere == "normal" or planet.atmosphere == "reducing" then
        minetest.register_node(prefix .. 'tall_grass', {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                {name = "grass_tall.png", color = grass_color},
            },
            paramtype2 = "degrotate",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = false,
        })
        random_yrot_nodes[minetest.get_content_id(prefix .. 'tall_grass')] = 20
    end

    planet.node_types.grass_soil = minetest.get_content_id(prefix .. 'grass_soil')
    planet.node_types.grass = minetest.get_content_id(prefix .. 'grass')
    if planet.atmosphere == "hot" then
        planet.node_types.dry_grass = minetest.get_content_id(prefix .. 'dry_grass')
    elseif planet.atmosphere == "normal" or planet.atmosphere == "reducing" then
        planet.node_types.tall_grass = minetest.get_content_id(prefix .. 'tall_grass')
    end
end

--[[
 # REGISTRATION
]]

function register_planet_nodes(planet)
    local prefix = string.format('planetgen:p%X_', planet.seed)
    local G = PcgRandom(planet.seed, planet.seed)
    register_base_nodes(G, planet, prefix)
    register_liquid_nodes(G, planet, prefix)
    if planet.atmosphere == "cold" or planet.atmosphere == "freezing" then
        register_base_icy_nodes(G, planet, prefix)
    end
    if planet.life ~= "dead" then
        register_base_floral_nodes(G, planet, prefix)
    end
end

function unregister_planet_nodes(planet)
    prefix = 'planetgen:p' .. planet.seed .. '_'
    -- Unregister base nodes and their random rotation info
    random_yrot_nodes[minetest.get_content_id(prefix .. 'dust')] = nil
    random_yrot_nodes[minetest.get_content_id(prefix .. 'sediment')] = nil
    random_yrot_nodes[minetest.get_content_id(prefix .. 'gravel')] = nil
    random_yrot_nodes[minetest.get_content_id(prefix .. 'stone')] = nil
    minetest.registered_nodes[prefix .. 'dust'] = nil
    minetest.registered_nodes[prefix .. 'sediment'] = nil
    minetest.registered_nodes[prefix .. 'gravel'] = nil
    minetest.registered_nodes[prefix .. 'stone'] = nil
    -- Unregister liquid nodes and their random rotation info
    random_yrot_nodes[minetest.get_content_id(prefix .. 'liquid')] = nil
    minetest.registered_nodes[prefix .. 'liquid'] = nil
    minetest.registered_nodes[prefix .. 'flowing_liquid'] = nil

    if planet.atmosphere == "cold" or planet.atmosphere == "freezing" then
        random_yrot_nodes[minetest.get_content_id(prefix .. 'snow')] = nil
        minetest.registered_nodes[prefix .. 'snow'] = nil
    end

    if planet.life ~= "dead" then
        -- Unregister base floral nodes and their random rotation info
        random_yrot_nodes[minetest.get_content_id(prefix .. 'grass_soil')] = nil
        random_yrot_nodes[minetest.get_content_id(prefix .. 'grass')] = nil
        minetest.registered_nodes[prefix .. 'grass_soil'] = nil
        minetest.registered_nodes[prefix .. 'grass'] = nil
        if planet.atmosphere == "hot" then
            random_yrot_nodes[minetest.get_content_id(prefix .. 'dry_grass')] = nil
            minetest.registered_nodes[prefix .. 'dry_grass'] = nil
        elseif planet.atmosphere == "normal" or planet.atmosphere == "reducing" then
            random_yrot_nodes[minetest.get_content_id(prefix .. 'tall_grass')] = nil
            minetest.registered_nodes[prefix .. 'tall_grass'] = nil
        end
    end
end

function choose_planet_nodes_and_colors(planet)
    planet.node_types.stone = minetest.get_content_id('planetgen:stone' .. planet.seed % 4 + 1)
    --planet.color_dictionary[planet.node_types.stone] = planet.seed % 16
    planet.node_types.liquid = minetest.get_content_id('planetgen:water_source')
end

function register_color_variants_continuous(name, num_variants, random_yrot, color_fn, def_fn)
    local name = "planetgen:" .. name
    for n=1, num_variants do
        local variant_name = name .. n
        local color = nil
        if color_fn ~= nil then
            color = color_fn(n/num_variants)
            color = string.format("#%.2X%.2X%.2X", color.r, color.g, color.b)
        end
        definition = def_fn(n, color)
        minetest.register_node(variant_name, definition)
        random_yrot_nodes[minetest.get_content_id(variant_name)] = random_yrot
    end
end

function register_all_nodes()
    -- STONE
    -- Main material to make up a planet
    -- Is entirely solid and anisotropic
    register_color_variants_continuous(
        "stone", 4, 2,
        function (x) return {r=0, g=255*x, b=255} end,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "stone.png^[colorize:" .. color .. ":32",
                "stone.png^[colorize:" .. color .. ":32",
                "(stone.png^[transformR180)^[colorize:" .. color .. ":32",
                "stone.png^[colorize:" .. color .. ":32",
                "(stone.png^[transformR180)^[colorize:" .. color .. ":32",
                "stone.png^[colorize:" .. color .. ":32"
            },
            paramtype2 = "colorfacedir",
            place_param2 = 8
        } end
    )
end
