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
Allocated: 12
6  .... small plant
6           aloe_plant
6  .... tall grass
6           cane_grass
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
            }
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
            }
        } end
    )
    for n=1,6 do
        table.insert(nv_flora.node_types.fern_plant, minetest.get_content_id(string.format("nv_flora:fern_plant%d", n)))
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
            }
        } end
    )
    for n=1,6 do
        table.insert(nv_flora.node_types.cane_grass, minetest.get_content_id(string.format("nv_flora:cane_grass%d", n)))
    end
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
    register_tall_grasses()
end

nv_flora.register_all_nodes()
