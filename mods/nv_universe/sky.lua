function nv_universe.set_space_sky(player, seed)
    player:set_sky {
		base_color = 0xFF080008,
		type = "skybox",
		textures = {
			"nv_skybox_top.png",
			"nv_skybox_bottom.png",
			"nv_skybox_right.png",
			"nv_skybox_left.png",
			"nv_skybox_back.png",
			"nv_skybox_front.png"
		},
		clouds = false,
	}
	player:set_sun {
		visible = false,
		sunrise_visible = false
	}
	player:set_moon {
		visible = false
	}
	player:set_stars {
		visible = false
	}
	nv_universe.configure_menu(player, seed)
end

function system_from_planet(planet)
	while planet % 5 ~= 0 and planet % 11 ~= 0 and planet % 12 ~= 0 do
		planet = planet - 1
	end
	return planet
end

function generate_star(seed)
	local star = {}
	local G = PcgRandom(seed, seed)
	star.temperature = 10^gen_linear(G, 3, 4.5)
	local star_Y
	if star.temperature < 2000 then
		star_Y = 0.3 + 0.7*(star.temperature - 1000)/1000
	else
		star_Y = 1
	end
	local star_sRGB = nv_universe.YT_to_sRGB {
		Y = star_Y,
		T = star.temperature
	}
	star.color = string.format("#%02x%02x%02x", star_sRGB.R, star_sRGB.G, star_sRGB.B)
	return star
end

local function generate_sun(seed)
	local sun = {}
	local star = generate_star(system_from_planet(seed))
	sun.color = star.color
	sun.texture = string.format("nv_sun.png^[multiply:%s", sun.color)
	return sun
end

local function generate_sky_color(seed)
	local sky_color = {}
	local G = PcgRandom(seed, seed)
	local meta = nv_planetgen.generate_planet_metadata(seed)
	local base_Y
	local base_T
	if meta.atmosphere == "vacuum" then
		base_Y = gen_linear(G, 0, 0.1)
		base_T = gen_linear(G, 1000, 20000)
	elseif meta.atmosphere == "freezing" or meta.atmosphere == "cold" then
		base_Y = gen_linear(G, 0.2, 0.5)
		base_T = gen_linear(G, 10000, 20000)
	elseif meta.atmosphere == "normal" then
		base_Y = gen_linear(G, 0.4, 0.9)
		base_T = gen_linear(G, 1000, 20000)
	elseif meta.atmosphere == "hot" or meta.atmosphere == "reducing" then
		base_Y = gen_linear(G, 0.7, 1.0)
		base_T = gen_linear(G, 200, 10000)
	elseif meta.atmosphere == "scorching" then
		base_Y = gen_linear(G, 0.1, 0.2)
		base_T = gen_linear(G, 200, 5000)
	end
	local day_sky_sRGB = nv_universe.YT_to_sRGB {
		Y = base_Y, T = base_T
	}
	local day_horizon_sRGB = nv_universe.YT_to_sRGB {
		Y = base_Y * gen_linear(G, 0.5, 0.9),
		T = base_T * gen_linear(G, 0.5, 1.5)
	}
	sky_color.day_sky = string.format("#%02x%02x%02x", day_sky_sRGB.R, day_sky_sRGB.G, day_sky_sRGB.B)
	sky_color.day_horizon = string.format("#%02x%02x%02x", day_horizon_sRGB.R, day_horizon_sRGB.G, day_horizon_sRGB.B)
	local sunrise_sRGB = nv_universe.YT_to_sRGB {
		Y = 0.9,
		T = 10^(3.8 + 2 * (3.8 - math.log10(base_T)))
	}
	sky_color.sunrise = string.format("#%02x%02x%02x", sunrise_sRGB.R, sunrise_sRGB.G, sunrise_sRGB.B)
	local dawn_sky_sRGB = nv_universe.YT_to_sRGB {
		Y = base_Y / 2,
		T = base_T
	}
	sky_color.dawn_sky = string.format("#%02x%02x%02x", dawn_sky_sRGB.R, dawn_sky_sRGB.G, dawn_sky_sRGB.B)
	local dawn_horizon_sRGB = nv_universe.YT_to_sRGB {
		Y = base_Y / 1.5,
		T = (10^(3.8 + 2 * ((3.8 - math.log10(base_T)))) + base_T) / 2
	}
	sky_color.dawn_horizon = string.format("#%02x%02x%02x", dawn_horizon_sRGB.R, dawn_horizon_sRGB.G, dawn_horizon_sRGB.B)
	return sky_color
end

function nv_universe.set_planet_sky(player, seed)
	local sky_color = generate_sky_color(seed)
    player:set_sky {
        type = "regular",
        clouds = false,
        sky_color = sky_color
    }
    local sun = generate_sun(seed)
    local sunrise = string.format("(sunrisebg.png^[colorize:#ffffffff:alpha)^[multiply:%s", sky_color.sunrise)
    player:set_sun {
		visible = true,
		texture = sun.texture,
		sunrise = sunrise,
		sunrise_visible = true
	}
	player:set_moon {
		visible = false
	}
	player:set_stars {
		visible = true
	}
end
