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
        local fauna = {
            freq = freq,
            seed = seed,
            size = size,
            leg_segments = leg_segments,
            leg_angle = leg_angle,
            less_legs = less_legs,
        }
        table.insert(r, #r + 1, fauna)
    end
    return r
end

dofile(minetest.get_modpath("nv_fauna") .. "/creatures.lua")

function start_walking_animation(creature)
    local t = 0
    for _, v in ipairs(creature.leg_entities) do
        core.after(t, function()
            if v:is_valid() then
                v:play_animation(1)
            end
        end)
        t = t + 0.2
    end
end

function spawn_entity(pos, planet_seed)
    local planet_fauna = get_planet_fauna(planet_seed)
    
    local pf = {}
    for k, v in ipairs(planet_fauna) do
        table.insert(pf, k, v.freq)
    end
    local G = PcgRandom(planet_seed * os.clock())
    local index = gen_weighted(G, pf)
    local creature = planet_fauna[index]
    
    local creature = nv_fauna.spawn_creature(pos, creature)
    if nv_fauna.planets[planet_seed] == nil then
        nv_fauna.planets[planet_seed] = {}
    end
    table.insert(nv_fauna.planets[planet_seed], #nv_fauna.planets[planet_seed], creature)
    start_walking_animation(creature)
end

core.register_on_generated(function(minp, maxp, blockseed)
    local y_abs = minp.y
    local universal = nv_universe.get_universal_coordinates(y_abs)
    if universal and not universal.on_space then
        local seed = universal.planet
        local G = PcgRandom(seed)
        local density = 0.00001 * G:next(1, 10)
        local G = PcgRandom(blockseed)
        for x = minp.x, maxp.x, 1 do
            for z = minp.z, maxp.z, 1 do
                if G:next(0, 1000) / 1000 < density then
                    for y = minp.y, maxp.y, 1 do
                        local pos = {x = x, y = y, z = z}
                        local node = core.get_node(pos)
                        local def = core.registered_nodes[node.name]
                        if not def.walkable then
                            if y == minp.y then
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

