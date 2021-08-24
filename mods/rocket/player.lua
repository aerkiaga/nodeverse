--
-- Player as a Rocket
--
-- This file defines functions for turning the player into a rocket, applying decent rocket
-- physics, and allowing them to turn back into a player
--

local rocket_players = {}
local liftoff_players = {}

-- Default player appearance
player_api.register_model("rocket_player.obj", {
	animation_speed = 0,
	textures = {"rocket.png"},
	animations = {},
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 2.5, 0.5},
	stepheight = 0.6,
	eye_height = 1.47,
})

-- Turn a player into a rocket
rocket.player_to_rocket = function (player, pos)
    player:set_physics_override {
        speed = 5,
        gravity = 1,
    }
	player:set_pos(pos)
    player_api.set_model(player, "rocket_player.obj")
    local name = player:get_player_name()
    rocket_players[name] = true
    liftoff_players[name] = false
end

--Turn a rocket player back into a player
rocket.rocket_to_player = function(player, pos)
    player_api.player_attached[player:get_player_name()] = false
    player_api.set_model(player, "character.b3d")
    player:set_local_animation(
        {x = 0,   y = 79},
        {x = 168, y = 187},
        {x = 189, y = 198},
        {x = 200, y = 219},
        30
    )
    rocket_players[player:get_player_name()] = false
    player:set_physics_override {
        speed = 1,
        gravity = 1,
    }

    --Move to rocket landing position
    if pos ~= nil then
        player:set_pos {x=pos.x, y=pos.y, z=pos.z}
    end

    player:get_inventory():add_item("main", "rocket:rocket 1")
end

rocket.particles = function(pos)
    minetest.add_particlespawner {
        amount = 5,
        time   = 0.1,
        minpos = {x=pos.x-0.2,y=pos.y,z=pos.z-0.2},
        maxpos = {x=pos.x+0.2,y=pos.y,z=pos.z+0.2},
        minvel = {x=0,y=-4,z=0},
        maxvel = {x=0,y=-3,z=0},
        minacc = 0,
        maxacc = 0,
        minexptime = 3.5,
        minexptime = 3.5,
        maxexptime = 4,
        minsize = 0.8,
        maxsize = 1.5,
        collisiondetection = false,
        collision_removal  = false,
        vertical = false,
        texture = 'thrust.png',
    }
end

-- Rocket globalstep
local function rocket_physics(dtime, player, name)
	-- Handle the rocket flying up
	local controls = player:get_player_control()
	local pos = player:get_pos()
	if controls.jump then
	    player:add_velocity {x=0,y=30*dtime,z=0}
	    rocket.particles(pos)
	end

	local vel = player:get_velocity()

	if(liftoff_players[name]) then
	    -- Handle the player landing on ground
	    pos.y = pos.y - 1
	    local node = minetest.get_node(pos)
	    pos.y = pos.y + 1
	    if minetest.registered_nodes[node.name].walkable
		and math.abs(vel.y) < 0.2 then
	        rocket.rocket_to_player(player, pos)
			rocket_players[name] = nil
			liftoff_players[name] = nil
	    end
	else
	    if vel.y > 1 then
	        liftoff_players[name] = true
	    end
	end
end

local function globalstep_callback(dtime)
    local player_list = minetest.get_connected_players()
    for _, player in pairs(player_list) do
        -- Check if player is rocket
        local name = player:get_player_name()
        if rocket_players[name] ~= nil then
			rocket_physics(dtime, player, name)
        end
    end
end

minetest.register_globalstep(globalstep_callback)

-- Rocket on_join_player
local function rocket_join_player(player, last_login)
    local inventory = player:get_inventory()
	if not inventory:contains_item("main", "rocket:rocket 1") then
		inventory:add_item("main", "rocket:rocket 1")
	end
end

minetest.register_on_joinplayer(rocket_join_player)
