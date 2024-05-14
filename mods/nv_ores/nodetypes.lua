--[[
The functions in this file perform registration of all node types used by the
mod. Each base node type has one or more variants to this end.

 # INDEX
    CALLBACK
    NODE TYPES
    REGISTRATION
    VARIANT SELECTION
]]

local function register_node(name, definition, random_yrot)
    local full_name = "nv_ores:" .. name
    minetest.register_node(full_name, definition)
    local id = minetest.get_content_id(full_name)
    nv_planetgen.random_yrot_nodes[id] = random_yrot
    nv_ores.node_types[name] = minetest.get_content_id(full_name)
end

--[[
 # NODE TYPES
Allocated: 11
10 .... large vein ores
4         iron ores
1           hematite
1           magnetite
1           goethite
1           limonite
3         aluminium ores
1           gibbsite
1           boehmite
1           diaspore
2         calcium ores
1           calcite
1           aragonite
1         sodium ores
1           halite
1  .... surface deposit ores
1           sulfur
1           solid_ammonia

]]--

local function register_ores()
    -- HEMATITE
    -- Fe2O3
    register_node(
        "hematite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_hematite.png",
                "nv_hematite.png^[transformR180",
                "nv_hematite.png^[transformR180",
                "nv_hematite.png^[transformR90",
                "nv_hematite.png",
                "nv_hematite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:iron_oxide",
            groups = {cracky = 1},
        }, 4
    )
    
    -- MAGNETITE
    -- Fe3O4
    register_node(
        "magnetite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_magnetite.png",
                "nv_magnetite.png^[transformR180",
                "nv_magnetite.png^[transformR180",
                "nv_magnetite.png^[transformR90",
                "nv_magnetite.png",
                "nv_magnetite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:iron_oxide",
            groups = {cracky = 1},
        }, 4
    )
    
    -- GOETHITE
    -- FeO(OH)
    register_node(
        "goethite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_goethite_top.png",
                "nv_goethite.png^[transformR180",
                "nv_goethite.png^[transformR180",
                "nv_goethite.png^[transformFX",
                "nv_goethite.png",
                "nv_goethite_top.png"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:iron_oxide",
            groups = {cracky = 1},
        }, 4
    )
    
    -- LIMONITE
    -- FeO(OH)·nH2O
    register_node(
        "limonite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_limonite.png",
                "nv_limonite.png^[transformR180",
                "nv_limonite.png^[transformR180",
                "nv_limonite.png^[transformR90",
                "nv_limonite.png",
                "nv_limonite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:iron_oxide",
            groups = {cracky = 1},
        }, 4
    )
    
    -- GIBBSITE
    -- Al(OH)3
    register_node(
        "gibbsite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_gibbsite.png",
                "nv_gibbsite.png^[transformR180",
                "nv_gibbsite.png^[transformR180",
                "nv_gibbsite.png^[transformR90",
                "nv_gibbsite.png",
                "nv_gibbsite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:aluminium_hydroxide",
            groups = {cracky = 3},
        }, 4
    )
    
    -- BOEHMITE
    -- Al(OH) gamma
    register_node(
        "boehmite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_boehmite.png",
                "nv_boehmite.png^[transformR180",
                "nv_boehmite.png^[transformR180",
                "nv_boehmite.png^[transformR90",
                "nv_boehmite.png",
                "nv_boehmite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:aluminium_hydroxide",
            groups = {cracky = 3},
        }, 4
    )
    
    -- DIASPORE
    -- Al(OH) alpha
    register_node(
        "diaspore", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_diaspore_top.png",
                "nv_diaspore.png^[transformR180",
                "nv_diaspore.png^[transformR180",
                "nv_diaspore.png^[transformFX",
                "nv_diaspore.png",
                "nv_diaspore.png"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:aluminium_hydroxide",
            groups = {cracky = 1},
        }, 4
    )
    
    -- CALCITE
    -- CaCO3
    register_node(
        "calcite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_calcite.png",
                "nv_calcite.png^[transformR180",
                "nv_calcite.png^[transformR180",
                "nv_calcite.png^[transformR90",
                "nv_calcite.png",
                "nv_calcite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:calcium_carbonate",
            groups = {cracky = 3},
        }, 4
    )
    
    -- ARAGONITE
    -- CaCO3
    register_node(
        "aragonite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_aragonite.png",
                "nv_aragonite.png^[transformR180",
                "nv_aragonite.png^[transformR180",
                "nv_aragonite.png^[transformR90",
                "nv_aragonite.png",
                "nv_aragonite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:calcium_carbonate",
            groups = {cracky = 2},
        }, 4
    )
    
    -- HALITE
    -- NaCl
    register_node(
        "halite", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_halite.png",
                "nv_halite.png^[transformR180",
                "nv_halite.png^[transformR180",
                "nv_halite.png^[transformR90",
                "nv_halite.png",
                "nv_halite.png^[transformR90"
            },
            overlay_tiles = {
                "",
                "",
                {name = "nv_ore_overlay.png"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png^[transformFX"},
                {name = "nv_ore_overlay.png"}
            },
            use_texture_alpha = "blend",
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:sodium_chloride",
            groups = {cracky = 3},
        }, 4
    )
end

local function register_surface_ores()
    -- SULFUR
    -- S
    register_node(
        "sulfur", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_sulfur.png",
                "nv_sulfur.png^[transformR180",
                "nv_sulfur.png^[transformR180",
                "nv_sulfur.png^[transformR90",
                "nv_sulfur.png",
                "nv_sulfur.png^[transformR90"
            },
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "nv_ores:sulfur_pieces",
            groups = {cracky = 3},
        }, 4
    )
    
    -- SOLID AMMONIA
    -- NH3
    register_node(
        "solid_ammonia", {
            drawtype = "normal",
            visual_scale = 1.0,
            tiles = {
                "nv_solid_ammonia.png",
                "nv_solid_ammonia.png^[transformR180",
                "nv_solid_ammonia.png^[transformR180",
                "nv_solid_ammonia.png^[transformR90",
                "nv_solid_ammonia.png",
                "nv_solid_ammonia.png^[transformR90"
            },
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "",
            groups = {cracky = 3},
        }, 4
    )
end

--[[
 # REGISTRATION
]]

nv_ores.node_types = {}
function nv_ores.register_all_nodes()
    register_ores()
    register_surface_ores()
end

nv_ores.register_all_nodes()
minetest.safe_file_write(minetest.get_worldpath() .. "/nv_ores.node_types", minetest.serialize(nv_ores.node_types))
