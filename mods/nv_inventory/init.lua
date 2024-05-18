nv_inventory = {}

nv_inventory.manual_recipes = {}

function nv_inventory.register_manual_recipe(recipe)
    table.insert(nv_inventory.manual_recipes, recipe)
    minetest.register_craft(recipe)
end

function nv_inventory.get_craft_formspec(player, recipes)
    local name = player:get_player_name()
    local r = ""
    local y = 1
    local inv = minetest.get_inventory({type = "player", name = name})
    for m, recipe in ipairs(recipes) do
        local doable = true
        for n, item in ipairs(recipe.recipe) do
            if not inv:contains_item("main", item) then
                doable = false
                break
            end
        end
        if doable then
            r = r .. string.format([[
                button[1,%g;9,1;recipe%d;]
            ]],
                y,
                m
            )
        end
        for n, item in ipairs(recipe.recipe) do
            local index = string.find(item, " ")
            local item_count = 1
            local item_name = ""
            if index then
                item_count = tonumber(string.sub(item, index + 1))
                item_name = string.sub(item, 1, index - 1)
            end
            r = r .. string.format([[
                item_image[1,%g;1,1;%s]
            ]],
                y,
                item_name
            )
            local color = "#ffffff"
            if not inv:contains_item("main", item) then
                color = "#ff0000"
            end
            r = r .. string.format([[
                style_type[label;textcolor=%s]
                label[1.8,%g;%s]
            ]],
                color,
                y + 0.8,
                tostring(item_count)
            )
        end
        r = r .. string.format([[
            image[7.5,%g;1,1;nv_arrow.png;]
        ]],
            y
        )
        local item = recipe.output
        local index = string.find(item, " ")
        local item_count = 1
        if index then
            item_count = tonumber(string.sub(item, index + 1))
            item = string.sub(item, 1, index - 1)
        end
        r = r .. string.format([[
            item_image[9,%g;1,1;%s]
        ]],
            y,
            item
        )
        if item_count > 1 then
            r = r .. string.format([[
                label[9.8,%g;%s]
            ]],
                y + 0.8,
                tostring(item_count)
            )
        end
        y = y + 1.5
    end
    return string.format(
        [[
	        scrollbaroptions[min=0;max=%d;smallstep=1;largestep=8]
	        scrollbar[13.7,0;0.3,6;vertical;craftscroll;0]
            scroll_container[0,0;14,8;craftscroll;vertical;1]
        ]],
        y - 4
    ) .. r .. [[
        scroll_container_end[]
        button[1,6.5;2,1;exit;Exit]
    ]]
end

local function get_manual_craft_formspec(player)
    return nv_inventory.get_craft_formspec(player, nv_inventory.manual_recipes)
end

local function get_base_formspec(player)
    local name = player:get_player_name()
    local r = ""
    r = [[
        list[current_player;main;1,1;8,4;]
        button[1,6.5;2,1;craft;Craft]
        list[current_player;craftresult;3.5,6.5;1,1;]
    ]]
    return r
end

local function visit_planet_callback(player, planet)
end

nv_universe.register_on_visit_planet(visit_planet_callback)

local function joinplayer_callback(player, last_login)
	nv_gui.set_inventory_formspec(player, "inventory", get_base_formspec(player))
end

minetest.register_on_joinplayer(joinplayer_callback)

local function player_receive_fields_callback(player, fields)
    local name = player:get_player_name()
	for field, value in pairs(fields) do
	    if field == "craft" then
			local formspec = get_manual_craft_formspec(player)
			nv_gui.show_formspec(player, formspec)
		elseif field == "exit" then
			local formspec = get_base_formspec(player)
			nv_gui.show_formspec(player, formspec)
	    elseif string.sub(field, 1, 6) == "recipe" then
	        local index = tonumber(string.sub(field, 7))
	        local recipe = nv_inventory.manual_recipes[index]
	        local inv = minetest.get_inventory({type = "player", name = name})
	        for _, item in ipairs(recipe.recipe) do
	            inv:remove_item("main", item)
	        end
	        inv:add_item("craftresult", recipe.output)
	        local formspec = get_manual_craft_formspec(player)
			nv_gui.show_formspec(player, formspec)
		end
	end
end

nv_gui.register_tab("inventory", "Inventory", player_receive_fields_callback)
