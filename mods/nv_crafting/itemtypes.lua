minetest.register_craftitem("nv_crafting:basic_fuel", {
    description = "Basic fuel",
    short_description = "Basic fuel",
    inventory_image = "nv_basic_fuel.png",
})

minetest.register_craftitem("nv_crafting:aluminium_oxide", {
    description = "Aluminium oxide",
    short_description = "Aluminium oxide",
    inventory_image = "nv_aluminium_oxide.png",
})

minetest.register_craftitem("nv_crafting:iron", {
    description = "Iron",
    short_description = "Iron",
    inventory_image = "nv_iron.png",
})

minetest.register_craftitem("nv_crafting:bottle", {
    description = "Bottle",
    short_description = "Bottle",
    inventory_image = "nv_bottle.png",
    pointabilities = {
        nodes = {
            ["group:water"] = true,
            ["group:"] = false,
        },
    },
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local node = core.get_node(pos)
            if core.registered_nodes[node.name].groups.water then
                core.set_node(pos, {name = "air", param1 = 0, param2 = 0})
                local count = itemstack:get_count() - 1
                if count > 0 then
                    local inv = minetest.get_inventory({type = "player", name = user:get_player_name()})
	                inv:add_item("main", ItemStack("nv_crafting:water_bottle"))
                    return ItemStack(string.format("nv_crafting:bottle %d", count))
                else
                    return ItemStack("nv_crafting:water_bottle")
                end
            elseif core.registered_nodes[node.name].groups.hydrocarbon then
                core.set_node(pos, {name = "air", param1 = 0, param2 = 0})
                local count = itemstack:get_count() - 1
                if count > 0 then
                    local inv = minetest.get_inventory({type = "player", name = user:get_player_name()})
	                inv:add_item("main", ItemStack("nv_crafting:hydrocarbon_bottle"))
                    return ItemStack(string.format("nv_crafting:bottle %d", count))
                else
                    return ItemStack("nv_crafting:hydrocarbon_bottle")
                end
            end
        end
    end,
})

minetest.register_craftitem("nv_crafting:water_bottle", {
    description = "Water bottle",
    short_description = "Water bottle",
    inventory_image = "nv_water_bottle.png",
})

minetest.register_craftitem("nv_crafting:hydrocarbon_bottle", {
    description = "Hydrocarbon bottle",
    short_description = "Hydrocarbon bottle",
    inventory_image = "nv_hydrocarbon_bottle.png",
})

minetest.register_craftitem("nv_crafting:acid_bottle", {
    description = "Acid bottle",
    short_description = "Acid bottle",
    inventory_image = "nv_acid_bottle.png",
})

minetest.register_craftitem("nv_crafting:cobalt_oxide", {
    description = "Cobalt oxide",
    short_description = "Cobalt oxide",
    inventory_image = "nv_cobalt_oxide.png",
})

minetest.register_craftitem("nv_crafting:magnesium", {
    description = "Magnesium",
    short_description = "Magnesium",
    inventory_image = "nv_magnesium.png",
})

minetest.register_craftitem("nv_crafting:lithium", {
    description = "Lithium",
    short_description = "Lithium",
    inventory_image = "nv_lithium.png",
})

minetest.register_craftitem("nv_crafting:battery", {
    description = "Battery",
    short_description = "Battery",
    inventory_image = "nv_battery.png",
})

minetest.register_craftitem("nv_crafting:molybdenum", {
    description = "Molybdenum",
    short_description = "Molybdenum",
    inventory_image = "nv_molybdenum.png",
})

minetest.register_tool("nv_crafting:pickaxe", {
    description = "Pickaxe",
    short_description = "Pickaxe",
    inventory_image = "nv_pickaxe.png",
    tool_capabilities = {
        full_punch_interval = 0.9,
        max_drop_level = 0,
        groupcaps = {
            crumbly={maxlevel=1, times={[1]=1.30, [2]=0.80, [3]=0.50}},
            cracky={maxlevel=1, times={[1]=2.50*0.5, [2]=2.00*0.5, [3]=1.50*0.5}},
            snappy={maxlevel=1, times={[1]=0.60, [2]=0.40, [3]=0.20}},
            choppy={maxlevel=1, times={[1]=2.10, [2]=1.80, [3]=1.20}},
            oddly_breakable_by_hand={maxlevel=1, times={[1]=0, [2]=0, [3]=0}},
        },
        damage_groups = {fleshy=1},
    },
})

minetest.register_craftitem("nv_crafting:silicon", {
    description = "Silicon",
    short_description = "Silicon",
    inventory_image = "nv_silicon.png",
})

minetest.register_tool("nv_crafting:silicon_pickaxe", {
    description = "Silicon pickaxe",
    short_description = "Silicon pickaxe",
    inventory_image = "nv_silicon_pickaxe.png",
    tool_capabilities = {
        full_punch_interval = 0.9,
        max_drop_level = 0,
        groupcaps = {
            crumbly={maxlevel=1, times={[1]=1.30, [2]=0.80, [3]=0.50}},
            cracky={maxlevel=1, times={[1]=2.50*0.2, [2]=2.00*0.2, [3]=1.50*0.2}},
            snappy={maxlevel=1, times={[1]=0.60, [2]=0.40, [3]=0.20}},
            choppy={maxlevel=1, times={[1]=2.10, [2]=1.80, [3]=1.20}},
            oddly_breakable_by_hand={maxlevel=1, times={[1]=0, [2]=0, [3]=0}},
        },
        damage_groups = {fleshy=1},
    },
})
