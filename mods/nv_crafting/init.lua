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
    local base_formspec = nv_inventory.get_craft_formspec(player, nv_crafting.furnace_recipes)
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
			nv_gui.show_formspec_raw(player, formspec)
		end
	end
end

nv_gui.register_callback("furnace", furnace_receive_fields_callback)

minetest.register_node(
    "nv_crafting:furnace1", {
        drawtype = "mesh",
        visual_scale = 1.0,
        tiles = {
            "nv_furnace1.png"
        },
        mesh = "nv_furnace1.obj",
        paramtype = "light",
        paramtype2 = "facedir",
        place_param2 = 0,
        sunlight_propagates = true,
        walkable = true,
        buildable_to = false,
        groups = {cracky = 1},
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            nv_gui.show_formspec_raw(clicker,
                get_furnace_formspec(clicker, 1),
                "furnace"
            )
        end,
        description = "Furnace Mk 1",
        short_description = "Furnace Mk 1",
    }, 4
)

if nv_planetgen then
    nv_inventory.register_manual_recipe({
        output = "nv_crafting:furnace1",
        type = "shapeless",
        recipe = {
            "nv_planetgen:crude_silicate 4",
        },
    })
    
    if nv_ores then
        nv_crafting.register_furnace_recipe({
            output = "nv_ores:aluminium_oxide",
            type = "shapeless",
            recipe = {
                "nv_ores:aluminium_hydroxide 1",
            },
            level = 1,
        })
    end
end
