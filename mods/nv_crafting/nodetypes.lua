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
                nv_crafting.get_furnace_formspec(clicker, 1),
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
                nv_crafting.get_furnace_formspec(clicker, 2),
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
                nv_crafting.get_furnace_formspec(clicker, 3),
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
                nv_crafting.get_anvil_formspec(clicker),
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
            nv_crafting.start_explosion(pos, 4)
        end,
        description = "Explosive",
        short_description = "Explosive",
    }
)
