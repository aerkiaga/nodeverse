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

-- Default player model, but all animations are the 'sit' animation
player_api.register_model("character_sitting.b3d", {
	animation_speed = 30,
	textures = {"character.png"},
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
