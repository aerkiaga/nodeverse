--[[
This file must register all custom node types used by a planet, before any of
those nodes is actually placed in the map, and then unregister them when no
longer needed.

 # INDEX
    REGISTRATION
]]

function register_base_nodes(G, planet, prefix)
    stone_color = planet.stone_color
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
        paramtype2 = "facedir",
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
        paramtype2 = "facedir",
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
        paramtype2 = "facedir",
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
        paramtype2 = "facedir",
        place_param2 = 8,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'stone')] = 2

    planet.node_types.dust = minetest.get_content_id(prefix .. 'dust')
    planet.node_types.sediment = minetest.get_content_id(prefix .. 'sediment')
    planet.node_types.gravel = minetest.get_content_id(prefix .. 'gravel')
    planet.node_types.stone = minetest.get_content_id(prefix .. 'stone')
end

function register_liquid_nodes(G, planet, prefix)
    liquid_color = planet.liquid_color

    -- LIQUID
    -- The liquid that fills a planet's oceans
    -- Might be water, or something else
    minetest.register_node(prefix .. 'liquid', {
        drawtype = "liquid",
        visual_scale = 1.0,
        tiles = {
            {
                name = "(liquid_animation.png^[colorize:" .. liquid_color .. ":128)^[opacity:160",
                backface_culling = false,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 2.0
                }
            },
            {
                name = "(liquid_animation.png^[colorize:" .. liquid_color .. ":128)^[opacity:160",
                backface_culling = true,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 2.0
                }
            }
        },
        use_texture_alpha = "blend",
        paramtype = "light",
        paramtype2 = "facedir",
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
        tiles = {"liquid.png"},
        special_tiles = {
            {
                name = "(liquid_animation.png^[colorize:" .. liquid_color .. ":128)^[opacity:160",
                backface_culling = false,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 2.0
                }
            },
            {
                name = "(liquid_animation.png^[colorize:" .. liquid_color .. ":128)^[opacity:160",
                backface_culling = true,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 2.0
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

function register_base_floral_nodes(G, planet, prefix)
    grass_color = planet.grass_color

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
        paramtype2 = "facedir",
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
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'grass')] = 20

    -- DRY GRASS
    -- A dry grassy plant
    minetest.register_node(prefix .. 'dry_grass', {
        drawtype = "plantlike",
        visual_scale = 1.0,
        tiles = {
            {name = "grass_dry.png", color = grass_color},
        },
        paramtype2 = "degrotate",
        place_param2 = 0,
        sunlight_propagates = true,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'dry_grass')] = 20

    planet.node_types.grass_soil = minetest.get_content_id(prefix .. 'grass_soil')
    planet.node_types.grass = minetest.get_content_id(prefix .. 'grass')
    planet.node_types.dry_grass = minetest.get_content_id(prefix .. 'dry_grass')

    -- TALL GRASS
    -- A tall grassy plant
    minetest.register_node(prefix .. 'tall_grass', {
        drawtype = "plantlike",
        visual_scale = 1.0,
        tiles = {
            {name = "grass_tall.png", color = grass_color},
        },
        paramtype2 = "degrotate",
        place_param2 = 0,
        sunlight_propagates = true,
    })
    random_yrot_nodes[minetest.get_content_id(prefix .. 'tall_grass')] = 20

    planet.node_types.grass_soil = minetest.get_content_id(prefix .. 'grass_soil')
    planet.node_types.grass = minetest.get_content_id(prefix .. 'grass')
    planet.node_types.dry_grass = minetest.get_content_id(prefix .. 'dry_grass')
    planet.node_types.tall_grass = minetest.get_content_id(prefix .. 'tall_grass')
end

--[[
 # REGISTRATION
]]

function register_planet_nodes(planet)
    prefix = string.format('planetgen:p%X_', planet.seed)
    planet.node_types = {}
    G = PcgRandom(planet.seed, planet.seed)
    register_base_nodes(G, planet, prefix)
    register_liquid_nodes(G, planet, prefix)
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

    if planet.life ~= "dead" then
        -- Unregister base floral nodes and their random rotation info
        random_yrot_nodes[minetest.get_content_id(prefix .. 'grass_soil')] = nil
        random_yrot_nodes[minetest.get_content_id(prefix .. 'grass')] = nil
        random_yrot_nodes[minetest.get_content_id(prefix .. 'dry_grass')] = nil
        minetest.registered_nodes[prefix .. 'grass_soil'] = nil
        minetest.registered_nodes[prefix .. 'grass'] = nil
        minetest.registered_nodes[prefix .. 'dry_grass'] = nil
    end
    planet.node_types = nil
end
