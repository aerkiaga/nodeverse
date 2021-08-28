--[[
This file controls how data is persented to the player in the HUD.

# INDEX
    INITIALIZATION
]]--

-- Rightclick definition
local function rocket_rightclick(pos, node, clicker, itemstack, pointed_thing)
    -- Remove the rocket on the ground
    minetest.remove_node(pos)
    -- Change the player into a rocket player
    rocket.player_to_rocket(clicker, pos)
end

-- Rocket Node Definition
local rocket_definition = {
    description =  "Rocket",
    drawtype = "mesh",
    mesh = "rocket.obj",
    sunlight_propagates = true,
    paramtype2 = "facedir",
    collision_box = {
        type = "fixed",
        fixed = {{0.95, -1.55, -0.55, -0.25, -0.65, 0.55}} --overwritten later
    },
    selection_box = {
        type = "fixed",
        fixed = {{0.95, -1.55, -0.55, -0.25, -0.65, 0.55}} --overwritten later
    },

    tiles = {"rocket.png"},
    groups = { oddly_breakable_by_hand=3 },

    on_rightclick = rocket_rightclick,
}

--[[
 # INITIALIZATION
]]--

-- Register with auto-box, allowing multi-node collision-box representations
autobox.register_node("rocket:rocket", "rocket.box", rocket_definition, true)
