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

function nv_universe.set_planet_sky(player, seed)
    player:set_sky {
        type = "regular",
        clouds = false
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
