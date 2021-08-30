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
    groups = { oddly_breakable_by_hand=3 },
    mesh = "seat.obj",

    visual = "mesh",
    textures = {
        "seat.png", "seat.png", "seat.png",
        "seat.png", "seat.png", "seat.png"
    },
})
