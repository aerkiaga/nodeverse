--[[
It is in this file that all spaceship nodes are defined. Each node type is associated
with an entity type, following a simple naming scheme (e.g. "nv_ships:seat" vs "nv_ships:ent_seat").

 # INDEX
    CALLBACKS
    COMMON REGISTRATION
    NODE TYPES
]]

--[[
 # CALLBACKS
]]

local function after_place_node_normal(pos, placer, itemstack, pointed_thing)
    local node = minetest.get_node(pos)
    if not nv_ships.try_add_node(node, pos, placer) then
        minetest.remove_node(pos)
        return true -- Don't remove from inventory
    end
end

local function can_dig_normal(pos, player)
    if player == nil then
        return false
    end
    return nv_ships.can_dig_node(pos, player)
end

local function after_dig_node_normal(pos, oldnode, oldmetadata, digger)
    if not nv_ships.try_remove_node(oldnode, pos, digger) then
        minetest.set_node(pos, oldnode)
        return
    end
    local start = string.find(oldnode.name, "_hull%d*")
    if start ~= nil then
        local new_name = string.sub(oldnode.name, 0, start-1)
        minetest.set_node(pos, {name=new_name, param1=oldnode.param1, param2=oldnode.param2})
    end
end

--[[
 # COMMON REGISTRATION
]]

nv_ships.node_name_to_ent_name_dict = {}

local function register_node_and_entity(name, def)
    local node_def = {
        description = def.description or "",
        drawtype = def.drawtype,
        is_ground_content = false,
        sunlight_propagates = def.sunlight_propagates,
        paramtype2 = def.paramtype2,
        tiles = def.tiles,
        color = def.color,
        use_texture_alpha = def.use_texture_alpha,
        groups = def.groups,
        node_box = def.node_box,
        mesh = def.mesh,
        selection_box = def.selection_box or def.collision_box,
        collision_box = def.collision_box,
        drop = def.drop,
        after_place_node = after_place_node_normal,
        after_dig_node = after_dig_node_normal,
        can_dig = can_dig_normal,
        on_rightclick = nv_ships.ship_rightclick_callback,
    }
    minetest.register_node("nv_ships:" .. name, node_def)

    local ent_use_texture_alpha = false
    if def.use_texture_alpha == "blend" then
        ent_use_texture_alpha = true
    end
    local colorized_textures = table.copy(def.textures)
    if def.color ~= nil then
        for n=1, #colorized_textures do
            colorized_textures[n] = colorized_textures[n] .. "^[multiply:" .. def.color
        end
    end
    local ent_def = {
        visual = def.visual,
        textures = colorized_textures,
        use_texture_alpha = ent_use_texture_alpha,
        visual_size = {x=10, y=10, z=10},
        mesh = def.mesh
    }
    minetest.register_entity("nv_ships:ent_" .. name, ent_def)

    if def.nv_no_entity then
        nv_ships.node_name_to_ent_name_dict["nv_ships:" .. name] = ""
    else
        nv_ships.node_name_to_ent_name_dict["nv_ships:" .. name] = "nv_ships:ent_" .. name
    end
end

local function register_hull_node_and_entity(name, def)
    local default_palette = {
        "#EDEDED", "#9B9B9B", "#4A4A4A", "#212121", "#284E9B",
        "#2F939B", "#6DEE1D", "#287C00", "#F7F920", "#D86128",
        "#683B0C", "#C11D26", "#F9A3A5", "#D10082", "#4C007F",
    }
    for n=1, 15 do
        local colored_def = {
            description = def.description,
            drawtype = def.drawtype,
            is_ground_content = false,
            sunlight_propagates = def.sunlight_propagates,
            paramtype2 = def.paramtype2,
            tiles = def.tiles,
            use_texture_alpha = def.use_texture_alpha,
            groups = def.groups,
            mesh = def.mesh,
            selection_box = def.selection_box or def.collision_box,
            collision_box = def.collision_box,
            drop = def.drop,
            after_place_node = def.after_place_node,
            on_rightclick = nv_ships.ship_rightclick_callback,

            visual = def.visual,
            textures = def.textures,
            use_texture_alpha = def.use_texture_alpha,
            visual_size = def.visual_size,
            mesh = def.mesh,

            color = default_palette[n],
            drop = "nv_ships:hull_plate" .. n,
        }
        register_node_and_entity(name .. n, colored_def)
    end
end

--[[
 # NODE TYPES
Allocated: 3
1       seat
1       floor
1       scaffold
15      scaffold_hull
1       landing_leg
]]--

-- SEAT
-- A pilot seat to man the ship
-- Defines cockpit position and orientation
-- Required for liftoff
-- At most one per ship
register_node_and_entity("seat", {
    description = "Pilot seat",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"nv_seat.png"},
    use_texture_alpha = "clip",
    groups = {
        oddly_breakable_by_hand = 3,
        fall_damage_add_percent = -100,
        bouncy = 0
    },
    mesh = "nv_seat.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0, 0.5}
        },
    },

    visual = "mesh",
    textures = {"nv_seat.png"},
})

-- SCAFFOLD
-- A full block of scaffolding
register_node_and_entity("scaffold", {
    description = "Ship scaffold",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"nv_scaffold.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_scaffold.obj",

    visual = "mesh",
    textures = {"nv_scaffold.png"},
})

-- SCAFFOLD HULL
-- A full block of ship hull
-- Shouldn't be obtainable
register_hull_node_and_entity("scaffold_hull", {
    description = "Scaffold hull",
    drawtype = "mesh",
    sunlight_propagates = false,
    paramtype2 = "colorfacedir",

    tiles = {"nv_scaffold_hull.png"},
    use_texture_alpha = "opaque",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_scaffold.obj",

    visual = "mesh",
    textures = {"nv_scaffold_hull.png"},
})

-- FLOOR
-- A thin scaffold floor occupying the bottom 1/4 of the node
-- Can be walked on easily
register_node_and_entity("floor", {
    description = "Ship floor",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"nv_floor.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_floor.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}
        },
    },

    visual = "mesh",
    textures = {"nv_floor.png"},
})

-- LANDING LEG
-- A retractable landing leg for spacecraft
-- Has no entity form
register_node_and_entity("landing_leg", {
    description = "Landing leg",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"nv_landing_leg.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_landing_leg.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25}
        },
    },

    visual = "mesh",
    textures = {"nv_landing_leg.png"},

    nv_no_entity = true,
})

-- GLASS FACE
-- A glass square cutting a node-shaped space in half
-- Should be unobtainable
-- TODO: handle side faces being visible with multiple connected panes
register_node_and_entity("glass_face", {
    description = "Glass face",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {{
        name = "nv_glass.png",
        backface_culling = true,
        align_style = "world"
    }},
    use_texture_alpha = "blend",
    groups = {oddly_breakable_by_hand = 3},
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625},
        }
    },
    mesh = "nv_glass_face.obj",
    drop = "nv_ships:glass_pane",

    visual = "mesh",
    textures = {"nv_glass.png"},

    nv_no_entity = false,
})

-- GLASS EDGE
-- Two perpendicular glass rectangles separating a quadrant of a node
-- Should be unobtainable
register_node_and_entity("glass_edge", {
    description = "Glass edge",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {{
        name = "nv_glass.png",
        backface_culling = true,
        align_style = "world"
    }},
    use_texture_alpha = "blend",
    groups = {oddly_breakable_by_hand = 3},
    node_box = {
        type = "fixed",
        fixed = {
            {-0.0625, -0.5, -0.0625, 0.5, 0.5, 0.0625},
            {-0.0625, -0.5, 0.0625, 0.0625, 0.5, 0.5}
        }
    },
    mesh = "nv_glass_edge.obj",
    selection_box = {
        type = "fixed",
        fixed = {
            {-0.0625, -0.5, -0.0625, 0.5, 0.5, 0.5}
        }
    },
    drop = "nv_ships:glass_pane",

    visual = "mesh",
    textures = {"nv_glass.png"},

    nv_no_entity = false,
})

-- GLASS VERTEX
-- Three perpendicular glass squares separating an octant of a node
-- Should be unobtainable
register_node_and_entity("glass_vertex", {
    description = "Glass vertex",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {{
        name = "nv_glass.png",
        backface_culling = true,
        align_style = "world"
    }},
    use_texture_alpha = "blend",
    groups = {oddly_breakable_by_hand = 3},
    node_box = {
        type = "fixed",
        fixed = {
            {-0.0625, 0.0625, -0.0625, 0.5, 0.5, 0.0625},
            {-0.0625, 0.0625, 0.0625, 0.0625, 0.5, 0.5},
            {-0.0625, -0.0625, -0.0625, 0.5, 0.0625, 0.5}
        }
    },
    mesh = "nv_glass_vertex.obj",
    selection_box = {
        type = "fixed",
        fixed = {
            {-0.0625, -0.0625, -0.0625, 0.5, 0.5, 0.5}
        }
    },
    drop = "nv_ships:glass_pane",

    visual = "mesh",
    textures = {"nv_glass.png"},

    nv_no_entity = false,
})
