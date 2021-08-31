-- Default player model, but all animations are the 'sit' animation
player_api.register_model("character_sitting.b3d", {
	animation_speed = 30,
	textures = {"character_sitting.png"},
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

local function make_normal_player(player)
	set_fall_damage(player, 100)
	player:set_physics_override {
		speed = 1,
		jump = 1,
		gravity = 1,
		sneak = true
	}
	player_api.set_model(player, "character.b3d")
	player:set_local_animation(
		{x = 0,   y = 79},
		{x = 168, y = 187},
		{x = 189, y = 198},
		{x = 200, y = 219},
		30
	)
end

function nv_ships.is_flying_callback(player)
    -- Player is flying
    if #(player:get_children()) == 0 then
        return
    end
    local dtime = get_dtime()
    local controls = player:get_player_control()
    local vel = player:get_velocity()
    if controls.sneak then
        local landing_pos = nv_ships.get_landing_position(player)
        if landing_pos ~= nil then
            -- Vertical landing
            landing_pos.y = landing_pos.y + 1
            local pos = player:get_pos()
            local target_vel = -14
            local target_time = -(pos.y - landing_pos.y)/target_vel
            set_fall_damage(player, 0)
            player:add_velocity {x=-vel.x, y=-vel.y+target_vel, z=-vel.z}
            player:set_physics_override {
                speed = 0,
                jump = 0,
                gravity = 0,
                sneak = false
            }
            minetest.after(target_time, function (player)
                -- Touched ground
                local vel = player:get_velocity()
                set_fall_damage(player, 20)
                player:add_velocity {x=-vel.x, y=-vel.y, z=-vel.z}
                player:set_pos(landing_pos)
                player:set_physics_override {
                    speed = 0,
                    jump = 0,
                    gravity = 1,
                    sneak = false
                }
                minetest.after(0.1, nv_ships.is_landed_callback, player)
            end, player)
            return
        elseif vel.y > -25 then
            -- Fly downwards
            local y_delta = math.max(-25 - vel.y, -7*dtime)
            player:add_velocity {x=0, y=y_delta, z=0}
        end
    elseif controls.jump then
        -- Fly upwards
        if vel.y < 25 then
            local y_delta = math.min(25 - vel.y, 15*dtime)
            player:add_velocity {x=0, y=y_delta, z=0}
        end
    end
    minetest.after(0.02, nv_ships.is_flying_callback, player)
end

function nv_ships.is_landed_callback(player)
    -- Player has landed or has not lifted off yet
    if #(player:get_children()) == 0 then
        return
    end
    local vel = player:get_velocity()
    player:add_velocity {x=-vel.x, y=-vel.y, z=-vel.z}
    local controls = player:get_player_control()
    if controls.jump then
        -- Lift off
        player:add_velocity {x=0, y=15, z=0}
        player:set_physics_override {
            speed = 5,
            jump = 0,
            gravity = 0.1,
            sneak = false
        }
        minetest.after(0.1, nv_ships.is_flying_callback, player)
    elseif controls.up or controls.down or controls.left or controls.right then
        if nv_ships.try_unboard_ship(player) then
            make_normal_player(player)
        else
            minetest.after(0.1, nv_ships.is_landed_callback, player)
        end
    else
        minetest.after(0.1, nv_ships.is_landed_callback, player)
    end
end

function nv_ships.ship_rightclick_callback(pos, node, clicker, itemstack, pointed_thing)
    if #(clicker:get_children()) >= 1 then
        return
    end
    if nv_ships.try_board_ship(pos, clicker) then
        -- Board ship
        set_fall_damage(clicker, 20)
        clicker:set_physics_override {
            speed = 0,
            jump = 0,
            gravity = 1,
            sneak = false
        }
        player_api.set_model(clicker, "character_sitting.b3d")
        clicker:set_local_animation(
            {x = 81, y = 160},
            {x = 81, y = 160},
            {x = 81, y = 160},
            {x = 81, y = 160},
            30
        )
        minetest.after(0.1, nv_ships.is_landed_callback, clicker)
    end
end

local function joinplayer_callback(player, last_login)
    local inventory = player:get_inventory()
    if not inventory:contains_item("main", "nv_ships:seat 1") then
	   inventory:add_item("main", "nv_ships:seat 2")
	   inventory:add_item("main", "nv_ships:floor 10")
	   inventory:add_item("main", "nv_ships:scaffold 10")
    end
	local name = player:get_player_name()
	if nv_ships.players_list[name] == nil then
		nv_ships.players_list[name] = {
			ships = {}
		}
	end
end

local function dieplayer_callback(player, last_login)
    local inventory = player:get_inventory()
    if not inventory:contains_item("main", "nv_ships:seat 1") then
	   inventory:add_item("main", "nv_ships:seat 1")
    end
    local children = player:get_children()
    if #children >= 1 then
		nv_ships.remove_ship_entity(player)
        make_normal_player(player)
    end
end

minetest.register_on_joinplayer(joinplayer_callback)
minetest.register_on_dieplayer(dieplayer_callback)
