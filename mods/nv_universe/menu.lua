local function get_planets_in_system(system)
	local planets = {}
	table.insert(planets, system)
	system = system + 1
	while system % 5 ~= 0 and system % 11 ~= 0 and system % 12 ~= 0 do
	    table.insert(planets, system)
		system = system + 1
	end
	return planets
end

local function get_ordered_planets_in_system(system)
    local planets = get_planets_in_system(system)
    local metas = {}
    for i, seed in ipairs(planets) do
        table.insert(metas, nv_planetgen.generate_planet_metadata(seed))
    end
    local ordered_planets = {}
    for i, meta in ipairs(metas) do
        if meta.atmosphere == "freezing" then
            table.insert(ordered_planets, planets[i])
        end
    end
    for i, meta in ipairs(metas) do
        if meta.atmosphere == "vacuum" then
            table.insert(ordered_planets, planets[i])
        end
    end
    for i, meta in ipairs(metas) do
        if meta.atmosphere == "cold" then
            table.insert(ordered_planets, planets[i])
        end
    end
    for i, meta in ipairs(metas) do
        if meta.atmosphere == "normal" then
            table.insert(ordered_planets, planets[i])
        end
    end
    for i, meta in ipairs(metas) do
        if meta.atmosphere == "reducing" then
            table.insert(ordered_planets, planets[i])
        end
    end
    for i, meta in ipairs(metas) do
        if meta.atmosphere == "hot" then
            table.insert(ordered_planets, planets[i])
        end
    end
    for i, meta in ipairs(metas) do
        if meta.atmosphere == "scorching" then
            table.insert(ordered_planets, planets[i])
        end
    end
    return ordered_planets
end

local function get_planet_color(planet, use_snow)
    use_snow = (use_snow == nil) and true or use_snow
	local meta = nv_planetgen.generate_planet_metadata(planet)
	nv_planetgen.choose_planet_nodes_and_colors(meta)
	local land
	if meta.life ~= "dead" then
		land = meta.raw_colors.grass
		land.r = (land.r) / 2
		land.g = (land.g) / 2
		land.b = (land.b) / 2
	else
		land = meta.raw_colors.stone
		land.r = land.r / 2
		land.g = land.g / 2
		land.b = land.b / 2
	end
	if use_snow then
        if meta.atmosphere == "freezing" then
            land.r = (land.r + 255 * 3) / 4
            land.g = (land.g + 255 * 3) / 4
            land.b = (land.b + 255 * 3) / 4
        elseif meta.atmosphere == "cold" then
            land.r = (land.r + 255) / 2
            land.g = (land.g + 255) / 2
            land.b = (land.b + 255) / 2
        end
    end
	return nv_universe.sRGB_to_string(land)
end

local function get_star_class(system)
    local star = generate_star(system)
    if star.temperature < 3700 then
        return "M"
    elseif star.temperature < 5200 then
        return "K"
    elseif star.temperature < 6000 then
        return "G"
    elseif star.temperature < 7500 then
        return "F"
    elseif star.temperature < 10000 then
        return "A"
    elseif star.temperature < 30000 then
        return "B"
    else
        return "O"
    end
end

local function create_stars(size, system, selected_system)
	local background_colors = {"#222222", "#444444"}
	local formspec = string.format([[
		box[0,0;%f,%f;#222222]
	]],
		size.width, size.height
	)
	for y=-1,1,1 do
        for x=-1,1,1 do
            local sys = (system + x + y * 256) % 65536
            if sys == system_from_planet(sys) then
                local G = PcgRandom(sys, sys)
                local abs_x = (size.width / 3) * (x + 1.5 + gen_linear(G, -0.4, 0.4))
                local abs_y = (size.height / 3) * (y + 1.5 + gen_linear(G, -0.4, 0.4))
                local star_image = string.format([[
		            image[%f,%f;0.2,0.2;nv_circle.png^[multiply:%s]
		            button[%f,%f;0.4,0.4;_stars%d;]
	            ]],
		            abs_x - 0.1, abs_y - 0.1,
		            generate_star(sys).color,
		            abs_x - 0.2, abs_y - 0.2,
		            sys
	            )
	            if sys == selected_system then
	                star_image = string.format([[
		                image[%f,%f;0.4,0.4;nv_circle.png^[multiply:#55ff88]
	                ]],
		                abs_x - 0.2, abs_y - 0.2
	                ) .. star_image
	            end
	            star_image = string.format([[
	                image[%f,%f;0.6,0.6;nv_circle.png^[multiply:#444444]
                ]],
	                abs_x - 0.3, abs_y - 0.3
                ) .. star_image
	            formspec = formspec .. star_image
            end
        end
    end
	return formspec
end

function nv_universe.create_stars_formspec(system, selected_system, can_travel)
    local planet_count = #get_planets_in_system(selected_system)
    local travel_button = ""
    local system_button = string.format(
        "button[1,5;2,1;system%d;Back to system]",
        system
    )
    if can_travel then
        travel_button = string.format(
            "button[1,6;2,1;stravl%d;TRAVEL HERE]",
            selected_system
        )
    end
    return string.format(
		[[
			formspec_version[2]
			size[14,8]
			textarea[0,1;4,4;;%s;]
			%s
			%s
			container[4,0.5]
			    %s
			container_end[]
		]],
		string.format(
		    [[
		        Planetary system %X
		        Class %s star
		        %d planet%s
		        ___________________
		        
		        Select any system
		        to see information
		        about it.
		    ]],
		    selected_system,
		    get_star_class(selected_system),
		    planet_count, (planet_count > 1) and "s" or ""
		),
		system_button,
		travel_button,
		create_stars({
			width = 7, height = 7
		}, system, selected_system
		)
	)
end

local function create_system(size, system, current_planet)
	local background_colors = {"#222222", "#444444"}
	local formspec = string.format([[
		image[0,0;%f,%f;nv_circle.png^[multiply:%s]
	]],
		size.width, size.height,
		background_colors[1]
	)
	local planets = get_ordered_planets_in_system(system)
	local orbit_size = size.width / (#planets + 1) / 2
	local planet_size = 0.2
	local planet_formspec = ""
	for i, planet in ipairs(planets) do
		local orbit_image = string.format([[
			image[%f,%f;%f,%f;nv_circle.png^[multiply:%s]
		]],
			i * orbit_size, i * orbit_size,
			size.width - 2 * i * orbit_size, size.height - 2 * i * orbit_size,
			background_colors[1 + i % 2]
		)
		local planet_color = get_planet_color(planet)
		local planet_image = string.format([[
			image[%f,%f;%f,%f;nv_circle.png^[multiply:%s]
			button[%f,%f;%f,%f;planet%d;]
		]],
			 i * orbit_size - planet_size / 2, size.height / 2 - planet_size / 2,
			planet_size, planet_size,
			planet_color,
			i * orbit_size - planet_size, size.height / 2 - planet_size,
			planet_size * 2, planet_size * 2,
			planet
		)
		if planet == current_planet then
		    planet_image = string.format([[
			    image[%f,%f;%f,%f;nv_circle.png^[multiply:#55ff88]
		    ]],
			    i * orbit_size - planet_size, size.height / 2 - planet_size,
			    planet_size * 2, planet_size * 2
		    ) .. planet_image
		end
		formspec = formspec .. orbit_image
		planet_formspec = planet_formspec .. planet_image
	end
	formspec = formspec .. planet_formspec
	local star_image = string.format([[
		image[%f,%f;%f,%f;nv_circle.png^[multiply:%s]
	]],
		size.width / 2 - planet_size, size.height / 2 - planet_size,
		planet_size * 2, planet_size * 2,
		generate_star(system).color
	)
	formspec = formspec .. star_image
	return formspec
end

function nv_universe.create_system_formspec(system, current_planet)
    local planet_count = #get_planets_in_system(system)
    local stars_button = string.format(
        "button[1,5;2,1;_stars%d;View neighbors]",
        system
    )
    return string.format(
		[[
			formspec_version[2]
			size[14,8]
			textarea[0,1;4,4;;%s;]
			%s
			container[4,0.5]
			    %s
			container_end[]
		]],
		string.format(
		    [[
		        Planetary system %X
		        Class %s star
		        %d planet%s
		        ___________________
		        
		        Select any planet
		        to see information
		        about it.
		    ]],
		    system,
		    get_star_class(system),
		    planet_count, (planet_count > 1) and "s" or ""
		),
		stars_button,
		create_system({
			width = 7, height = 7
		}, system, current_planet
		)
	)
end

local suffixes = {"b", "c", "d", "e", "f"}
local function get_planet_name(planet)
    local system = system_from_planet(planet)
    local index = planet - system + 1
    local suffix = suffixes[index]
    return string.format("%X %s", system, suffix)
end

local function random_overlay(G, file)
    return string.format(
        "[combine:32x32:%d,%d=%s",
        G:next(-31, 0), G:next(-31, 0),
        file
    )
end

function create_planet_image(planet)
    local meta = nv_planetgen.generate_planet_metadata(planet)
    local G = PcgRandom(planet, planet)
    nv_planetgen.choose_planet_nodes_and_colors(meta)
    local planet_color
    if meta.atmosphere == "freezing" then
        planet_color = get_planet_color(planet, true)
    else
        planet_color = get_planet_color(planet, false)
    end
    local craters
    if meta.atmosphere == "vacuum" then
        craters = string.format(
            "(%s^[resize:128x128)^[mask:nv_circle.png",
            random_overlay(G, "nv_craters.png")
        )
    else
        craters = "[combine:128x128"
    end
    local snows
    if meta.atmosphere == "cold" then
        snows = string.format(
            "(%s^[resize:128x128)^[mask:nv_circle.png",
            random_overlay(G, "nv_snows.png")
        )
    else
        snows = "[combine:128x128"
    end
    local deserts
    if meta.atmosphere == "hot" then
        deserts = string.format(
            "((%s^[colorize:%s:48)^[resize:128x128)^[mask:nv_circle.png",
            random_overlay(G, "nv_deserts.png"),
            nv_universe.sRGB_to_string(meta.raw_colors.stone)
        )
    else
        deserts = "[combine:128x128"
    end
    local mountains = string.format(
        "(%s^[resize:128x128)^[mask:nv_circle.png",
        random_overlay(G, "nv_mountains.png")
    )
    local oceans
    local ocean_color = meta.raw_colors.liquid
    ocean_color.r = ocean_color.r / 2
    ocean_color.g = ocean_color.g / 2
    ocean_color.b = ocean_color.b / 2
    if meta.has_oceans then
        oceans = string.format(
            "((%s^[multiply:%s)^[resize:128x128)^[mask:nv_circle.png",
            random_overlay(G, "nv_oceans.png"),
            nv_universe.sRGB_to_string(ocean_color)
        )
    else
        oceans = "[combine:128x128"
    end
	return string.format(
	    "(((((nv_circle.png^[multiply:%s)^(%s))^(%s))^(%s))^(%s))^(%s)",
	    planet_color,
	    snows,
	    deserts,
	    mountains,
	    craters,
	    oceans
	)
end

function nv_universe.create_planet_formspec(planet, can_travel)
    local meta = nv_planetgen.generate_planet_metadata(planet)
    local atmosphere_description
    if meta.atmosphere == "freezing" then
        atmosphere_description = "Extremely cold"
    elseif meta.atmosphere == "vacuum" then
        atmosphere_description = "No atmosphere"
    elseif meta.atmosphere == "cold" then
        atmosphere_description = "Cold climate"
    elseif meta.atmosphere == "normal" then
        atmosphere_description = "Temperate climate"
    elseif meta.atmosphere == "reducing" then
        atmosphere_description = "Reducing atmosphere"
    elseif meta.atmosphere == "hot" then
        atmosphere_description = "Hot climate"
    elseif meta.atmosphere == "scorching" then
        atmosphere_description = "Extremely hot"
    end
    local life_description
    if meta.life == "dead" then
        life_description = "No life forms"
    elseif meta.life == "normal" then
        life_description = "Living organisms"
    elseif meta.life == "lush" then
        life_description = "Abundant life"
    end
    local ocean_description
    if not meta.has_oceans then
        ocean_description = "No oceans"
    elseif meta.atmosphere == "freezing" then
        ocean_description = "Liquid hydrocarbons"
    elseif meta.atmosphere == "scorching" then
        ocean_description = "Lava oceans"
    else
        ocean_description = "Water oceans"
    end
    local system_button = string.format(
        "button[1,5;2,1;system%d;View system]",
        system_from_planet(planet)
    )
    local travel_button = ""
    if can_travel then
        travel_button = string.format(
            "button[1,6;2,1;travel%d;TRAVEL HERE]",
            planet
        )
    end
    local planet_size = 7 * nv_universe.get_planet_gravity(planet)^(1/3)
    return string.format(
		[[
			formspec_version[2]
			size[14,8]
			textarea[0,1;4,4;;%s;]
			%s
			%s
			image[%d,%d;%d,%d;%s]
		]],
		string.format(
		    [[
		        Planet %s
		        %s
		        %s
		        %s
		    ]],
		    get_planet_name(planet),
		    atmosphere_description,
		    life_description,
		    ocean_description
		),
		system_button,
		travel_button,
		8 - planet_size / 2, 4.5 - planet_size / 2,
		planet_size, planet_size,
		create_planet_image(planet)
	)
end

local function player_receive_fields_callback(player, fields)
	for field, value in pairs(fields) do
	    if string.sub(field, 1, 6) == "_stars" then
			local planet = nv_universe.players[player:get_player_name()].planet
			local system = system_from_planet(planet)
			local selected_system = tonumber(string.sub(field, 7, -1))
			local can_travel = nv_universe.check_travel_capability(player, selected_system) and system ~= selected_system
			local formspec = nv_universe.create_stars_formspec(system, selected_system, can_travel)
			nv_gui.show_formspec(player, formspec)
		end
		if string.sub(field, 1, 6) == "system" then
		    local planet = nv_universe.players[player:get_player_name()].planet
			local selected_system = tonumber(string.sub(field, 7, -1))
			local formspec = nv_universe.create_system_formspec(selected_system, planet)
			nv_gui.show_formspec(player, formspec)
		end
		if string.sub(field, 1, 6) == "planet" then
			local selected_planet = tonumber(string.sub(field, 7, -1))
			local can_travel = nv_universe.check_travel_capability(player, selected_planet)
			local formspec = nv_universe.create_planet_formspec(selected_planet, can_travel)
			nv_gui.show_formspec(player, formspec)
		end
		if string.sub(field, 1, 6) == "travel" then
		    local selected_planet = tonumber(string.sub(field, 7, -1))
		    nv_universe.send_to_new_space(player, selected_planet)
		end
		if string.sub(field, 1, 6) == "stravl" then
		    local selected_system = tonumber(string.sub(field, 7, -1))
		    nv_universe.send_to_new_space(player, selected_system)
		    local formspec = nv_universe.create_stars_formspec(selected_system, selected_system, false)
			nv_gui.show_formspec(player, formspec)
		end
	end
end

nv_gui.register_tab("universe", "Navigation", player_receive_fields_callback)
