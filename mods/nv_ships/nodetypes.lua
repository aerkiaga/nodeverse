local function undo_node_placement(node, pos, placer)
    local inventory = player:get_inventory()
    inventory:add_item("main", node.name .. " 1")
    minetest.remove_node(pos)
end

local function after_place_node_normal(pos, placer, itemstack, pointed_thing)
    local node = minetest.get_node(pos)
    if not nv_ships.try_add_node(node, pos, placer) then
        undo_node_placement(node, pos, placer)
    end
end

local function register_node_and_entity(name, def)
    local node_def = {
        description = def.description or "",
        drawtype = def.drawtype,
        sunlight_propagates = def.sunlight_propagates,
        paramtype2 = def.paramtype2,
        tiles = def.tiles,
        use_texture_alpha = def.use_texture_alpha,
        groups = def.groups,
        mesh = def.mesh,
        after_place_node = after_place_node_normal,
        on_rightclick = nv_ships.ship_rightclick_callback,
    }
    minetest.register_node("nv_ships:" .. name, node_def)

    local ent_use_texture_alpha = false
    if def.use_texture_alpha == "blend" then
        ent_use_texture_alpha = true
    end
    local ent_def = {
        visual = def.visual,
        textures = def.textures,
        use_texture_alpha = ent_use_texture_alpha,
        visual_size = {x=10, y=10, z=10},
        mesh = def.mesh
    }
    minetest.register_entity("nv_ships:ent_" .. name, ent_def)
end

register_node_and_entity("seat", {
    description = "Seat",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"seat.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "seat.obj",

    visual = "mesh",
    textures = {"seat.png"},
})

register_node_and_entity("floor", {
    description = "Floor",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"floor.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "floor.obj",

    visual = "mesh",
    textures = {"floor.png"},
})

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
