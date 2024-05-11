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
Allocated: 1
1  .... ores
1           hematite
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
            paramtype = "light",
            paramtype2 = "facedir",
            place_param2 = 0,
            sunlight_propagates = false,
            walkable = true,
            buildable_to = false,
            drop = "",
            groups = {crumbly = 2},
        }, 4
    )
end

--[[
 # REGISTRATION
]]

nv_ores.node_types = {}
function nv_ores.register_all_nodes()
    register_ores()
end

nv_ores.register_all_nodes()
minetest.safe_file_write(minetest.get_worldpath() .. "/nv_ores.node_types", minetest.serialize(nv_ores.node_types))
