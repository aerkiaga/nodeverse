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
            
            nv_crafting.register_anvil_recipe({
                output = "nv_crafting:silicon_pickaxe",
                type = "shapeless",
                recipe = {
                    "nv_crafting:silicon 2",
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
        
        nv_crafting.register_furnace_recipe({
            output = "nv_crafting:silicon",
            type = "shapeless",
            recipe = {
                "nv_planetgen:crude_silicate 2",
                "nv_ores:carbon 1",
            },
            level = 3,
        })
    end
end
