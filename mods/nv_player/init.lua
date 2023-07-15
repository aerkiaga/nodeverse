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
    textures = {"nv_spacesuit.png"},
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
    textures = {"nv_spacesuit.png"},
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

function nv_player.reset_model(player)
    player_api.set_model(player, "character.b3d")
    player:set_local_animation(
        {x = 0,   y = 79},
        {x = 168, y = 187},
        {x = 189, y = 198},
        {x = 200, y = 219},
        30
    )
end

function nv_player.sit_model(player)
    player_api.set_model(player, "character_sitting.b3d")
    player:set_local_animation(
        {x = 81, y = 160},
        {x = 81, y = 160},
        {x = 81, y = 160},
        {x = 81, y = 160},
        30
    )
end

local function joinplayer_callback(player, last_login)
    player:set_minimap_modes({
        {
            type = "surface",
            size = 243
        }
    }, 0
    )
    player:set_lighting {
        saturation = 1,
        shadows = {
            intensity = 0.5
        },
        exposure = {
            luminance_min = -3,
            luminance_max = -3,
            exposure_correction = 0,
            speed_dark_bright = 10,
            speed_bright_dark = 10,
            center_weight_power = 1
        }
    }
end

minetest.register_on_joinplayer(joinplayer_callback)

--
-- Copied code of init.lua from the Hand mod
--
-- Adds the default MTG hand tool to the game
--

-- Copyright (C) 2010-2012 celeron55, Perttu Ahola <celeron55@gmail.com>
-- This file was released under GNU LGPL-2.1
-- As part of this mod, it is re-released under GNU GPL-3.0
minetest.override_item("", {
    wield_scale = {x=1,y=1,z=2.5},
    tool_capabilities = {
        full_punch_interval = 0.9,
        max_drop_level = 0,
        groupcaps = {
            crumbly = {times={[2]=3.00, [3]=0.70}, uses=0, maxlevel=1},
            snappy = {times={[3]=0.40}, uses=0, maxlevel=1},
            oddly_breakable_by_hand = {times={[1]=3.50,[2]=2.00,[3]=0.70}, uses=0}
        },
        damage_groups = {fleshy=1},
    }
})
