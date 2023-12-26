--[[
The functions in this file perform registration of all node types used by the
mod. Each base node type has one or more variants to this end.

 # INDEX
    NODE TYPES
    REGISTRATION
    VARIANT SELECTION
]]

local function register_color_variants(name, num_variants, color_fn, def_fn)
    --[[
    Will register a number of node types. These are meant to be variants of a
    common abstract node type.
    name            string      node base name, e.g. 'tall_grass'
    num_variants    number      number of distinct node types to register
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
    name = "nv_flora:" .. name
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

--[[
 # NODE TYPES
Allocated: 48
12 .... small plants
6           aloe_plant
6           fern_plant
24 .... small mushrooms
6           thin_mushroom
6           small_mushroom
6           trumpet_mushroom
6           large_mushroom
6  .... tall grasses
6           cane_grass
6           thick_grass
6           ball_grass
3  .... stems
1           veiny_stem
1           woody_stem
1           succulent_stem
2  .... leaves
1           soft_leaves
1           smooth_cap
1  .... miscellaneous
1           vine
]]--

local function register_small_plants()
    nv_flora.node_types.aloe_plant = {}
    -- ALOE PLANT
    -- Aloe-like bush
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "aloe_plant", 6,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_aloe_plant.png"
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
    for n=1,6 do
        table.insert(nv_flora.node_types.aloe_plant, minetest.get_content_id(string.format("nv_flora:aloe_plant%d", n)))
    end
    
    nv_flora.node_types.fern_plant = {}
    -- FERN PLANT
    -- Fern-like bush
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "fern_plant", 6,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_fern_plant.png"
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
    for n=1,6 do
        table.insert(nv_flora.node_types.fern_plant, minetest.get_content_id(string.format("nv_flora:fern_plant%d", n)))
    end
end

local function register_small_mushrooms()
    nv_flora.node_types.thin_mushroom = {}
    -- THIN MUSHROOM
    -- A glowing mushroom with a long, thin stem and a small cap
    -- 32 grass colors as palette and nodetype
    register_color_variants(
        "thin_mushroom", 4,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_thin_mushroom.png"
            },
            palette = string.format("nv_palette_grass%d.png", n),
            paramtype = "light",
            paramtype2 = "colordegrotate",
            place_param2 = 0,
            light_source = 7,
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
    for n=1,4 do
        table.insert(nv_flora.node_types.thin_mushroom, minetest.get_content_id(string.format("nv_flora:thin_mushroom%d", n)))
    end
    
    nv_flora.node_types.small_mushroom = {}
    -- SMALL MUSHROOM
    -- A small, asymmetrical mushroom
    -- 32 grass colors as palette and nodetype
    register_color_variants(
        "small_mushroom", 4,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_small_mushroom.png"
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
    for n=1,4 do
        table.insert(nv_flora.node_types.small_mushroom, minetest.get_content_id(string.format("nv_flora:small_mushroom%d", n)))
    end
    
    nv_flora.node_types.trumpet_mushroom = {}
    -- TRUMPET MUSHROOM
    -- A large, trumpet-shaped glowing mushroom
    -- 32 grass colors as palette and nodetype
    register_color_variants(
        "trumpet_mushroom", 4,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_trumpet_mushroom.png"
            },
            palette = string.format("nv_palette_grass%d.png", n),
            paramtype = "light",
            paramtype2 = "colordegrotate",
            place_param2 = 0,
            light_source = 11,
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
    for n=1,4 do
        table.insert(nv_flora.node_types.trumpet_mushroom, minetest.get_content_id(string.format("nv_flora:trumpet_mushroom%d", n)))
    end
    
    nv_flora.node_types.large_mushroom = {}
    -- LARGE MUSHROOM
    -- A short mushroom with a very large, dotted cap
    -- 32 grass colors as palette and nodetype
    register_color_variants(
        "large_mushroom", 4,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_large_mushroom.png"
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
    for n=1,4 do
        table.insert(nv_flora.node_types.large_mushroom, minetest.get_content_id(string.format("nv_flora:large_mushroom%d", n)))
    end
end

local function register_tall_grasses()
    nv_flora.node_types.cane_grass = {}
    -- CANE GRASS
    -- Rigid bamboo-like canes
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "cane_grass", 6,
        function (x) 
            local G = PcgRandom(7857467, x)            
            return {
                r = G:next(0, 192), g = G:next(64, 255), b = G:next(0, 192)
            }
        end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_cane_grass.png"
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
            groups = {snappy = 1},
        } end
    )
    for n=1,6 do
        table.insert(nv_flora.node_types.cane_grass, minetest.get_content_id(string.format("nv_flora:cane_grass%d", n)))
    end
    
    nv_flora.node_types.thick_grass = {}
    -- THICK GRASS
    -- A thick central stem with small leaves surrounding it
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "thick_grass", 6,
        function (x) 
            local G = PcgRandom(7857467, x)            
            return {
                r = G:next(0, 192), g = G:next(64, 255), b = G:next(0, 192)
            }
        end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_thick_grass.png"
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
            groups = {snappy = 1},
        } end
    )
    for n=1,6 do
        table.insert(nv_flora.node_types.thick_grass, minetest.get_content_id(string.format("nv_flora:thick_grass%d", n)))
    end
    
    nv_flora.node_types.ball_grass = {}
    -- BALL GRASS
    -- A central stem with discrete spherical bushes
    -- 48 grass colors as palette and nodetype
    register_color_variants(
        "ball_grass", 6,
        function (x) 
            local G = PcgRandom(7857467, x)            
            return {
                r = G:next(0, 192), g = G:next(64, 255), b = G:next(0, 192)
            }
        end,
        function (n, color) return {
            drawtype = "plantlike",
            visual_scale = 1.0,
            tiles = {
                "nv_ball_grass.png"
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
            groups = {snappy = 1},
        } end
    )
    for n=1,6 do
        table.insert(nv_flora.node_types.ball_grass, minetest.get_content_id(string.format("nv_flora:ball_grass%d", n)))
    end
end

local function register_stems()
    nv_flora.node_types.veiny_stem = {}
    -- VEINY STEM
    -- Thick stem with veiny surface
    -- 48 grass colors as palette
    register_color_variants(
        "veiny_stem", 1,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "normal",
            tiles = {
                "nv_veiny_stem_top.png",
                "nv_veiny_stem_top.png",
                "nv_veiny_stem.png^[transformFY",
                "nv_veiny_stem.png^[transformFY",
                "nv_veiny_stem.png",
                "nv_veiny_stem.png"
            },
            palette = "nv_palette_grass.png",
            paramtype = "light",
            paramtype2 = "color4dir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "",
            groups = {choppy = 1},
            nv_vineable = true,
        } end
    )
    nv_flora.node_types.veiny_stem = minetest.get_content_id("nv_flora:veiny_stem")
    
    nv_flora.node_types.woody_stem = {}
    -- WOODY STEM
    -- Thick stem with wood bark texture
    -- 32 grass colors as palette
    register_color_variants(
        "woody_stem", 1,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "normal",
            tiles = {
                "nv_woody_stem_top.png",
                "nv_woody_stem_top.png",
                "nv_woody_stem.png^[transformFY",
                "nv_woody_stem.png^[transformFY",
                "nv_woody_stem.png",
                "nv_woody_stem.png"
            },
            palette = "nv_palette_grass.png",
            paramtype = "light",
            paramtype2 = "color4dir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "",
            groups = {choppy = 1},
            nv_vineable = true,
        } end
    )
    nv_flora.node_types.woody_stem = minetest.get_content_id("nv_flora:woody_stem")
    
    nv_flora.node_types.succulent_stem = {}
    -- SUCCULENT STEM
    -- Water-filled stem, used for branched plants
    -- 48 grass colors as palette
    register_color_variants(
        "succulent_stem", 1,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "normal",
            tiles = {
                "nv_succulent_stem_top.png",
                "nv_succulent_stem_top.png",
                "nv_succulent_stem.png^[transformFY",
                "nv_succulent_stem.png^[transformFY",
                "nv_succulent_stem.png",
                "nv_succulent_stem.png"
            },
            palette = "nv_palette_grass.png",
            paramtype = "light",
            paramtype2 = "color4dir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "",
            groups = {choppy = 2},
        } end
    )
    nv_flora.node_types.succulent_stem = minetest.get_content_id("nv_flora:succulent_stem")
end

local function register_leaves()
    nv_flora.node_types.soft_leaves = {}
    -- SOFT LEAVES
    -- Leaves with a soft appearance
    -- 48 grass colors as palette
    register_color_variants(
        "soft_leaves", 1,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "normal",
            tiles = {
                "nv_soft_leaves.png",
                "nv_soft_leaves.png",
                "nv_soft_leaves.png^[transformFX^[transformFY",
                "nv_soft_leaves.png^[transformFX",
                "nv_soft_leaves.png",
                "nv_soft_leaves.png^[transformFY"
            },
            use_texture_alpha = "clip",
            palette = "nv_palette_grass.png",
            paramtype = "light",
            paramtype2 = "color4dir",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = true,
            buildable_to = false,
            nv_vineable = true,
            drop = "",
            groups = {snappy = 1},
        } end
    )
    nv_flora.node_types.soft_leaves = minetest.get_content_id("nv_flora:soft_leaves")
    
    nv_flora.node_types.smooth_cap = {}
    -- SMOOTH CAP
    -- Smooth, solid, fungus-like material
    -- 32 grass colors as palette
    register_color_variants(
        "smooth_cap", 1,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "normal",
            tiles = {
                "nv_smooth_cap.png",
                "nv_smooth_cap.png",
                "nv_smooth_cap.png^[transformFX^[transformFY",
                "nv_smooth_cap.png^[transformFX",
                "nv_smooth_cap.png",
                "nv_smooth_cap.png^[transformFY"
            },
            palette = "nv_palette_grass.png",
            paramtype = "light",
            paramtype2 = "color4dir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "",
            groups = {choppy = 2},
        } end
    )
    nv_flora.node_types.smooth_cap = minetest.get_content_id("nv_flora:smooth_cap")
end

local function register_miscellaneous()
    nv_flora.node_types.vine = {}
    -- VINE
    -- Leaves with a soft appearance
    -- 8 water colors as palette
    register_color_variants(
        "vine", 2,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "signlike",
            tiles = {
                string.format("nv_vine%d.png", n),
            },
            use_texture_alpha = "clip",
            palette = "nv_palette_water2.png",
            paramtype = "light",
            paramtype2 = "colorwallmounted",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = false,
            climbable = true,
            buildable_to = true,
            selection_box = {
                type = "fixed",
                fixed = {
                    {-0.5, -0.5, -0.5, 0.5, -0.5 + 1/16, 0.5}
                },
            },
            drop = "",
            groups = {snappy = 2},
        } end
    )
    nv_flora.node_types.vine = {
        minetest.get_content_id("nv_flora:vine1"),
        minetest.get_content_id("nv_flora:vine2")
    }
    
    nv_flora.node_types.lilypad = {}
    -- CLASSIC LILYPAD
    -- A standard circular lilypad
    -- 8 water colors as palette
    register_color_variants(
        "classic_lilypad", 1,
        function (x) return {r = 0, g = 0, b = 0} end,
        function (n, color) return {
            drawtype = "signlike",
            tiles = {
                "nv_classic_lilypad.png",
            },
            use_texture_alpha = "clip",
            palette = "nv_palette_water2.png",
            paramtype = "light",
            paramtype2 = "colorwallmounted",
            place_param2 = 0,
            sunlight_propagates = true,
            walkable = true,
            climbable = false,
            buildable_to = true,
            selection_box = {
                type = "fixed",
                fixed = {
                    {-0.5, -0.5, -0.5, 0.5, -0.5 + 1/16, 0.5}
                },
            },
            collision_box = {
                type = "fixed",
                fixed = {
                    {-0.5, -0.5, -0.5, 0.5, -0.5 + 1/16, 0.5}
                },
            },
            drop = "",
            groups = {snappy = 2},
        } end
    )
    nv_flora.node_types.classic_lilypad = minetest.get_content_id("nv_flora:classic_lilypad")
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

nv_flora.node_types = {}
function nv_flora.register_all_nodes()
    register_small_plants()
    register_small_mushrooms()
    register_tall_grasses()
    register_stems()
    register_leaves()
    register_miscellaneous()
end

nv_flora.register_all_nodes()
