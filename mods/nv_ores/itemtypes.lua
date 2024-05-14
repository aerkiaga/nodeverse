--[[
This file defines items that are not associated with a particular nodetype.

 # INDEX
    ITEM TYPES
]]

--[[
 # ITEM TYPES
Allocated: 1
1       iron_oxide
1       aluminium_hydroxide
1       calcium_carbonate
1       sodium_chloride
1       sulfur
]]

minetest.register_craftitem("nv_ores:iron_oxide", {
    description = "Iron oxide",
    short_description = "Iron oxide",
    inventory_image = "nv_iron_oxide.png",
})

minetest.register_craftitem("nv_ores:aluminium_hydroxide", {
    description = "Aluminium hydroxide",
    short_description = "Aluminium hydroxide",
    inventory_image = "nv_aluminium_hydroxide.png",
})

minetest.register_craftitem("nv_ores:calcium_carbonate", {
    description = "Calcium carbonate",
    short_description = "Calcium carbonate",
    inventory_image = "nv_calcium_carbonate.png",
})

minetest.register_craftitem("nv_ores:sodium_chloride", {
    description = "Sodium chloride",
    short_description = "Sodium chloride",
    inventory_image = "nv_sodium_chloride.png",
})

minetest.register_craftitem("nv_ores:sulfur_pieces", {
    description = "Sulfur",
    short_description = "Sulfur",
    inventory_image = "nv_sulfur_pieces.png",
})
