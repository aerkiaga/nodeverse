local function get_planets_in_system(system)
	local planets = {}
	table.insert(planets, system)
	system = system + 1
	while system % 5 ~= 0 and system % 11 ~= 0 and system % 12 ~= 0 do
		system = system + 1
		table.insert(planets, system)
	end
	return planets
end

local function get_planet_color(planet)
	local meta = nv_planetgen.generate_planet_metadata(planet)
	nv_planetgen.choose_planet_nodes_and_colors(meta)
	local land
	if meta.life ~= "dead" then
		land = meta.raw_colors.grass
	else
		land = meta.raw_colors.stone
	end
	return string.format("#%02x%02x%02x", land.r, land.g, land.b)
end

local function create_system(pos, size, system)
	local background_colors = {"#222222", "#444444"}
	local formspec = string.format([[
		image[%f,%f;%f,%f;nv_circle.png^[multiply:%s]
	]],
		pos.x, pos.y,
		size.width, size.height,
		background_colors[1]
	)
	local planets = get_planets_in_system(system)
	local orbit_size = size.width / (#planets + 1) / 2
	local planet_size = 0.2
	local planet_formspec = ""
	for i, planet in ipairs(planets) do
		local orbit_image = string.format([[
			image[%f,%f;%f,%f;nv_circle.png^[multiply:%s]
		]],
			pos.x + i * orbit_size, pos.y + i * orbit_size,
			size.width - 2 * i * orbit_size, size.height - 2 * i * orbit_size,
			background_colors[1 + i % 2]
		)
		local planet_color = get_planet_color(planet)
		local planet_image = string.format([[
			image[%f,%f;%f,%f;nv_circle.png^[multiply:%s]
			button[%f,%f;%f,%f;%s;]
		]],
			pos.x + i * orbit_size - planet_size / 2, pos.y + size.height / 2 - planet_size / 2,
			planet_size, planet_size,
			planet_color,
			pos.x + i * orbit_size - planet_size / 2, pos.y + size.height / 2 - planet_size / 2,
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
		pos.x + size.width / 2 - planet_size, pos.y + size.height / 2 - planet_size,
		planet_size * 2, planet_size * 2,
		generate_star(system).color
	)
	formspec = formspec .. star_image
	return formspec
end

function nv_universe.configure_menu(player, planet)
	local system = system_from_planet(planet)
	local star = generate_star(system)
	local formspec = string.format(
		[[
			formspec_version[2]
			size[10,8]
			%s
		]],
		create_system({
			x = 0.5, y = 0.5
		}, {
			width = 7, height = 7
		}, system
		)
	)
	player:set_inventory_formspec(formspec)
end

local function player_receive_fields_callback(player, formname, fields)
	if formname == "" then
		for field, value in pairs(fields) do
			if string.sub(field, 1, 6) == "planet" then
				local new_planet = tonumber(string.sub(field, 7, -1))
				nv_universe.send_to_new_space(player, new_planet)
			end
		end
	end
end

minetest.register_on_player_receive_fields(player_receive_fields_callback)
