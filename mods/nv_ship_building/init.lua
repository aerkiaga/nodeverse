local prev_globalstep = nil

local function get_dtime()
    local r
    local current_time = minetest.get_us_time()
	if prev_globalstep == nil then
		r = 0
	else
		r = (current_time - prev_globalstep) / 1e+6
	end
	prev_globalstep = current_time
    return r
end

local function get_landing_position(player)
    local pos = player:get_pos()
    for y=pos.y, pos.y - 32, -1 do
        pos.y = y
        local node = minetest.get_node(pos)
        if minetest.registered_nodes[node.name].walkable then
            return pos
        end
    end
    return nil
end

function is_flying_callback(player)
    local dtime = get_dtime()
    local controls = player:get_player_control()
    local vel = player:get_velocity()
    if controls.sneak then
        local landing_pos = get_landing_position(player)
        if landing_pos ~= nil then
            landing_pos.y = landing_pos.y + 1
            player:set_pos(landing_pos)
            player:add_velocity {x=-vel.x, y=-vel.y, z=-vel.z}
            player:set_physics_override {
                speed = 0,
                jump = 0,
                gravity = 1,
                sneak = false
            }
            minetest.after(0.02, is_landed_callback, player)
            return
        elseif vel.y > -25 then
            local y_delta = math.max(-25 - vel.y, -7*dtime)
            player:add_velocity {x=0, y=y_delta, z=0}
        end
    elseif controls.jump then
        if vel.y < 25 then
            local y_delta = math.min(25 - vel.y, 15*dtime)
            player:add_velocity {x=0, y=y_delta, z=0}
        end
    end
    minetest.after(0.02, is_flying_callback, player)
end

function is_landed_callback(player)
    local controls = player:get_player_control()
    if controls.jump then
        player:add_velocity {x=0, y=15, z=0}
        player:set_physics_override {
            speed = 5,
            jump = 0,
            gravity = 0.2,
            sneak = false
        }
        minetest.after(0.1, is_flying_callback, player)
    else
        minetest.after(0.1, is_landed_callback, player)
    end
end

local function seat_rightclick_callback(pos, node, clicker, itemstack, pointed_thing)
    minetest.remove_node(pos)
    local ent_seat = minetest.add_entity(pos, "nv_ship_building:ent_seat")
    clicker:set_pos(pos)
    ent_seat:set_attach(clicker)
    clicker:set_physics_override {
        speed = 0,
        jump = 0,
        gravity = 1,
        sneak = false
    }
    minetest.after(0.1, is_landed_callback, clicker)
end

minetest.register_node("nv_ship_building:seat", {
    description = "Seat",
    drawtype = "normal",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"rocket.png"},
    groups = { oddly_breakable_by_hand=3 },

    on_rightclick = seat_rightclick_callback,
})

minetest.register_entity("nv_ship_building:ent_seat", {
    initial_properties = {
        visual = "cube",
        textures = {
            "rocket.png", "rocket.png", "rocket.png",
            "rocket.png", "rocket.png", "rocket.png"
        },
        --automatic_rotate = 1.0,
    },
})

local function joinplayer_callback(player, last_login)
    local inventory = player:get_inventory()
	inventory:add_item("main", "nv_ship_building:seat 1")
end

minetest.register_on_joinplayer(joinplayer_callback)
