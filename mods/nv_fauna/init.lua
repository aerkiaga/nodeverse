nv_fauna = {}

nv_fauna.planets = {}

function get_planet_fauna(planet_seed)
    local r = {}
    local G = PcgRandom(planet_seed)
    local count = G:next(1, 5)
    for i = 1, count do
        local freq = G:next(1, 4) * G:next(1, 4)
        local seed = G:next()
        local size = G:next(0, 99) / 100
        local leg_segments = G:next(1, 3)
        local leg_angle = 90 - G:next(0, 2) * G:next(0, 2) * G:next(0, 2) * G:next(1, 2) * G:next(1, 2) * G:next(1, 2)
        local less_legs = G:next(2, 3)
        local has_neck = (G:next(0, 1) == 1)
        local has_tail = (G:next(0, 1) == 1)
        local fauna = {
            freq = freq,
            seed = seed,
            size = size,
            leg_segments = leg_segments,
            leg_angle = leg_angle,
            less_legs = less_legs,
            has_neck = has_neck,
            has_tail = has_tail,
        }
        table.insert(r, #r + 1, fauna)
    end
    return r
end

dofile(minetest.get_modpath("nv_fauna") .. "/creatures.lua")

function start_walking_animation(creature)
    local t = 0
    for _, v in ipairs(creature.leg_entities) do
        if v:is_valid() then
            v:play_animation(1, {
                start_frame = t,
            })
        else
            creature.body_entity:remove()
        end
        t = t + 0.2
    end
end

function stop_walking_animation(creature)
    for _, v in ipairs(creature.leg_entities) do
        if v:is_valid() then
            v:stop_animation()
        else
            creature.body_entity:remove()
        end
    end
end

function spawn_entity(pos, planet_seed)
    local planet_fauna = get_planet_fauna(planet_seed)
    
    local pf = {}
    for k, v in ipairs(planet_fauna) do
        pf[k] = v.freq
    end
    local G = PcgRandom(planet_seed * os.clock())
    local index = gen_weighted(G, pf)
    local descriptor = planet_fauna[index]
    
    local creature = nv_fauna.spawn_creature(pos, descriptor)
    if nv_fauna.planets[planet_seed] == nil then
        nv_fauna.planets[planet_seed] = {}
    end
    creature.pos = pos
    creature.descriptor = descriptor
    creature.seed = planet_seed
    table.insert(nv_fauna.planets[planet_seed], creature)
end

function respawn_entity(creature)
    creature.body_entity:remove()
    local creature2 = nv_fauna.spawn_creature(creature.pos, creature.descriptor)
    creature2.pos = creature.pos
    creature2.descriptor = creature.descriptor
    creature2.seed = creature.seed
    local creatures = nv_fauna.planets[creature.seed]
    for i, creat in pairs(creatures) do
        if creat == creature then
            creatures[i] = creature2
        end
    end
end

function wander_entity(creature)
    local G = PcgRandom(os.clock() * 1000 + creature.pos.x + creature.pos.z)
    local x = creature.pos.x + G:next(-1, 1)
    local z = creature.pos.z + G:next(-1, 1)
    local floor = false
    for y = creature.pos.y - 2, creature.pos.y + 2, 1 do
        local pos = {x = x, y = y, z = z}
        local node = core.get_node(pos)
        local def = core.registered_nodes[node.name]
        if def.walkable then
            floor = true
        elseif floor then
            local new_pos = {x = x, y = y - 0.5, z = z}
            local dist = {x = new_pos.x - creature.pos.x, y = new_pos.y - creature.pos.y, z = new_pos.z - creature.pos.z}
            local t = 1.0
            local vel = {x = dist.x / t, y = dist.y / t, z = dist.z / t}
            creature.body_entity:add_velocity(vel)
            creature.body_entity:set_rotation({x = 0, y = math.atan2(vel.z, vel.x), z = 0})
            creature.pos = new_pos
            start_walking_animation(creature)
            core.after(1, function()
                local mvel = {x = -vel.x, y = -vel.y, z = -vel.z}
                creature.body_entity:add_velocity(mvel)
                local new_pos2 = {x = new_pos.x, y = new_pos.y + creature.height, z = new_pos.z}
                creature.body_entity:move_to(new_pos2, true)
                stop_walking_animation(creature)
            end)
            break
        end
    end
end

core.register_on_generated(function(minp, maxp, blockseed)
    local y_abs = minp.y
    local universal = nv_universe.get_universal_coordinates(y_abs)
    if universal and not universal.on_space then
        local seed = universal.planet
        local G = PcgRandom(seed)
        local density = 0.000001 * G:next(1, 10)
        local G = PcgRandom(blockseed)
        for x = minp.x, maxp.x, 1 do
            for z = minp.z, maxp.z, 1 do
                if G:next(0, 1000) / 1000 < density then
                    for y = minp.y, maxp.y, 1 do
                        local pos = {x = x, y = y, z = z}
                        local node = core.get_node(pos)
                        local def = core.registered_nodes[node.name]
                        if not def.walkable then
                            if y == minp.y or def.drawtype == "liquid" then
                                break
                            end
                            local pos2 = {x = x, y = y - 0.5, z = z}
                            spawn_entity(pos2, seed)
                            break
                        end
                    end
                end
            end
        end
    end
end)

core.register_globalstep(function(dtime)
    local G = PcgRandom(os.clock() * 1000)
    for seed, creatures in pairs(nv_fauna.planets) do
        for i, creature in pairs(creatures) do
            if G:next(0, 99) == 0 then
                wander_entity(creature)
            end
        end
    end
end)
