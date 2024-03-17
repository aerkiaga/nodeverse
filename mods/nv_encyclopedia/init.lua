nv_encyclopedia = {}

--[[
Contains a dictionary of players, where each value is a list of planets
in the order they were visited by that player. Format is:
    seed        seed of the planet
    flora       table, with each index' value set to 'true'
]]
nv_encyclopedia.players = {}

dofile(minetest.get_modpath("nv_encyclopedia") .. "/storage.lua")

local function get_planet_formspec(player, planet)
    local name = player:get_player_name()
    local r = ""
    local flora = nv_flora.get_planet_flora(planet)
    local meta = nv_planetgen.generate_planet_metadata(planet)
    local x = 1
    local y = 1
    r = r .. string.format(
        [[
            image[%d,%d;3,3;%s]
        ]],
        x + 6,
        y,
        nv_universe.create_planet_image(planet)
    )
    r = r .. string.format("textarea[%d,%d;5,4;;%s;]", x, y,
        string.format(
            [[
Planet %s
________________________

Atmosphere: %s
Life: %s
Oceans: %s
Landscape: %s
Exposed stone: %s
Caves: %s
            ]],
            nv_universe.get_planet_name(planet),
            
            meta.atmosphere == "freezing" and "extremely cold" or (
            meta.atmosphere == "vacuum" and "none" or (
            meta.atmosphere == "cold" and "cold" or (
            meta.atmosphere == "normal" and "temperate" or (
            meta.atmosphere == "reducing" and "reducing" or (
            meta.atmosphere == "hot" and "hot" or (
            meta.atmosphere == "scorching" and "extremely hot")))))),
            
            meta.life == "dead" and "none" or (
            meta.life == "normal" and "some" or (
            meta.life == "lush" and "lush")),
            
            meta.has_oceans and "yes" or "no",
            
            meta.terrestriality > 0 and "high" or "low",
            
            meta.rockiness < 4 and "none" or (
            meta.rockiness < 5 and "scarce" or "common"),
            
            meta.caveness < 0.05 and "scarce" or (
            meta.caveness < 0.3 and "common" or "very common")
        )
    ) y = y + 4
    local n_total, n_found = #flora, 0
    local dug_plants = {}
    for n, player_planet in ipairs(nv_encyclopedia.players[name]) do
        if player_planet.seed == planet then
            dug_plants = player_planet.flora
        end
    end
    for k, t in pairs(dug_plants) do
        n_found = n_found + 1
    end
    r = r .. string.format(
        [[
            textarea[%d,%d;5,2;;Collected flora: %s;]
        ]],
        x, y,
        meta.life == "dead" and "N/A" or string.format(
            "%d / %d", n_found, n_total
        )
    )
    y = y + 1
    for n, plant in ipairs(flora) do
        r = r .. string.format(
            [[
                image[%d,%d;1.8,1.8;%s]
            ]],
            x,
            y,
            string.format(
                dug_plants[plant.custom.index] and "([fill:128x128:#444444)^((%s)^[resize:128x128)" or "((%s)^[resize:12x12)^[hsl:0:-100:-40",
                plant.thumbnail(planet, plant.custom)
            )
        )
        x = x + 2
        if x > 10 then
            x = 1
            y = y + 2
        end
    end
    return string.format(
        [[
	        scrollbaroptions[min=0;max=%d;smallstep=1;largestep=8]
	        scrollbar[13.7,0;0.3,8;vertical;encycloscroll;0]
            scroll_container[0,0;14,8;encycloscroll;vertical;1]
        ]],
        y - 4
    ) .. r .. [[
        scroll_container_end[]
    ]]
end

local function get_base_formspec(player)
    local name = player:get_player_name()
    local r = ""
    local systems = {}
    for n, player_planet in ipairs(nv_encyclopedia.players[name]) do
        local system = nv_universe.system_from_planet(player_planet.seed)
        local found = nil
        for n, sys in ipairs(systems) do
            if sys.seed == system then
                found = sys
                break
            end
        end
        if not found then
            found = {}
            found.seed = system
            found.planets = {}
            table.insert(systems, found)
        end
        found.planets[player_planet.seed] = true
    end
    local y = 1
    for n=#systems,1,-1 do
        local pl = ""
        local x = 1
        local n_discovered = 0
        local all_planets = nv_universe.get_ordered_planets_in_system(systems[n].seed)
        for m, pseed in ipairs(all_planets) do
            local discovered = systems[n].planets[pseed]
            if discovered then
                n_discovered = n_discovered + 1
            end
            pl = pl .. (
                discovered and string.format(
                    [[
                        image_button[%d,%d;1.8,1.8;%s;planet%d;]
                    ]],
                    x,
                    y + 1,
                    nv_universe.create_planet_image(pseed),
                    pseed
                ) or string.format(
                    [[
                        image[%d,%d;1.8,1.8;%s]
                    ]],
                    x,
                    y + 1,
                    "nv_circle.png^[colorize:#444444:255"
                )
            )
            x = x + 2
        end
        r = r .. string.format(
            [[
                textarea[0,%d;8,1;;%s;]
                %s
            ]],
            y,
            string.format(
                [[
                    Planetary system %X  -  %d / %d planets visited
                ]],
                systems[n].seed,
                n_discovered,
                #all_planets
            ),
            pl
        )
        y = y + 4
    end
    return string.format(
        [[
	        scrollbaroptions[min=0;max=%d;smallstep=1;largestep=8]
	        scrollbar[13.7,0;0.3,8;vertical;encycloscroll;0]
            scroll_container[0,0;14,8;encycloscroll;vertical;1]
        ]],
        y - 4
    ) .. r .. [[
        scroll_container_end[]
    ]]
end

local function visit_planet_callback(player, planet)
    local name = player:get_player_name()
    nv_encyclopedia.players[name] = nv_encyclopedia.players[name] or {}
    for n, player_planet in ipairs(nv_encyclopedia.players[name]) do
        if player_planet.seed == planet then
            return
        end
    end
    table.insert(nv_encyclopedia.players[name], {
        seed = planet,
        flora = {},
    })
    nv_gui.set_inventory_formspec(player, "encyclopedia", get_base_formspec(player))
    nv_encyclopedia.store_player_state(player)
end

nv_universe.register_on_visit_planet(visit_planet_callback)

local function dig_plant_callback(player, planet, index)
    local name = player:get_player_name()
    nv_encyclopedia.players[name] = nv_encyclopedia.players[name] or {}
    local found = nil
    local m = nil
    for n, player_planet in ipairs(nv_encyclopedia.players[name]) do
        if player_planet.seed == planet then
            found = player_planet
        end
        m = n
    end
    if not found then
        found = {
            seed = planet,
            flora = {},
        }
        table.insert(nv_encyclopedia.players[name], found)
    end
    found.flora[index] = true
    nv_encyclopedia.store_player_state(player)
end

nv_flora.register_on_dig_plant(dig_plant_callback)

local function joinplayer_callback(player, last_login)
    if last_login ~= nil then
        nv_encyclopedia.load_player_state(player)
    end
	nv_gui.set_inventory_formspec(player, "encyclopedia", get_base_formspec(player))
end

minetest.register_on_joinplayer(joinplayer_callback)

local function leaveplayer_callback(player, timed_out)
    nv_encyclopedia.store_player_state(player)
end

minetest.register_on_leaveplayer(leaveplayer_callback)

local function player_receive_fields_callback(player, fields)
	for field, value in pairs(fields) do
	    if string.sub(field, 1, 6) == "planet" then
			local selected_planet = tonumber(string.sub(field, 7, -1))
			local formspec = get_planet_formspec(player, selected_planet)
			nv_gui.show_formspec(player, formspec)
		end
	end
end

nv_gui.register_tab("encyclopedia", "Discoveries", player_receive_fields_callback)
