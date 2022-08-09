--[[
Here are defined any nodes required by the Nodeverse game at the top level.

 # INDEX
    LOOT CALCULATION
    NODE TYPES
]]

--[[
 # LOOT CALCULATION
]]--

local loot_table = {
    ["nv_ships:seat"] = 10,
    ["nv_ships:control_panel"] = 10,
    ["nv_ships:floor 3"] = 3,
    ["nv_ships:scaffold 2"] = 1,
    ["nv_ships:landing_leg"] = 5,
    ["nv_ships:hull_plate1 5"] = 10,
    ["nv_ships:hull_plate2 5"] = 10,
    ["nv_ships:hull_plate3 5"] = 10,
    ["nv_ships:hull_plate4 5"] = 10,
    ["nv_ships:hull_plate5 5"] = 10,
    ["nv_ships:hull_plate6 5"] = 10,
    ["nv_ships:hull_plate7 5"] = 10,
    ["nv_ships:hull_plate8 5"] = 10,
    ["nv_ships:hull_plate9 5"] = 10,
    ["nv_ships:hull_plate10 5"] = 10,
    ["nv_ships:hull_plate11 5"] = 10,
    ["nv_ships:hull_plate12 5"] = 10,
    ["nv_ships:hull_plate13 5"] = 10,
    ["nv_ships:hull_plate14 5"] = 10,
    ["nv_ships:hull_plate15 5"] = 10,
}

local function compute_pinata_loot_table()
    local raw_p = 0
    for name, rarity in pairs(loot_table) do
        raw_p = raw_p + 1 / rarity
    end
    local weighted_loot_table = {}
    local remaining_p = 1
    for name, rarity in pairs(loot_table) do
        weighted_loot_table[name] = rarity * raw_p * remaining_p
        remaining_p = remaining_p * (1 - 1 / weighted_loot_table[name])
    end
    local r = {}
    local index = 1
    for name, rarity in pairs(weighted_loot_table) do
        r[index] = {}
        r[index].items = {name}
        r[index].rarity = rarity
        index = index + 1
    end
    return {
        max_items = 1,
        items = r,
    }
end

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
    
    drop = compute_pinata_loot_table(),
})
