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

dofile(minetest.get_modpath("nv_crafting") .. "/nodetypes.lua")
dofile(minetest.get_modpath("nv_crafting") .. "/itemtypes.lua")
dofile(minetest.get_modpath("nv_crafting") .. "/recipes.lua")
