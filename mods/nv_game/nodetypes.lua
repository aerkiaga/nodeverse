--[[
Here are defined any nodes required by the Nodeverse game at the top level.

 # INDEX
    NODE TYPES
]]

--[[
 # NODE TYPES
Allocated: 1
1       pinata
]]--

-- PINATA
-- A node that drops random loot upon breaking
minetest.register_node("nv_game:pinata", {
    description = "Piñata",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    tiles = {"nv_pinata.png"},
    use_texture_alpha = "clip",
    groups = {
        oddly_breakable_by_hand = 2,
    },
    mesh = "nv_pinata.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-3/16, -0.5, -0.5, 3/16, 0.5, 0.5}
        },
    },
})
