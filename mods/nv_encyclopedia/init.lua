nv_encyclopedia = {}

--[[
Contains a dictionary of players, where each value is a list of planets
in the order they were visited by that player. Format is:
    seed        seed of the planet
]]
nv_encyclopedia.players = {}

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
        for m, pseed in ipairs(nv_universe.get_ordered_planets_in_system(systems[n].seed)) do
            pl = pl .. string.format(
                [[
                    image[%d,%d;1.8,1.8;%s]
                ]],
                x,
                y + 1,
                systems[n].planets[pseed] and nv_universe.create_planet_image(pseed) or "nv_circle.png^[colorize:#444444:255"
            )
            x = x + 2
        end
        r = r .. string.format(
            [[
                textarea[0,%d;4,1;;%s;]
                %s
            ]],
            y,
            string.format(
                [[
                    System %X
                ]],
                systems[n].seed
            ),
            pl
        )
        y = y + 2
    end
    return [[
        scroll_container[0,0;14,8;encycloscroll;vertical;0.1]
    ]] .. r .. [[
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
    })
end

nv_universe.register_on_visit_planet(visit_planet_callback)

local function joinplayer_callback(player, last_login)
    local formspec = string.format(
        [[
		    formspec_version[2]
		    size[14,8]
		    %s
	    ]],
	    get_base_formspec(player)
	)
	nv_gui.set_inventory_formspec(player, "encyclopedia", formspec)
end

minetest.register_on_joinplayer(joinplayer_callback)

local function player_receive_fields_callback(player, fields)
	for field, value in pairs(fields) do
	end
end

nv_gui.register_tab("encyclopedia", "Discoveries", player_receive_fields_callback)
