function nv_ship_building.is_flying_callback(player)
    -- Player is flying
    if #(player:get_children()) == 0 then
        return
    end
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
        minetest.after(0.1, nv_ship_building.is_flying_callback, player)
    elseif controls.up or controls.down or controls.left or controls.right then
        if nv_ship_building.try_unboard_ship(player) then
            set_fall_damage(player, 100)
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
    if #(clicker:get_children()) >= 1 then
        return
    end
    if nv_ship_building.try_board_ship(pos, clicker) then
        -- Board ship
        set_fall_damage(clicker, 20)
        clicker:set_physics_override {
            speed = 0,
            jump = 0,
            gravity = 1,
            sneak = false
        }
        clicker:set_local_animation(
            {x = 81, y = 160},
            {x = 81, y = 160},
            {x = 81, y = 160},
            {x = 81, y = 160},
            30
        )
        minetest.after(0.1, nv_ship_building.is_landed_callback, clicker)
    end
end

minetest.register_node("nv_ship_building:seat", {
    description = "Seat",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype2 = "facedir",

    tiles = {"seat.png"},
    use_texture_alpha = "clip",
    groups = { oddly_breakable_by_hand=3 },
    mesh = "seat.obj",

    on_rightclick = ship_rightclick_callback,
})

minetest.register_entity("nv_ship_building:ent_seat", {
    initial_properties = {
        visual = "mesh",
        textures = {
            "seat.png", "seat.png", "seat.png",
            "seat.png", "seat.png", "seat.png"
        },
        use_texture_alpha = true,
        visual_size = {x=10, y=10, z=10},
        mesh = "seat.obj"
    },
})

local function joinplayer_callback(player, last_login)
    local inventory = player:get_inventory()
    if not inventory:contains_item("main", "nv_ship_building:seat 1") then
	   inventory:add_item("main", "nv_ship_building:seat 1")
    end
end

local function dieplayer_callback(player, last_login)
    local inventory = player:get_inventory()
    if not inventory:contains_item("main", "nv_ship_building:seat 1") then
	   inventory:add_item("main", "nv_ship_building:seat 1")
    end
    local children = player:get_children()
    if #children >= 1 then
        set_fall_damage(player, 100)
        player:set_physics_override {
            speed = 1,
            jump = 1,
            gravity = 1,
            sneak = true
        }
        for index, child in ipairs(children) do
            local properties = child:get_properties() or {}
            if true then
                child:set_detach(player)
                child:remove()
            end
        end
        player:set_local_animation(
            {x = 0,   y = 79},
            {x = 168, y = 187},
            {x = 189, y = 198},
            {x = 200, y = 219},
            30
        )
    end
end

minetest.register_on_joinplayer(joinplayer_callback)
minetest.register_on_dieplayer(dieplayer_callback)
