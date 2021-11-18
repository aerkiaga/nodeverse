--[[
This file defines items that are not associated with a particular nodetype.

 # INDEX
    CALLBACKS
    COMMON REGISTRATION
    ITEM TYPES
]]

--[[
 # CALLBACKS
]]

local function on_place_hull_plate(itemstack, placer, pointed_thing)
    if pointed_thing.type ~= "node" then
        return nil -- Don't remove from inventory
    end
    local pos = pointed_thing.under
    local node = minetest.get_node(pos)
    local name = itemstack:get_name()
    local index = tonumber(string.sub(name, string.len("nv_ships:hull_plate")+1))
    local new_node = nv_ships.try_add_hull(node, pos, placer, index)
    if new_node ~= nil then
        minetest.set_node(pos, new_node)
        itemstack:take_item(1)
        return itemstack
    end
end

--[[
 # COMMON REGISTRATION
]]

local function register_item_colors(name, def)
    --[[
    Using palettes would be more efficient, but unfortunately the current API
    still seems to contain some unimplemented features around them.
    ]]
    local default_palette = {
        "#EDEDED", "#9B9B9B", "#4A4A4A", "#212121", "#284E9B",
        "#2F939B", "#6DEE1D", "#287C00", "#F7F920", "#D86128",
        "#683B0C", "#C11D26", "#F9A3A5", "#D10082", "#4C007F",
    }
    local color_names = {
        "White", "Grey", "Dark grey", "Black", "Blue",
        "Cyan", "Green", "Dark green", "Yellow", "Orange",
        "Brown", "Red", "Pink", "Magenta", "Violet",
    }
    for n=1, 15 do
        local description = (color_names[n] or "") .. " " .. def.uncolored_description
        local item_def = {
            description = description,
            short_description = description,
            inventory_image = def.inventory_image,
            inventory_overlay = def.inventory_overlay,
            color = default_palette[n],
            on_place = on_place_hull_plate,
        }
        minetest.register_craftitem("nv_ships:" .. name .. n, item_def)
    end
end

--[[
 # ITEM TYPES
Allocated: 2
15      hull_plate
]]

register_item_colors("hull_plate", {
    uncolored_description = "hull plate",
    short_description = "hull plate",
    inventory_image = "hull_plate.png",
    inventory_overlay = "hull_plate_overlay.png",
})
