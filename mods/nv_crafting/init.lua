nv_crafting = {}

nv_crafting.furnace_recipes = {}

function nv_crafting.register_furnace_recipe(recipe)
    table.insert(nv_crafting.furnace_recipes, recipe)
end

level_cache = {}

local function get_furnace_formspec(player, level)
    if level then
        level_cache[player:get_player_name()] = level
    else
        level = level_cache[player:get_player_name()]
    end
    local recipes = {}
    for _, recipe in ipairs(nv_crafting.furnace_recipes) do
        if recipe.level <= level then
            table.insert(recipes, recipe)
        end
    end
    local base_formspec = nv_inventory.get_craft_formspec(player, recipes)
    return base_formspec
end

local function furnace_receive_fields_callback(player, fields)
    local name = player:get_player_name()
	for field, value in pairs(fields) do
	    if field == "exit" then
			minetest.close_formspec(name, "furnace")
	    elseif string.sub(field, 1, 6) == "recipe" then
	        local index = tonumber(string.sub(field, 7))
	        local recipe = nv_crafting.furnace_recipes[index]
	        local inv = minetest.get_inventory({type = "player", name = name})
	        for _, item in ipairs(recipe.recipe) do
	            inv:remove_item("main", item)
	        end
	        inv:add_item("craftresult", recipe.output)
	        local formspec = get_furnace_formspec(player)
			nv_gui.show_formspec_raw(player, formspec, "furnace")
		end
	end
end

nv_gui.register_callback("furnace", furnace_receive_fields_callback)

nv_crafting.anvil_recipes = {}

function nv_crafting.register_anvil_recipe(recipe)
    table.insert(nv_crafting.anvil_recipes, recipe)
end

local function get_anvil_formspec(player)
    local base_formspec = nv_inventory.get_craft_formspec(player, nv_crafting.anvil_recipes)
    return base_formspec
end

local function anvil_receive_fields_callback(player, fields)
    local name = player:get_player_name()
	for field, value in pairs(fields) do
	    if field == "exit" then
			minetest.close_formspec(name, "anvil")
	    elseif string.sub(field, 1, 6) == "recipe" then
	        local index = tonumber(string.sub(field, 7))
	        local recipe = nv_crafting.anvil_recipes[index]
	        local inv = minetest.get_inventory({type = "player", name = name})
	        for _, item in ipairs(recipe.recipe) do
	            inv:remove_item("main", item)
	        end
	        inv:add_item("craftresult", recipe.output)
	        local formspec = get_anvil_formspec(player)
			nv_gui.show_formspec_raw(player, formspec, "anvil")
		end
	end
end

nv_gui.register_callback("anvil", anvil_receive_fields_callback)

local function start_explosion(pos, radius)
    local start_pos = vector.add(pos, {x = -radius, y = -radius, z = -radius})
    local end_pos = vector.add(pos, {x = radius, y = radius, z = radius})
    local vm = core.get_voxel_manip()
    start_pos, end_pos = vm:read_from_map(start_pos, end_pos)
    local data = vm:get_data()
    local param2 = vm:get_param2_data()
    va = VoxelArea(start_pos, end_pos)
    for z = -radius, radius do
        for y = -radius, radius do
            for x = -radius, radius do
                if math.sqrt(x*x + y*y + z*z) <= radius then
                    i = va:index(pos.x + x, pos.y + y, pos.z + z)
                    print(i)
                    local id = data[i]
                    if id ~= core.CONTENT_AIR then
                        local name = core.get_name_from_content_id(id)
                        local node = core.registered_nodes[name]
                        groups = node.groups
                        if not groups.nv_ships then
                            data[i] = core.CONTENT_AIR
                            param2[i] = 0
                        end
                    end
                end
            end
        end
    end
    vm:set_data(data)
    vm:set_param2_data(param2)
    vm:write_to_map(true)
    vm:close()
end

minetest.register_node(
    "nv_crafting:furnace1", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_furnace1.png"
        },
        mesh = "nv_furnace1.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.5 + 0.125, -0.5, -0.5 + 0.125, 0.5 - 0.125, 0.5 - 0.125, 0.5 - 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.5 + 0.125, -0.5, -0.5 + 0.125, 0.5 - 0.125, 0.5 - 0.125, 0.5 - 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1, falling_node = 1},
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            nv_gui.show_formspec_raw(clicker,
                get_furnace_formspec(clicker, 1),
                "furnace"
            )
        end,
        description = "Furnace",
        short_description = "Furnace",
    }
)

minetest.register_node(
    "nv_crafting:furnace2", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_furnace2.png"
        },
        mesh = "nv_furnace2.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.5 + 0.125, -0.5, -0.5 + 0.125, 0.5 - 0.125, 0.5 - 0.0625, 0.5 - 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.5 + 0.125, -0.5, -0.5 + 0.125, 0.5 - 0.125, 0.5 - 0.0625, 0.5 - 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            nv_gui.show_formspec_raw(clicker,
                get_furnace_formspec(clicker, 2),
                "furnace"
            )
        end,
        description = "Blast furnace",
        short_description = "Blast furnace",
    }
)

minetest.register_node(
    "nv_crafting:furnace3", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_furnace3.png"
        },
        mesh = "nv_furnace3.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.5 + 0.125, -0.5, -0.5 + 0.125, 0.5 - 0.125, 0.5, 0.5 - 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.5 + 0.125, -0.5, -0.5 + 0.125, 0.5 - 0.125, 0.5, 0.5 - 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            nv_gui.show_formspec_raw(clicker,
                get_furnace_formspec(clicker, 3),
                "furnace"
            )
        end,
        description = "Electric furnace",
        short_description = "Electric furnace",
    }
)

minetest.register_node(
    "nv_crafting:silicate_sand", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_silicate_sand.png",
            "nv_silicate_sand.png",
            "nv_silicate_sand.png^[transformR180",
            "nv_silicate_sand.png^[transformR90",
            "nv_silicate_sand.png^[transformR270",
            "nv_silicate_sand.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_sediment", gain = 0.07, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {crumbly = 2, falling_node = 1},
        description = "Silicate sand",
        short_description = "Silicate sand",
    }
)

minetest.register_node(
    "nv_crafting:gray_brick", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_gray_brick.png",
            "nv_gray_brick.png",
            "nv_gray_brick.png",
            "nv_gray_brick.png",
            "nv_gray_brick.png",
            "nv_gray_brick.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_stone", gain = 0.4, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        description = "Gray brick",
        short_description = "Gray brick",
    }
)

minetest.register_node(
    "nv_crafting:red_brick", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_red_brick.png",
            "nv_red_brick.png",
            "nv_red_brick.png",
            "nv_red_brick.png",
            "nv_red_brick.png",
            "nv_red_brick.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_stone", gain = 0.4, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        description = "Red brick",
        short_description = "Red brick",
    }
)

minetest.register_node(
    "nv_crafting:black_brick", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_black_brick.png",
            "nv_black_brick.png",
            "nv_black_brick.png",
            "nv_black_brick.png",
            "nv_black_brick.png",
            "nv_black_brick.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_stone", gain = 0.4, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        description = "Black brick",
        short_description = "Black brick",
    }
)

minetest.register_node(
    "nv_crafting:blue_brick", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_blue_brick.png",
            "nv_blue_brick.png",
            "nv_blue_brick.png",
            "nv_blue_brick.png",
            "nv_blue_brick.png",
            "nv_blue_brick.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_stone", gain = 0.4, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        description = "Blue brick",
        short_description = "Blue brick",
    }
)

minetest.register_node(
    "nv_crafting:yellow_brick", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_yellow_brick.png",
            "nv_yellow_brick.png",
            "nv_yellow_brick.png",
            "nv_yellow_brick.png",
            "nv_yellow_brick.png",
            "nv_yellow_brick.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_stone", gain = 0.4, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        description = "Yellow brick",
        short_description = "Yellow brick",
    }
)

minetest.register_node(
    "nv_crafting:concrete", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_concrete.png",
            "nv_concrete.png",
            "nv_concrete.png^[transformR180",
            "nv_concrete.png^[transformR90",
            "nv_concrete.png^[transformR270",
            "nv_concrete.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_stone", gain = 0.4, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        description = "Concrete",
        short_description = "Concrete",
    }
)

minetest.register_node(
    "nv_crafting:polymer", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_polymer.png",
            "nv_polymer.png",
            "nv_polymer.png",
            "nv_polymer.png",
            "nv_polymer.png",
            "nv_polymer.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {choppy = 2},
        description = "Polymer",
        short_description = "Polymer",
    }
)

minetest.register_node(
    "nv_crafting:torch", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_torch.png"
        },
        mesh = "nv_torch.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.0625, -0.5, -0.0625, 0.0625, 0.0, 0.0625}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.0625, -0.5, -0.0625, 0.0625, 0.0, 0.0625}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 11,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = true,
        drop = "",
        groups = {choppy = 3},
        description = "Torch",
        short_description = "Torch",
    }
)

minetest.register_node(
    "nv_crafting:lamp", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_lamp.png"
        },
        mesh = "nv_lamp.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 16,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = false,
        groups = {choppy = 2},
        description = "Lamp",
        short_description = "Lamp",
    }
)

minetest.register_node(
    "nv_crafting:lamp_white", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_lamp_white.png"
        },
        mesh = "nv_lamp.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 16,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = false,
        groups = {choppy = 2},
        description = "White lamp",
        short_description = "White lamp",
    }
)

minetest.register_node(
    "nv_crafting:lamp_yellow", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_lamp_yellow.png"
        },
        mesh = "nv_lamp.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 16,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = false,
        groups = {choppy = 2},
        description = "Yellow lamp",
        short_description = "Yellow lamp",
    }
)

minetest.register_node(
    "nv_crafting:lamp_red", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_lamp_red.png"
        },
        mesh = "nv_lamp.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 16,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = false,
        groups = {choppy = 2},
        description = "Red lamp",
        short_description = "Red lamp",
    }
)

minetest.register_node(
    "nv_crafting:lamp_purple", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_lamp_purple.png"
        },
        mesh = "nv_lamp.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 16,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = false,
        groups = {choppy = 2},
        description = "Purple lamp",
        short_description = "Purple lamp",
    }
)

minetest.register_node(
    "nv_crafting:lamp_blue", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_lamp_blue.png"
        },
        mesh = "nv_lamp.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 16,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = false,
        groups = {choppy = 2},
        description = "Blue lamp",
        short_description = "Blue lamp",
    }
)

minetest.register_node(
    "nv_crafting:lamp_green", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_lamp_green.png"
        },
        mesh = "nv_lamp.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        light_source = 16,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = false,
        groups = {choppy = 2},
        description = "Green lamp",
        short_description = "Green lamp",
    }
)

minetest.register_node(
    "nv_crafting:anvil", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_anvil.png"
        },
        mesh = "nv_anvil.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.25, -0.5, -0.25, 0.25, 0.125, 0.25}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.25, -0.5, -0.25, 0.25, 0.125, 0.25}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {choppy = 1},
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            nv_gui.show_formspec_raw(clicker,
                get_anvil_formspec(clicker),
                "anvil"
            )
        end,
        description = "Anvil",
        short_description = "Anvil",
    }
)

minetest.register_node(
    "nv_crafting:marble", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_marble.png",
            "nv_marble.png",
            "nv_marble.png^[transformR180",
            "nv_marble.png^[transformR90",
            "nv_marble.png^[transformR270",
            "nv_marble.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sounds = {
            footstep = {
                name = "nv_step_stone", gain = 0.4, pitch = 1
            }
        },
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        description = "Marble",
        short_description = "Marble",
    }
)

minetest.register_node(
    "nv_crafting:bed", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_bed.png",
        },
        mesh = "nv_bed.obj",
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 0.0, 1.5}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 0.0, 1.5}
        },
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {choppy = 3},
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            time = core.get_timeofday()
            if time > 0.75 or time < 0.25 then
                core.set_timeofday(0.25)
            end
        end,
        description = "Bed",
        short_description = "Bed",
    }
)

minetest.register_node(
    "nv_crafting:glass", {
        drawtype = "glasslike",
        visual_scale = 1.0,
        tiles = {
            "nv_soda_glass.png",
            "nv_soda_glass.png",
            "nv_soda_glass.png^[transformR180",
            "nv_soda_glass.png^[transformR90",
            "nv_soda_glass.png^[transformR270",
            "nv_soda_glass.png",
        },
        use_texture_alpha = "blend",
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 3},
        description = "Clear glass",
        short_description = "Clear glass",
    }
)

minetest.register_node(
    "nv_crafting:glass_green", {
        drawtype = "glasslike",
        visual_scale = 1.0,
        tiles = {
            "nv_soda_glass.png^[multiply:#4a4",
            "nv_soda_glass.png^[multiply:#4a4",
            "nv_soda_glass.png^[transformR180^[multiply:#4a4",
            "nv_soda_glass.png^[transformR90^[multiply:#4a4",
            "nv_soda_glass.png^[transformR270^[multiply:#4a4",
            "nv_soda_glass.png^[multiply:#4a4",
        },
        use_texture_alpha = "blend",
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 3},
        description = "Green glass",
        short_description = "Green glass",
    }
)

minetest.register_node(
    "nv_crafting:glass_orange", {
        drawtype = "glasslike",
        visual_scale = 1.0,
        tiles = {
            "nv_soda_glass.png^[multiply:#c95",
            "nv_soda_glass.png^[multiply:#c95",
            "nv_soda_glass.png^[transformR180^[multiply:#c95",
            "nv_soda_glass.png^[transformR90^[multiply:#c95",
            "nv_soda_glass.png^[transformR270^[multiply:#c95",
            "nv_soda_glass.png^[multiply:#c95",
        },
        use_texture_alpha = "blend",
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 3},
        description = "Orange glass",
        short_description = "Orange glass",
    }
)

minetest.register_node(
    "nv_crafting:glass_blue", {
        drawtype = "glasslike",
        visual_scale = 1.0,
        tiles = {
            "nv_soda_glass.png^[multiply:#46a",
            "nv_soda_glass.png^[multiply:#46a",
            "nv_soda_glass.png^[transformR180^[multiply:#46a",
            "nv_soda_glass.png^[transformR90^[multiply:#46a",
            "nv_soda_glass.png^[transformR270^[multiply:#46a",
            "nv_soda_glass.png^[multiply:#46a",
        },
        use_texture_alpha = "blend",
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 3},
        description = "Blue glass",
        short_description = "Blue glass",
    }
)

minetest.register_node(
    "nv_crafting:explosive", {
        drawtype = "normal",
        visual_scale = 1.0,
        tiles = {
            "nv_explosive_top.png",
            "nv_explosive_top.png",
            "nv_explosive.png",
            "nv_explosive.png^[transformFX",
            "nv_explosive.png^[transformFX",
            "nv_explosive.png",
        },
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = false,
        walkable = true,
        buildable_to = false,
        groups = {choppy = 3, explody = 2},
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            timer = core.get_node_timer(pos)
            timer:start(5.0)
            core.add_particlespawner({
                amount = 100,
                time = 5.0,
                size = 1,
                texture = "nv_smoke_particle.png",
                pos = pos,
                vel = {
                    min = {x = -0.5, y = 2, z = -0.5},
                    max = {x = 0.5, y = 2, z = 0.5},
                },
            })
        end,
        on_timer = function(pos, elapsed, node, timeout)
            start_explosion(pos, 4)
        end,
        description = "Explosive",
        short_description = "Explosive",
    }
)

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

if nv_planetgen then
    nv_inventory.register_manual_recipe({
        output = "nv_crafting:silicate_sand",
        type = "shapeless",
        recipe = {
            "nv_planetgen:crude_silicate 1",
        },
    })
    
    nv_inventory.register_manual_recipe({
        output = "nv_crafting:furnace1",
        type = "shapeless",
        recipe = {
            "nv_planetgen:crude_silicate 4",
        },
    })
    
    if nv_flora then
        nv_crafting.register_furnace_recipe({
            output = "nv_ores:carbon",
            type = "shapeless",
            recipe = {
                "nv_flora:polymer_planks 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 1,
        })
    end
    
    if nv_ores then
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:basic_fuel 2",
            type = "shapeless",
            recipe = {
                "nv_ores:carbon 1",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:basic_fuel 2",
            type = "shapeless",
            recipe = {
                "nv_ores:sulfur_pieces 3",
            },
        })
    
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:aluminium_oxide",
            type = "shapeless",
            recipe = {
                "nv_ores:aluminium_hydroxide 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 1,
        })
    end
    
    if nv_flora then
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:basic_fuel 2",
            type = "shapeless",
            recipe = {
                "nv_flora:polymer_planks 1",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:torch",
            type = "shapeless",
            recipe = {
                "nv_crafting:basic_fuel 1",
                "nv_flora:polymer_planks 1",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:bed",
            type = "shapeless",
            recipe = {
                "nv_flora:polymer_planks 2",
                "nv_flora:polymer_fiber 4",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:polymer",
            type = "shapeless",
            recipe = {
                "nv_flora:polymer_planks 1",
                "nv_flora:polymer_fiber 1",
            },
        })
    end
    
    if nv_ores then
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:concrete 2",
            type = "shapeless",
            recipe = {
                "nv_crafting:aluminium_oxide 1",
                "nv_ores:calcium_carbonate 1",
            },
        })
    
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:gray_brick 2",
            type = "shapeless",
            recipe = {
                "nv_crafting:aluminium_oxide 1",
                "nv_planetgen:crude_silicate 1",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:red_brick 2",
            type = "shapeless",
            recipe = {
                "nv_crafting:aluminium_oxide 1",
                "nv_ores:iron_oxide 1",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:black_brick 2",
            type = "shapeless",
            recipe = {
                "nv_crafting:aluminium_oxide 1",
                "nv_ores:carbon 1",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:blue_brick 2",
            type = "shapeless",
            recipe = {
                "nv_crafting:aluminium_oxide 1",
                "nv_crafting:cobalt_oxide 1",
            },
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:yellow_brick 2",
            type = "shapeless",
            recipe = {
                "nv_crafting:aluminium_oxide 1",
                "nv_ores:molybdenum_oxide 1",
            },
        })
        
        if nv_flora then
            nv_inventory.register_manual_recipe({
                output = "nv_crafting:furnace2",
                type = "shapeless",
                recipe = {
                    "nv_crafting:concrete 4",
                    "nv_flora:polymer_planks 2",
                },
            })
        end
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:iron",
            type = "shapeless",
            recipe = {
                "nv_ores:iron_oxide 1",
                "nv_ores:carbon 1",
            },
            level = 2,
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:marble",
            type = "shapeless",
            recipe = {
                "nv_ores:calcium_carbonate 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 2,
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:anvil",
            type = "shapeless",
            recipe = {
                "nv_crafting:iron 4",
            },
        })
        
        if nv_flora then
            nv_crafting.register_anvil_recipe({
                output = "nv_crafting:pickaxe",
                type = "shapeless",
                recipe = {
                    "nv_crafting:iron 2",
                    "nv_flora:polymer_planks 1",
                },
            })
        end
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:lamp",
            type = "shapeless",
            recipe = {
                "nv_crafting:iron 1",
                "nv_crafting:basic_fuel 1",
            },
        })
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:lamp_white",
            type = "shapeless",
            recipe = {
                "nv_crafting:lamp 1",
                "nv_crafting:magnesium 1",
            },
        })
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:lamp_yellow",
            type = "shapeless",
            recipe = {
                "nv_crafting:lamp 1",
                "nv_ores:sodium_chloride 1",
            },
        })
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:lamp_red",
            type = "shapeless",
            recipe = {
                "nv_crafting:lamp 1",
                "nv_ores:lithium_oxide 1",
            },
        })
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:lamp_purple",
            type = "shapeless",
            recipe = {
                "nv_crafting:lamp 1",
                "nv_ores:potassium_nitrate 1",
            },
        })
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:lamp_blue",
            type = "shapeless",
            recipe = {
                "nv_crafting:lamp 1",
                "nv_ores:sulfur_pieces 1",
            },
        })
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:lamp_green",
            type = "shapeless",
            recipe = {
                "nv_crafting:lamp 1",
                "nv_ores:molybdenum_oxide 1",
            },
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:glass 2",
            type = "shapeless",
            recipe = {
                "nv_planetgen:crude_silicate 1",
                "nv_ores:sodium_chloride 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 2,
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:glass_green 2",
            type = "shapeless",
            recipe = {
                "nv_planetgen:crude_silicate 1",
                "nv_ores:sodium_chloride 1",
                "nv_ores:iron_oxide 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 2,
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:glass_orange 2",
            type = "shapeless",
            recipe = {
                "nv_planetgen:crude_silicate 1",
                "nv_ores:sodium_chloride 1",
                "nv_ores:sulfur_pieces 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 2,
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:glass_blue 2",
            type = "shapeless",
            recipe = {
                "nv_planetgen:crude_silicate 1",
                "nv_ores:sodium_chloride 1",
                "nv_crafting:cobalt_oxide 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 2,
        })
        
        nv_inventory.register_manual_recipe({
            output = "nv_crafting:bottle 4",
            type = "shapeless",
            recipe = {
                "nv_crafting:glass 1",
            },
        })
        
        if nv_flora then
            nv_inventory.register_manual_recipe({
                output = "nv_crafting:explosive 3",
                type = "shapeless",
                recipe = {
                    "nv_ores:potassium_nitrate 1",
                    "nv_ores:carbon 1",
                    "nv_ores:sulfur_pieces 1",
                    "nv_flora:polymer_fiber 1",
                },
            })
        end
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:acid_bottle 1",
            type = "shapeless",
            recipe = {
                "nv_ores:sulfur_pieces 1",
                "nv_ores:potassium_nitrate 1",
                "nv_crafting:water_bottle 1",
            },
            level = 1,
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:cobalt_oxide 1",
            type = "shapeless",
            recipe = {
                "nv_ores:cobalt_arsenate 1",
                "nv_crafting:acid_bottle 1",
                "nv_crafting:basic_fuel 1",
            },
            level = 2,
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:magnesium",
            type = "shapeless",
            recipe = {
                "nv_ores:magnesium_hydroxide 1",
                "nv_ores:carbon 1",
            },
            level = 2,
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:lithium",
            type = "shapeless",
            recipe = {
                "nv_ores:lithium_oxide 1",
                "nv_crafting:magnesium 1",
            },
            level = 1,
        })
        
        nv_crafting.register_anvil_recipe({
            output = "nv_crafting:battery",
            type = "shapeless",
            recipe = {
                "nv_crafting:lithium 1",
                "nv_crafting:cobalt_oxide 1",
                "nv_crafting:iron 1",
            },
        })
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:molybdenum",
            type = "shapeless",
            recipe = {
                "nv_ores:molybdenum_oxide 1",
                "nv_crafting:hydrocarbon_bottle 1",
            },
            level = 2,
        })
        
        nv_inventory.register_manual_recipe({
                output = "nv_crafting:furnace3",
                type = "shapeless",
                recipe = {
                    "nv_crafting:concrete 4",
                    "nv_ores:magnesium_hydroxide 2",
                    "nv_crafting:molybdenum 2",
                    "nv_crafting:battery 1",
                },
            })
    end
end
