nv_player = {}

function nv_player.set_fall_damage(player, amount)
    local armor = player:get_armor_groups()
    if amount <= 0 then
        armor.immortal = 1
    else
        armor.immortal = nil
    end
    armor.fall_damage_add_percent = amount - 100
    player:set_armor_groups(armor)
end

function nv_player.set_collisionbox(player, collisionbox)
    local properties = player:get_properties()
    properties.collisionbox = collisionbox
    player:set_properties(properties)
end

-- Default player appearance
player_api.register_model("character.b3d", {
	animation_speed = 30,
	textures = {"spacesuit.png"},
	animations = {
		-- Standard animations.
		stand     = {x = 0,   y = 79},
		lay       = {x = 162, y = 166},
		walk      = {x = 168, y = 187},
		mine      = {x = 189, y = 198},
		walk_mine = {x = 200, y = 219},
		sit       = {x = 81,  y = 160},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.47,
})

-- Default player model, but all animations are the 'sit' animation
player_api.register_model("character_sitting.b3d", {
	animation_speed = 30,
	textures = {"spacesuit.png"},
	animations = {
		-- 'Sit' animation, everywhere
		stand     = {x = 81,  y = 160},
		lay       = {x = 81,  y = 160},
		walk      = {x = 81,  y = 160},
		mine      = {x = 81,  y = 160},
		walk_mine = {x = 81,  y = 160},
		sit       = {x = 81,  y = 160},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.47,
})
