nv_fauna.hinges = {
    {3.0, 1.0, 1.0, 1.0, 1.0, 1.0,},
    {4.0, 2.0, 2.0, 1.0, 1.0, 1.0,},
    {6.0, 2.5, 2.5, 4.0, 1.0, 1.0,},
    {8.0, 2.5, 2.5, 6.0, 2.0, 2.0,},
    {15.0, 5.0, 5.0, 10.0, 2.0, 2.0,},
    {25.0, 5.0, 10.0, 7.0, 4.0, 4.0,},
    {40.0, 10.0, 20.0, 10.0, 10.0, 10.0,},
    {60.0, 20.0, 30.0, 20.0, 20.0, 20.0,},
}

for i = 1, #nv_fauna.hinges do
    core.register_entity(string.format("nv_fauna:hinge%d", i), {
        initial_properties = {
            visual = "mesh",
            mesh = string.format("nv_hinge%d.gltf", i),
            textures = {
                "nv_woody_stem.png",
                "nv_woody_stem.png",
            },
        },
    })
    core.register_entity(string.format("nv_fauna:hinge%d_r", i), {
        initial_properties = {
            visual = "mesh",
            mesh = string.format("nv_hinge%d_r.gltf", i),
            textures = {
                "nv_woody_stem.png",
                "nv_woody_stem.png",
            },
        },
    })
end

function gen_legs(creature, body_hinge)
    local G = PcgRandom(creature.seed)
    local angles = {}
    local hinges = {}
    
    local angles_pre = {}
    for i = 1, creature.leg_segments do
        angles_pre[i] = G:next(1, 10)
    end
    local sum = 0
    for i = 1, creature.leg_segments do
        sum = sum + angles_pre[i]
    end
    for i = 1, creature.leg_segments do
        angles[i] = creature.leg_angle * angles_pre[i] / sum
    end
    
    local hinge = body_hinge
    for i = 1, creature.leg_segments do
        if hinge >= 2 then
            hinge = G:next(G:next(1, hinge - 1), hinge - 1)
        end
        hinges[i] = hinge
    end
    
    return {
        angles = angles,
        hinges = hinges,
    }
end

function gen_leg_count(body_hinge, legs)
    local body_length = nv_fauna.hinges[body_hinge][1]
    local leg_width = nv_fauna.hinges[legs.hinges[1]][3]
    local count = math.floor(body_length / leg_width)
    if count == 0 then
        return 1
    else
        return count
    end
end

function create_leg(legs, body_pos, suffix)
    local leg_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d%s", legs.hinges[1], suffix))
    local prev_entity = leg_entity
    for i = 2, #legs.hinges do
        local prev_length = nv_fauna.hinges[legs.hinges[i - 1]][4]
        local next_length = nv_fauna.hinges[legs.hinges[i]][1]
        local attach_x = 0
        local attach_len = next_length * math.cos(legs.angles[i] * math.pi / 180)
        local attach_height = next_length * math.sin(legs.angles[i] * math.pi / 180)
        
        local hinge_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d%s", legs.hinges[i], suffix))
        core.after(0, function(he, pe)
            he:set_attach(pe, "LeafSwinging", {x=attach_x + attach_len, y=-attach_height, z=0}, {x=0, y=0, z=-legs.angles[i]}, false)
        end, hinge_entity, prev_entity)
        hinge_entity:set_texture_mod("^[colorize:#aabbcc:90")
        prev_entity = hinge_entity
    end
    leg_entity:set_texture_mod("^[colorize:#001122:90")
    return leg_entity
end

function add_legs(body_entity, body_hinge, legs, leg_count, body_pos)
    local body_width = nv_fauna.hinges[body_hinge][3]
    local body_length = nv_fauna.hinges[body_hinge][1]
    local leg_width = nv_fauna.hinges[legs.hinges[1]][3]
    local leg_length = nv_fauna.hinges[legs.hinges[1]][1]
    local leg_entities = {}
    
    for leg_i = 0, leg_count - 1 do
        local attach_x = (body_length - leg_width) * leg_i / leg_count + leg_width / 2
        local attach_z = body_width / 2
        local attach_len = leg_length * math.cos(legs.angles[1] * math.pi / 180)
        local attach_height = leg_length * math.sin(legs.angles[1] * math.pi / 180)
        
        local leg_entity = create_leg(legs, body_pos, "")
        core.after(0, function()
            leg_entity:set_attach(body_entity, "", {x=-attach_x, y=-attach_height, z=-attach_z - attach_len}, {x=-90, y=90 - legs.angles[1], z=-90}, false)
        end)
        table.insert(leg_entities, #leg_entities + 1, leg_entity)
        
        local leg_entity2 = create_leg(legs, body_pos, "_r")
        core.after(0, function()
            leg_entity2:set_attach(body_entity, "", {x=-attach_x, y=-attach_height, z=attach_z + attach_len}, {x=90, y=-90 + legs.angles[1], z=-90}, false)
        end)
        table.insert(leg_entities, #leg_entities + 1, leg_entity2)
    end
    return leg_entities
end

function compute_leg_height(legs)
    local angle = 0
    local height = 0
    for i = 1, #legs.angles do
        angle = angle + legs.angles[i]
        local leg_length = nv_fauna.hinges[legs.hinges[i]][1]
        local leg_length2 = nv_fauna.hinges[legs.hinges[i]][4]
        local total_length = leg_length + leg_length2
        local total_height = total_length * math.sin(angle * math.pi / 180)
        height = height + total_height
    end
    return height
end

function nv_fauna.spawn_creature(pos, creature)
    local body_hinge = math.floor(creature.size * #nv_fauna.hinges + 1)
    local legs = gen_legs(creature, body_hinge)
    local leg_count = gen_leg_count(body_hinge, legs)
    if math.floor(leg_count / creature.less_legs) > 1 then
        leg_count = math.floor(leg_count / creature.less_legs)
    end

    local height = compute_leg_height(legs) / 10
    local body_pos = {x = pos.x, y = pos.y + height, z = pos.z}
    
    local body_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d", body_hinge))
    local leg_entities = add_legs(body_entity, body_hinge, legs, leg_count, body_pos)
    local creature = {
        body_entity = body_entity,
        leg_entities = leg_entities,
    }
    return creature
end
