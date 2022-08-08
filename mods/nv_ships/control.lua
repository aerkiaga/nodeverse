--[[
TODO: explain all this code
]]

local function make_normal_player(player)
    nv_player.set_fall_damage(player, 100)
    player:set_physics_override {
        speed = 1,
        jump = 1,
        gravity = 1,
        sneak = true
    }
    nv_player.reset_model(player)
end

local function start_vertical_landing(ship, player, landing_pos)
    local name = player:get_player_name()
    -- Stop in mid-air and set new physics
    local pos = player:get_pos()
    local vel = player:get_velocity()
    player:add_velocity {x=-vel.x, y=-vel.y, z=-vel.z}
    player:set_physics_override {
        speed = 0,
        jump = 0,
        gravity = 0,
        sneak = false
    }
    nv_player.set_fall_damage(player, 0)
    nv_ships.players_list[name].state = "landing"
    minetest.sound_stop(nv_ships.players_list[name].sound)
    nv_ships.players_list[name].sound = minetest.sound_play({
        name = "nv_landing", gain = 0.5, pitch = 1
    }, {
        object = player, gain = 0.25, max_hear_distance = 10, loop = false
    }, false)
    minetest.after(0.1, function ()
        -- Actually start moving down
        local target_vel = -14
        local target_time = -(pos.y - landing_pos.y)/target_vel
        local x_vel = (landing_pos.x - pos.x)*target_time
        local z_vel = (landing_pos.z - pos.z)*target_time
        local vel = player:get_velocity()
        player:add_velocity {x=-vel.x+x_vel, y=-vel.y+target_vel, z=-vel.z+z_vel}
        nv_player.set_fall_damage(player, 0)
        minetest.after(target_time, function ()
            -- Touch ground
            local new_vel = player:get_velocity()
            player:add_velocity {x=-new_vel.x, y=-new_vel.y, z=-new_vel.z}
            player:set_pos(landing_pos)
            player:set_physics_override {
                speed = 0,
                jump = 0,
                gravity = 1,
                sneak = false
            }
            nv_player.set_fall_damage(player, 0)

            local new_landing_pos = nv_ships.get_landing_position(ship, player, landing_pos)
            nv_ships.ship_to_node(ship, player, new_landing_pos)
            player:set_pos(new_landing_pos)
            minetest.sound_stop(nv_ships.players_list[name].sound)
            minetest.sound_play({
                name = "nv_touch_ground", gain = 0.5, pitch = 1
            }, {
                object = player, gain = 1, max_hear_distance = 10, loop = false
            }, true)
            minetest.after(0.1, function ()
                -- Restore player
                nv_ships.players_list[name].state = "landed"
                nv_player.set_fall_damage(player, 20)
                nv_player.set_collisionbox(player, {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3})
            end)
        end)
    end)
end

function nv_ships.is_flying_callback(ship, player, dtime)
    -- Player is flying
    if #(player:get_children()) == 0 then
        return
    end
    local controls = player:get_player_control()
    local vel = player:get_velocity()
    if controls.sneak then
        local landing_pos = nv_ships.get_landing_position(ship, player)
        if landing_pos ~= nil then
            start_vertical_landing(ship, player, landing_pos)
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
end

local function set_flying_state(ship, player)
    local name = player:get_player_name()
    player:set_physics_override {
        speed = 5,
        jump = 0,
        gravity = 0.1,
        sneak = false
    }
    nv_player.set_collisionbox(player, nv_ships.get_ship_collisionbox(ship))
    nv_ships.players_list[name].state = "flying"
    nv_ships.players_list[name].sound = minetest.sound_play({
        name = "nv_engine", gain = 0.5, pitch = 1
    }, {
        object = player, gain = 0.25, max_hear_distance = 10, loop = true
    }, false)
end

function nv_ships.is_landed_callback(ship, player)
    -- Player has landed or has not lifted off yet
    local vel = player:get_velocity()
    player:add_velocity {x=-vel.x, y=-vel.y, z=-vel.z}
    local name = player:get_player_name()
    local controls = player:get_player_control()
    if controls.jump then
        -- Lift off
        nv_ships.ship_to_entity(ship, player)
        player:add_velocity {x=0, y=15, z=0}
        minetest.sound_play({
            name = "nv_liftoff", gain = 0.5, pitch = 1
        }, {
            object = player, gain = 0.4, max_hear_distance = 10, loop = false
        }, true)
        set_flying_state(ship, player)

    elseif controls.up or controls.down or controls.left or controls.right then
        if nv_ships.try_unboard_ship(player) then
            make_normal_player(player)
            nv_ships.players_list[name].state = nil
            nv_ships.players_list[name].cur_ship = nil
        end
    end
end

local function master_control_callback()
    local dtime = get_dtime()
    local player_list = minetest.get_connected_players()
    for index, player in ipairs(player_list) do
        local name = player:get_player_name()
        local state = nv_ships.players_list[name].state
        local ship = nv_ships.players_list[name].cur_ship
        if state == "landed" then
            nv_ships.is_landed_callback(ship, player)
        elseif state == "flying" then
            nv_ships.is_flying_callback(ship, player, dtime)
        end
    end
    if dtime > 0.02 then
        minetest.after(0.02, master_control_callback)
    end
end

local function globalstep_callback(dtime)
    master_control_callback()
end

function nv_ships.ship_rightclick_callback(pos, node, clicker, itemstack, pointed_thing)
    if #(clicker:get_children()) >= 1 then
        return
    end
    local ship = nv_ships.try_board_ship(pos, clicker)
    if ship == nil then
        return
    end
    -- Board ship
    nv_player.set_fall_damage(clicker, 20)
    clicker:set_physics_override {
        speed = 0,
        jump = 0,
        gravity = 1,
        sneak = false
    }
    nv_player.sit_model(clicker)
    local name = clicker:get_player_name()
    nv_ships.players_list[name].state = "landed"
    nv_ships.players_list[name].cur_ship = ship
end

-- Serialized default ship for new players
local default_ship = nil

function nv_ships.set_default_ship(data)
    default_ship = data
end

local function joinplayer_callback(player, last_login)
    local name = player:get_player_name()
    local inventory = player:get_inventory()
    if nv_ships.players_list[name] == nil then        
        nv_ships.players_list[name] = {
            ships = {}
        }
        nv_ships.load_player_state(player)
        if #nv_ships.players_list[name].ships == 0 and default_ship ~= nil then
            local ship = nv_ships.deserialize_ship(default_ship)
            nv_ships.players_list[name].ships = {ship}
            nv_ships.players_list[name].cur_ship = ship
            nv_ships.players_list[name].state = "flying"
            ship.owner = name
            ship.index = 0
            ship.state = "entity"
        end
        local current_ship = nv_ships.players_list[name].cur_ship
        if current_ship ~= nil and current_ship.state == "entity" then
            nv_ships.ship_to_entity(current_ship, player, false)
            if nv_ships.players_list[name].state == "flying" then
                set_flying_state(current_ship, player)
            end
        end
    end
end

local function leaveplayer_callback(player, timed_out)
    nv_ships.remove_ship_entity(player)
    nv_ships.store_player_state(player)
end

local function shutdown_callback()
    for player_index, player in ipairs(minetest.get_connected_players()) do
        nv_ships.remove_ship_entity(player)
        nv_ships.store_player_state(player)
    end
end

local function dieplayer_callback(player, last_login)
    -- TODO: a player's ship(s) should be summoned to the player's spawn site,
    -- or the player should spawn at their ship's position
    local name = player:get_player_name()
    local inventory = player:get_inventory()
    if not inventory:contains_item("main", "nv_ships:seat 1") then
       inventory:add_item("main", "nv_ships:seat 1")
    end
    if nv_ships.players_list[name].state ~= nil then
        nv_ships.remove_ship_entity(player)
        make_normal_player(player)
        nv_ships.players_list[name].state = nil
        nv_ships.players_list[name].cur_ship = nil
    end
end

minetest.register_globalstep(globalstep_callback)
minetest.register_on_joinplayer(joinplayer_callback)
minetest.register_on_leaveplayer(leaveplayer_callback)
minetest.register_on_dieplayer(dieplayer_callback)
minetest.register_on_shutdown(shutdown_callback)
