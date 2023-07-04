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
		base_T = gen_linear(G, 0, 10000)
	elseif meta.atmosphere == "scorching" then
		base_Y = gen_linear(G, 0, 0.1)
		base_T = gen_linear(G, 0, 5000)
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
	return sky_color
end

function nv_universe.set_planet_sky(player, seed)
    player:set_sky {
        type = "regular",
        clouds = false,
        sky_color = generate_sky_color(seed)
    }
    player:set_sun {
		visible = true,
		sunrise_visible = true
	}
	player:set_moon {
		visible = false
	}
	player:set_stars {
		visible = true
	}
end
