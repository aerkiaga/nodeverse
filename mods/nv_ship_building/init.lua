local function seat_rightclick_callback(pos, node, clicker, itemstack, pointed_thing)
    minetest.remove_node(pos)
    pos.y = pos.y + 1
    local ent_seat = minetest.add_entity(pos, "nv_ship_building:ent_seat")
    clicker:set_attach(ent_seat)
end

minetest.register_node("nv_ship_building:seat", {
    description = "Seat",
    drawtype = "normal",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"rocket.png"},
    groups = { oddly_breakable_by_hand=3 },

    on_rightclick = seat_rightclick_callback,
})

minetest.register_entity("nv_ship_building:ent_seat", {
    initial_properties = {
        visual = "cube",
        textures = {
            "rocket.png", "rocket.png", "rocket.png",
            "rocket.png", "rocket.png", "rocket.png"
        },
        --automatic_rotate = 1.0,
    },
})

local function joinplayer_callback(player, last_login)
    local inventory = player:get_inventory()
	inventory:add_item("main", "nv_ship_building:seat 1")
end

minetest.register_on_joinplayer(joinplayer_callback)
