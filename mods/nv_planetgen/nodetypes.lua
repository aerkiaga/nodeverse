--[[
The functions in this file perform registration of all node types used by the
mod, and then assign these to the different planets. Each base node type has
one or more variants to this end.

Some of the color-generation functions in this file match equivalent functions
in 'textures/palettes/generate.scm'; if you edit any of the functions marked as
such, you should perform the same changes in that file.

 # INDEX
    NODE TYPES
    REGISTRATION
    VARIANT SELECTION
]]

nv_planetgen.color_multiplier = {}
local function register_color_variants(name, num_variants, random_yrot, color_fn, def_fn)
    --[[
    Will register a number of node types. These are meant to be variants of a
    common abstract node type.
    name            string      node base name, e.g. 'tall_grass'
    num_variants    number      number of distinct node types to register
    random_yrot     number      value to be registered at 'nv_planetgen.random_yrot_nodes'
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
    name = "nv_planetgen:" .. name
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
        local definition = def_fn(n, color)
        minetest.register_node(variant_name, definition)
        local id = minetest.get_content_id(variant_name)
        nv_planetgen.random_yrot_nodes[id] = random_yrot
        if definition.paramtype2 == "color" then
            nv_planetgen.color_multiplier[id] = 1
        elseif definition.paramtype2 == "color4dir" then
            nv_planetgen.color_multiplier[id] = 4
        elseif definition.paramtype2 == "colorwallmounted" then
            nv_planetgen.color_multiplier[id] = 8
        elseif definition.paramtype2 == "colorfacedir"
        or definition.paramtype2 == "colordegrotate" then
            nv_planetgen.color_multiplier[id] = 32
        end
    end
end

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
local function fnColorWater(n)
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

--[[
 # NODE TYPES
Allocated: 110
7  .... base
2           dust
2           sediment
2           gravel
1           stone
68 .... liquid
32          water
32          flowing_water
1           hydrocarbon
1           flowing_hydrocarbon
1           lava
1           flowing_lava
1 ..... icy
1           snow
1           ice
34  ... base floral
16          grass_soil
6           grass
6           dry_grass
6           tall_grass
]]--

local function register_base_nodes()
    -- DUST
    -- Covers a planet's surface
    -- Made of the same material as STONE
    -- 16 stone colors as palette and nodetype
    register_color_variants(
        "dust", 2, 24,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_dust.png",
                "nv_dust2.png",
                "nv_dust.png",
                "nv_dust2.png",
                "nv_dust2.png",
                "nv_dust.png"
            },
            palette = string.format("nv_palette_stone%d.png", n),
            paramtype = "light",
            paramtype2 = "colorfacedir",
            place_param2 = 0,
            sounds = {
                footstep = {
                    name = "nv_step_dust", gain = 0.2, pitch = 1
                }
            },
            drop = "",
            groups = {crumbly = 1},
        } end
    )
    -- SEDIMENT
    -- Covers a planet's ocean floor and beaches
    -- Made of the same material as STONE
    -- Deposited by LIQUID over time
    -- 16 stone colors as palette and nodetype
    register_color_variants(
        "sediment", 2, 24,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_sediment.png",
                "nv_sediment2.png",
                "nv_sediment.png",
                "nv_sediment2.png",
                "nv_sediment2.png",
                "nv_sediment.png"
            },
            palette = string.format("nv_palette_stone%d.png", n),
            paramtype = "light",
            paramtype2 = "colorfacedir",
            place_param2 = 0,
            sounds = {
                footstep = {
                    name = "nv_step_sediment", gain = 0.07, pitch = 1
                }
            },
            drop = "",
            groups = {crumbly = 2},
        } end
    )
    -- GRAVEL
    -- Lies under a layer of DUST
    -- Less granular than DUST
    -- 16 stone colors as palette and nodetype
    register_color_variants(
        "gravel", 2, 4,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_gravel.png",
                "nv_gravel.png",
                "nv_gravel.png^[transformR180",
                "nv_gravel.png^[transformR90",
                "nv_gravel.png^[transformR270",
                "nv_gravel.png",
            },
            palette = string.format("nv_palette_stone%d.png", n),
            paramtype = "light",
            paramtype2 = "colorfacedir",
            place_param2 = 0,
            sounds = {
                footstep = {
                    name = "nv_step_gravel", gain = 0.3, pitch = 1
                }
            },
            drop = "",
            groups = {crumbly = 1},
        } end
    )
    -- STONE
    -- Main material to make up a planet
    -- Is entirely solid and anisotropic
    -- 16 stone colors as palette
    register_color_variants(
        "stone", 1, 2,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_stone.png",
                "nv_stone.png",
                "nv_stone.png^[transformR180",
                "nv_stone.png",
                "nv_stone.png^[transformR180",
                "nv_stone.png"
            },
            palette = "nv_palette_stone.png",
            paramtype = "light",
            paramtype2 = "color4dir",
            place_param2 = 0,
            sounds = {
                footstep = {
                    name = "nv_step_stone", gain = 0.4, pitch = 1
                }
            },
            drop = "",
            groups = {cracky = 1},
            nv_vineable = true,
        } end
    )
end

local function register_liquid_nodes()
    -- WATER
    -- The liquid that fills a temperate planet's oceans.
    -- Most common liquid; essential for life.
    -- 32 water colors as nodetype
    register_color_variants(
        "water", 32, 4,
        fnColorWater,
        function (n, color) return {
            drawtype = "liquid",
            visual_scale = 1.0,
            tiles = {
                {
                    name = "nv_water_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 2.0
                    }
                },
                {
                    name = "nv_water_animation.png^[opacity:180",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 2.0
                    }
                }
            },
            color = color,
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            is_ground_content = false,
            sunlight_propagates = true,
            walkable = false,
            pointable = false,
            buildable_to = true,
            liquidtype = "source",
            liquid_alternative_flowing = "nv_planetgen:flowing_water" .. n,
            liquid_alternative_source = "nv_planetgen:water" .. n,
            liquid_viscosity = 1,
            waving = 3,
        } end
    )
    -- 32 water colors as nodetype
    register_color_variants(
        "flowing_water", 32, 4,
        fnColorWater,
        function (n, color) return {
            drawtype = "flowingliquid",
            visual_scale = 1.0,
            tiles = {"nv_water.png"},
            special_tiles = {
                {
                    name = "nv_water_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                },
                {
                    name = "nv_water_animation.png^[opacity:180",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                }
            },
            color = color,
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "flowingliquid",
            place_param2 = 0,
            is_ground_content = false,
            sunlight_propagates = true,
            walkable = false,
            pointable = false,
            buildable_to = true,
            liquidtype = "flowing",
            liquid_alternative_flowing = "nv_planetgen:flowing_water" .. n,
            liquid_alternative_source = "nv_planetgen:water" .. n,
            liquid_viscosity = 1,
            waving = 3,
        } end
    )
    -- HYDROCARBON
    -- Extremely cold, liquid short-chain hydrocarbon mix.
    -- Forms lakes in very cold planets.
    -- Single variant
    register_color_variants(
        "hydrocarbon", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "liquid",
            visual_scale = 1.0,
            tiles = {
                {
                    name = "nv_hydrocarbon_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                },
                {
                    name = "nv_hydrocarbon_animation.png^[opacity:180",
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
            sunlight_propagates = true,
            walkable = false,
            buildable_to = true,
            liquidtype = "source",
            liquid_alternative_flowing = "nv_planetgen:flowing_hydrocarbon",
            liquid_alternative_source = "nv_planetgen:hydrocarbon",
            liquid_viscosity = 0,
            damage_per_second = 2 * 2,
            waving = 3,
        } end
    )
    -- Single variant
    register_color_variants(
        "flowing_hydrocarbon", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "flowingliquid",
            visual_scale = 1.0,
            tiles = {"nv_hydrocarbon.png"},
            special_tiles = {
                {
                    name = "nv_hydrocarbon_animation.png^[opacity:180",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 4.0
                    }
                },
                {
                    name = "nv_hydrocarbon_animation.png^[opacity:180",
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
            sunlight_propagates = true,
            walkable = false,
            buildable_to = true,
            liquidtype = "flowing",
            liquid_alternative_flowing = "nv_planetgen:flowing_hydrocarbon",
            liquid_alternative_source = "nv_planetgen:hydrocarbon",
            liquid_viscosity = 0,
            damage_per_second = 2 * 2,
            waving = 3,
        } end
    )
    -- LAVA
    -- Molten mix of rocks at high temperature.
    -- Fills the oceans of very hot planets with intense volcanic activity.
    -- Single variant
    register_color_variants(
        "lava", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "liquid",
            visual_scale = 1.0,
            tiles = {
                {
                    name = "nv_lava_animation.png",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 8.0
                    }
                },
                {
                    name = "nv_lava_animation.png",
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
            light_source = 4,
            is_ground_content = false,
            walkable = false,
            buildable_to = true,
            liquidtype = "source",
            liquid_alternative_flowing = "nv_planetgen:flowing_lava",
            liquid_alternative_source = "nv_planetgen:lava",
            liquid_viscosity = 7,
            damage_per_second = 4 * 2,
            waving = 3,
        } end
    )
    -- Single variant
    register_color_variants(
        "flowing_lava", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "flowingliquid",
            visual_scale = 1.0,
            tiles = {"nv_lava.png"},
            special_tiles = {
                {
                    name = "nv_lava_animation.png",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 8.0
                    }
                },
                {
                    name = "nv_lava_animation.png",
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
            light_source = 4,
            is_ground_content = false,
            walkable = false,
            buildable_to = true,
            liquidtype = "flowing",
            liquid_alternative_flowing = "nv_planetgen:flowing_lava",
            liquid_alternative_source = "nv_planetgen:lava",
            liquid_viscosity = 7,
            damage_per_second = 4 * 2,
            waving = 3,
        } end
    )
end

local function register_icy_nodes()
    -- SNOW
    -- Covers planets with very low temperatures
    -- Single variant
    register_color_variants(
        "snow", 1, 4,
        nil,
        function (n, color) return {
            drawtype = "nodebox",
            visual_scale = 1.0,
            tiles = {
                "nv_snow_top.png",
            },
            paramtype = "light",
            paramtype2 = "colorfacedir",
            place_param2 = 8,
            walkable = true,
            buildable_to = true,
            leveled = 16,
            node_box = {
                type = "leveled",
                fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
            },
            collision_box = {
                type = "fixed",
                fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}
            },
            sounds = {
                footstep = {
                    name = "nv_step_snow", gain = 0.15, pitch = 1
                }
            },
            drop = "",
            groups = {
                can_replace = 1,
                crumbly = 2,
            },
        } end
    )

    -- ICE
    -- Covers some areas of cold and freezing planets
    -- Single variant
    register_color_variants(
        "ice", 1, 24,
        nil,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_ice.png",
                "nv_ice2.png",
                "nv_ice.png",
                "nv_ice2.png",
                "nv_ice2.png",
                "nv_ice.png"
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "colorfacedir",
            place_param2 = 8,
            walkable = true,
            buildable_to = true,
            sounds = {
                footstep = {
                    name = "nv_step_stone", gain = 0.3, pitch = 2.5
                }
            },
            drop = "",
            groups = {cracky = 2},
        } end
    )
end

local function register_base_floral_nodes()
    -- GRASS SOIL
    -- A surface node for planets supporting life
    -- 16 stone colors as nodetype, 48 grass colors as palette
    register_color_variants(
        "grass_soil", 16, 4,
        fnColorStone,
        function (n, color) return {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                {name = "nv_grass_soil_top.png"},
                {name = "nv_dust.png", color = color},
                {name = "nv_dust2.png", color = color},
                {name = "nv_dust.png", color = color},
                {name = "nv_dust2.png", color = color},
                {name = "nv_dust2.png", color = color}
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_grass_soil_side.png"},
                {name = "nv_grass_soil_side2.png^[transformFX"},
                {name = "nv_grass_soil_side.png^[transformFX"},
                {name = "nv_grass_soil_side2.png"}
            },
            palette = "nv_palette_grass.png",
            paramtype = "light",
            paramtype2 = "color4dir",
            place_param2 = 8,
            sounds = {
                footstep = {
                    name = "nv_step_grass_soil", gain = 0.05, pitch = 1
                }
            },
            drop = "",
            groups = {crumbly = 1},
        } end
    )
    -- GRASS
    -- A short grassy plant
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "grass", 6, 20,
        fnColorGrass,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_grass.png",
            },
            palette = string.format("nv_palette_grass%d.png", n),
            paramtype = "light",
            paramtype2 = "colordegrotate",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = false,
            buildable_to = true,
            selection_box = {
                type = "fixed",
                fixed = {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}}
            },
            drop = "",
            groups = {snappy = 2},
        } end
    )

    -- DRY GRASS
    -- A dry grassy plant
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "dry_grass", 6, 20,
        fnColorGrass,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_grass_dry.png"
            },
            palette = string.format("nv_palette_grass%d.png", n),
            paramtype = "light",
            paramtype2 = "colordegrotate",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = false,
            buildable_to = true,
            selection_box = {
                type = "fixed",
                fixed = {{-0.5, -0.5, -0.5, 0.5, -3/16, 0.5}}
            },
            drop = "",
            groups = {snappy = 2},
        } end
    )

    -- TALL GRASS
    -- A tall grassy plant
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "tall_grass", 6, 20,
        fnColorGrass,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_grass_tall.png"
            },
            palette = string.format("nv_palette_grass%d.png", n),
            paramtype = "light",
            paramtype2 = "colordegrotate",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = false,
            buildable_to = true,
            selection_box = {
                type = "fixed",
                fixed = {{-0.5, -0.5, -0.5, 0.5, 6/16, 0.5}}
            },
            drop = "",
            groups = {snappy = 2},
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

function nv_planetgen.register_all_nodes()
    register_base_nodes()
    register_liquid_nodes()
    register_icy_nodes()
    register_base_floral_nodes()
end

--[[
 # VARIANT SELECTION
]]

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
