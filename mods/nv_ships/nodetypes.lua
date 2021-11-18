--[[
It is in this file that all spaceship nodes are defined. Each node type is associated
with an entity type, following a simple naming scheme (e.g. "nv_ships:seat" vs "nv_ships:ent_seat").

 # INDEX
    COMMON REGISTRATION
    NODE TYPES
]]

local function after_place_node_normal(pos, placer, itemstack, pointed_thing)
    local node = minetest.get_node(pos)
    if not nv_ships.try_add_node(node, pos, placer) then
        minetest.remove_node(pos)
        return true -- Don't remove from inventory
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
        sunlight_propagates = def.sunlight_propagates,
        paramtype2 = def.paramtype2,
        tiles = def.tiles,
        color = def.color,
        use_texture_alpha = def.use_texture_alpha,
        groups = def.groups,
        mesh = def.mesh,
        selection_box = def.collision_box,
        collision_box = def.collision_box,
        after_place_node = after_place_node_normal,
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

    nv_ships.node_name_to_ent_name_dict["nv_ships:" .. name] = "nv_ships:ent_" .. name
end

local function register_colored_node_and_entity(name, def)
    local default_palette = {
        "#EDEDED", "#9B9B9B", "#4A4A4A", "#212121", "#284E9B",
        "#2F939B", "#6DEE1D", "#287C00", "#F7F920", "#D86128",
        "#683B0C", "#C11D26", "#F9A3A5", "#D10082", "#4C007F",
    }
    for n=1, 15 do
        local colored_def = {
            description = def.description or "",
            drawtype = def.drawtype,
            sunlight_propagates = def.sunlight_propagates,
            paramtype2 = def.paramtype2,
            tiles = def.tiles,
            use_texture_alpha = def.use_texture_alpha,
            groups = def.groups,
            mesh = def.mesh,
            selection_box = def.collision_box,
            collision_box = def.collision_box,
            after_place_node = after_place_node_normal,
            on_rightclick = nv_ships.ship_rightclick_callback,

            visual = def.visual,
            textures = def.textures,
            use_texture_alpha = ent_use_texture_alpha,
            visual_size = {x=10, y=10, z=10},
            mesh = def.mesh,

            color = default_palette[n],
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
]]--

-- SEAT
-- A pilot seat to man the ship
-- Defines cockpit position and orientation
-- Required for liftoff
-- At most one per ship
register_node_and_entity("seat", {
    description = "Seat",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"seat.png"},
    use_texture_alpha = "clip",
    groups = {
        oddly_breakable_by_hand = 3,
        fall_damage_add_percent = -100,
        bouncy = 0
    },
    mesh = "seat.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0, 0.5}
        },
    },

    visual = "mesh",
    textures = {"seat.png"},
})

-- SCAFFOLD
-- A full block of scaffolding
register_node_and_entity("scaffold", {
    description = "Scaffold",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"scaffold.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "scaffold.obj",

    visual = "mesh",
    textures = {"scaffold.png"},
})

-- SCAFFOLD HULL
-- A full block of ship hull
register_colored_node_and_entity("scaffold_hull", {
    description = "Scaffold hull",
    drawtype = "mesh",
    sunlight_propagates = false,
    paramtype2 = "colorfacedir",

    tiles = {"scaffold_hull.png"},
    use_texture_alpha = "opaque",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "scaffold.obj",

    visual = "mesh",
    textures = {"scaffold_hull.png"},
})

-- FLOOR
-- A thin scaffold floor occupying the bottom 1/4 of the node
-- Can be walked on easily
register_node_and_entity("floor", {
    description = "Floor",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"floor.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "floor.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}
        },
    },

    visual = "mesh",
    textures = {"floor.png"},
})
