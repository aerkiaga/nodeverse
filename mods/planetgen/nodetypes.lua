--[[
This file must register all custom node types used by a planet, before any of
those nodes is actually placed in the map, and then unregister them when no
longer needed.

 # INDEX
    REGISTRATION
    VARIANT SELECTION
]]

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

function register_color_variants(name, num_variants, random_yrot, color_fn, def_fn)
    --[[
    Will register a number of node types. These are meant to be variants of a
    common abstract node type.
    name            string      node base name, e.g. 'tall_grass'
    num_variants    number      number of distinct node types to register
    random_yrot     number      value to be registered at 'random_yrot_nodes'
    color_fn        function (x)
        (optional) Should return a table with 'r', 'g', and 'b' members in the
        range [0 .. 255], that will be passed as color string to 'def_fn'.
        n           number      index of variant, [1 .. 'num_variants']
    def_fn          function (n, color)
        Should return a node definition table to be passed as second argument to
        'minetest.register_node()'.
        n           number      index of variant, [1 .. 'num_variants']
        color       string      return value of 'color_fn', converted to string
    ]]--
    local name = "planetgen:" .. name
    for n=1, num_variants do
        local variant_name = name
        if num_variants > 1 then
            variant_name = variant_name .. n
        end
        local color = nil
        if color_fn ~= nil then
            color = color_fn(n)
            color = string.format("#%.2X%.2X%.2X", color.r, color.g, color.b)
        end
        definition = def_fn(n, color)
        minetest.register_node(variant_name, definition)
        random_yrot_nodes[minetest.get_content_id(variant_name)] = random_yrot
    end
end

function fnExtractBits(n, lower, num)
    return math.floor(n / (2^lower)) % (2^num)
end

function fnBitsDistribution(n, lower, num, max)
    return math.floor(max * fnExtractBits(n, lower, num) / ((2^num) - 1))
end

function fnColorStone(n)
    n = n - 1
    local r = fnBitsDistribution(n, 0, 2, 192)
    local g = fnBitsDistribution(n, 2, 1, r)
    local b = fnBitsDistribution(n, 3, 1, g)
    return {r=r, g=g, b=b}
end

function register_base_nodes()
    -- DUST
    -- Covers a planet's surface
    -- Made of the same material as STONE
    register_color_variants(
        "dust", 16, 24,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "dust.png^[colorize:" .. color .. ":64",
                "dust2.png^[colorize:" .. color .. ":64",
                "dust.png^[colorize:" .. color .. ":64",
                "dust2.png^[colorize:" .. color .. ":64",
                "dust2.png^[colorize:" .. color .. ":64",
                "dust.png^[colorize:" .. color .. ":64"
            },
            paramtype2 = "colorfacedir",
            place_param2 = 0,
        } end
    )
    -- SEDIMENT
    -- Covers a planet's ocean floor and beaches
    -- Made of the same material as STONE
    -- Deposited by LIQUID over time
    register_color_variants(
        "sediment", 16, 24,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "sediment.png^[colorize:" .. color .. ":48",
                "sediment2.png^[colorize:" .. color .. ":48",
                "sediment.png^[colorize:" .. color .. ":48",
                "sediment2.png^[colorize:" .. color .. ":48",
                "sediment2.png^[colorize:" .. color .. ":48",
                "sediment.png^[colorize:" .. color .. ":48"
            },
            paramtype2 = "colorfacedir",
            place_param2 = 0,
        } end
    )
    -- GRAVEL
    -- Lies under a layer of DUST
    -- Less granular than DUST
    register_color_variants(
        "gravel", 16, 4,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "gravel.png^[colorize:" .. color .. ":48",
                "gravel.png^[colorize:" .. color .. ":48",
                "(gravel.png^[transformR180)^[colorize:" .. color .. ":48",
                "(gravel.png^[transformR90)^[colorize:" .. color .. ":48",
                "(gravel.png^[transformR270)^[colorize:" .. color .. ":48",
                "gravel.png^[colorize:" .. color .. ":48",
            },
            paramtype2 = "colorfacedir",
            place_param2 = 0,
        } end
    )
    -- STONE
    -- Main material to make up a planet
    -- Is entirely solid and anisotropic
    register_color_variants(
        "stone", 16, 2,
        fnColorStone,
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
            paramtype2 = "facedir",
            place_param2 = 0
        } end
    )
end

function register_liquid_nodes()
    -- WATER
    -- The liquid that fills a temperate planet's oceans.
    -- Most common liquid; essential for life.
    register_color_variants(
        "water", 4, 4,
        nil,
        function (n, color) return {
            drawtype = "liquid",
            visual_scale = 1.0,
            tiles = {
                {
                    name = "water_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 2.0
                    }
                },
                {
                    name = "water_animation.png^[opacity:180",
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
            palette = "palette_water" .. n .. ".png",
            paramtype = "light",
            paramtype2 = "colorfacedir",
            place_param2 = 0,
            is_ground_content = false,
            walkable = false,
            liquidtype = "source",
            liquid_alternative_flowing = "planetgen:flowing_water" .. n,
    	    liquid_alternative_source = "planetgen:water" .. n,
            waving = 3,
        } end
    )
    register_color_variants(
        "flowing_water", 4, 4,
        nil,
        function (n, color) return {
            drawtype = "flowingliquid",
            visual_scale = 1.0,
            tiles = {"water.png"},
            special_tiles = {
                {
                    name = "water_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 2.0
                    }
                },
                {
                    name = "water_animation.png^[opacity:180",
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
            palette = "palette_water" .. n .. ".png",
            paramtype = "light",
            paramtype2 = "flowingliquid",
            place_param2 = 0,
            is_ground_content = false,
            walkable = false,
            liquidtype = "flowing",
            liquid_alternative_flowing = "planetgen:flowing_water" .. n,
    	    liquid_alternative_source = "planetgen:water" .. n,
            waving = 3,
        } end
    )
    -- HYDROCARBON
    -- Extremely cold, liquid short-chain hydrocarbon mix.
    -- Forms lakes in very cold planets.
    register_color_variants(
        "hydrocarbon", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "liquid",
            visual_scale = 1.0,
            tiles = {
                {
                    name = "hydrocarbon_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                },
                {
                    name = "hydrocarbon_animation.png^[opacity:180",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                }
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            is_ground_content = false,
            walkable = false,
            liquidtype = "source",
            liquid_alternative_flowing = "planetgen:flowing_hydrocarbon" .. n,
    	    liquid_alternative_source = "planetgen:hydrocarbon" .. n,
            waving = 3,
        } end
    )
    register_color_variants(
        "flowing_hydrocarbon", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "flowingliquid",
            visual_scale = 1.0,
            tiles = {"hydrocarbon.png"},
            special_tiles = {
                {
                    name = "hydrocarbon_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                },
                {
                    name = "hydrocarbon_animation.png^[opacity:180",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                }
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "flowingliquid",
            place_param2 = 0,
            is_ground_content = false,
            walkable = false,
            liquidtype = "flowing",
            liquid_alternative_flowing = "planetgen:flowing_hydrocarbon" .. n,
    	    liquid_alternative_source = "planetgen:hydrocarbon" .. n,
            waving = 3,
        } end
    )
    -- LAVA
    -- Molten mix of rocks at high temperature.
    -- Fills the oceans of very hot planets with intense volcanic activity.
    register_color_variants(
        "lava", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "liquid",
            visual_scale = 1.0,
            tiles = {
                {
                    name = "lava_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 8.0
                    }
                },
                {
                    name = "lava_animation.png^[opacity:180",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 8.0
                    }
                }
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            is_ground_content = false,
            walkable = false,
            liquidtype = "source",
            liquid_alternative_flowing = "planetgen:flowing_lava" .. n,
    	    liquid_alternative_source = "planetgen:lava" .. n,
            waving = 3,
        } end
    )
    register_color_variants(
        "flowing_lava", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "flowingliquid",
            visual_scale = 1.0,
            tiles = {"lava.png"},
            special_tiles = {
                {
                    name = "lava_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 8.0
                    }
                },
                {
                    name = "lava_animation.png^[opacity:180",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 8.0
                    }
                }
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "flowingliquid",
            place_param2 = 0,
            is_ground_content = false,
            walkable = false,
            liquidtype = "flowing",
            liquid_alternative_flowing = "planetgen:flowing_lava" .. n,
    	    liquid_alternative_source = "planetgen:lava" .. n,
            waving = 3,
        } end
    )
end

--[[
 # REGISTRATION
Color variants can be generated in two ways: one involves creating a color
palette at node registration and giving values to 'planet.color_dictionary[id]'.
The other is done by passing a value of 'num_variants' > 1 to function
'register_color_variants()', thus creating multiple node types. Of course, both
can be combined, by creating as many palettes as 'num_variants' and using
parameter 'n' of 'def_fn' to choose.
]]

function register_all_nodes()
    register_base_nodes()
    register_liquid_nodes()
end

--[[
 # VARIANT SELECTION
]]

function choose_planet_nodes_and_colors(planet)
    local G = PcgRandom(planet.seed, planet.seed)
    local stone_color = G:next(1, 16)
    planet.node_types.dust = minetest.get_content_id("planetgen:dust" .. stone_color)
    planet.node_types.sediment = minetest.get_content_id("planetgen:sediment" .. stone_color)
    planet.node_types.gravel = minetest.get_content_id("planetgen:gravel" .. stone_color)
    planet.node_types.stone = minetest.get_content_id("planetgen:stone" .. stone_color)
    if planet.atmosphere == "freezing" then
        planet.node_types.liquid = minetest.get_content_id("planetgen:hydrocarbon")
    elseif planet.atmosphere == "scorching" then
        planet.node_types.liquid = minetest.get_content_id("planetgen:lava")
    elseif gen_true_with_probability(G, planet.terrestriality + 0.18) then
        planet.node_types.liquid = minetest.get_content_id("planetgen:water" .. G:next(1, 3))
        planet.color_dictionary[planet.node_types.liquid] = G:next(0, 7)
    else
        planet.node_types.liquid = minetest.get_content_id("planetgen:water" .. 4)
        planet.color_dictionary[planet.node_types.liquid] = G:next(0, 7)
    end
end
