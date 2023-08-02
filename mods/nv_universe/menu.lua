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
	else
		land = meta.raw_colors.stone
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

local function create_system(size, system)
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
			button[%f,%f;%f,%f;%s;]
		]],
			 i * orbit_size - planet_size / 2, size.height / 2 - planet_size / 2,
			planet_size, planet_size,
			planet_color,
			i * orbit_size - planet_size / 2, size.height / 2 - planet_size / 2,
			planet_size, planet_size,
			string.format("planet%d", planet)
		)
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

function nv_universe.create_system_formspec(system)
    local planet_count = #get_planets_in_system(system)
    return string.format(
		[[
			formspec_version[2]
			size[14,8]
			textarea[0,1;4,4;;%s;]
			container[4,0]
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
		create_system({
			width = 7, height = 7
		}, system
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

local function create_planet_image(planet)
    local meta = nv_planetgen.generate_planet_metadata(planet)
    local G = PcgRandom(planet, planet)
    nv_planetgen.choose_planet_nodes_and_colors(meta)
    local oceans
    if meta.has_oceans then
        oceans = string.format(
            "((%s^[multiply:%s)^[resize:128x128)^[mask:nv_circle.png",
            random_overlay(G, "nv_oceans.png"),
            nv_universe.sRGB_to_string(meta.raw_colors.liquid)
        )
    else
        oceans = "[combine:128x128"
    end
	return string.format(
	    "(nv_circle.png^[multiply:%s)^(%s)",
	    get_planet_color(planet),
	    oceans
	)
end

function nv_universe.create_planet_formspec(planet)
    local meta = nv_planetgen.generate_planet_metadata(planet)
    return string.format(
		[[
			formspec_version[2]
			size[14,8]
			textarea[0,1;4,4;;%s;]
			container[4,0]
			    image[0,0;7,7;%s]
			container_end[]
		]],
		string.format(
		    [[
		        Planet %s
		    ]],
		    get_planet_name(planet)
		),
		create_planet_image(planet)
	)
end

local function player_receive_fields_callback(player, formname, fields)
	if formname == "" then
		for field, value in pairs(fields) do
			if string.sub(field, 1, 6) == "planet" then
				local selected_planet = tonumber(string.sub(field, 7, -1))
				local formspec = nv_universe.create_planet_formspec(selected_planet)
				minetest.show_formspec(player:get_player_name(), "", formspec)
				--nv_universe.send_to_new_space(player, new_planet)
			end
		end
	end
end

minetest.register_on_player_receive_fields(player_receive_fields_callback)
