minetest.register_node("nv_ships:seat", {
    description = "Seat",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"seat.png"},
    use_texture_alpha = "clip",
    groups = { oddly_breakable_by_hand=3 },
    mesh = "seat.obj",

    on_rightclick = nv_ships.ship_rightclick_callback,
})

minetest.register_entity("nv_ships:ent_seat", {
    initial_properties = {
        visual = "mesh",
        textures = {
            "seat.png", "seat.png", "seat.png",
            "seat.png", "seat.png", "seat.png"
        },
        use_texture_alpha = true,
        visual_size = {x=10, y=10, z=10},
        mesh = "seat.obj"
    },
})
