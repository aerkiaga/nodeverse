function nv_ship_building.is_flying_callback(player)
    -- Player is flying
    local dtime = get_dtime()
    local controls = player:get_player_control()
    local vel = player:get_velocity()
    if controls.sneak then
        local landing_pos = nv_ship_building.get_landing_position(player)
        if landing_pos ~= nil then
            -- Vertical landing
            landing_pos.y = landing_pos.y + 1
            local pos = player:get_pos()
            local target_vel = -14
            local target_time = -(pos.y - landing_pos.y)/target_vel
            set_fall_damage(player, -1000)
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
                minetest.after(0.1, nv_ship_building.is_landed_callback, player)
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
    minetest.after(0.02, nv_ship_building.is_flying_callback, player)
end

function nv_ship_building.is_landed_callback(player)
    -- Player has landed or has not lifted off yet
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
        minetest.after(0.1, nv_ship_building.is_flying_callback, player)
    elseif controls.up or controls.down or controls.left or controls.right then
        if nv_ship_building.try_unboard_ship(player) then
            player:set_physics_override {
                speed = 1,
                jump = 1,
                gravity = 1,
                sneak = true
            }
        else
            minetest.after(0.1, nv_ship_building.is_landed_callback, player)
        end
    else
        minetest.after(0.1, nv_ship_building.is_landed_callback, player)
    end
end

local function ship_rightclick_callback(pos, node, clicker, itemstack, pointed_thing)
    if nv_ship_building.try_board_ship(pos, clicker) then
        -- Board ship
        set_fall_damage(clicker, 20)
        clicker:set_physics_override {
            speed = 0,
            jump = 0,
            gravity = 1,
            sneak = false
        }
        minetest.after(0.1, nv_ship_building.is_landed_callback, clicker)
    end
end

minetest.register_node("nv_ship_building:seat", {
    description = "Seat",
    drawtype = "normal",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"rocket.png"},
    groups = { oddly_breakable_by_hand=3 },

    on_rightclick = ship_rightclick_callback,
})

minetest.register_entity("nv_ship_building:ent_seat", {
    initial_properties = {
        visual = "cube",
        textures = {
            "rocket.png", "rocket.png", "rocket.png",
            "rocket.png", "rocket.png", "rocket.png"
        },
    },
})

local function joinplayer_callback(player, last_login)
    local inventory = player:get_inventory()
	inventory:add_item("main", "nv_ship_building:seat 1")
end

minetest.register_on_joinplayer(joinplayer_callback)
