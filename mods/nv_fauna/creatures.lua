nv_fauna.hinges = {
    {1.0, 1.0, 1.0, 1.0, 1.0, 1.0,},
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

function gen_color(seed)
    local G = PcgRandom(seed)
    local r = G:next(0, 255)
    local g = G:next(0, 255)
    local b = G:next(0, 255)
    return {r=r, g=g, b=b}
end

function clamp_u8(x)
    if x < 0 then return 0 end
    if x > 255 then return 255 end
    return x
end

function mod_color(color)
    local G = PcgRandom(color.r * 75834 + color.g * 6381 + color.b * 3)
    local range = 2^G:next(5, 7)
    local r = clamp_u8(color.r + G:next(-range, range))
    local g = clamp_u8(color.g + G:next(-range, range))
    local b = clamp_u8(color.b + G:next(-range, range))
    return {r=r, g=g, b=b}
end

function color_to_mod(color)
    return string.format("^[colorize:#%02x%02x%02x:90", color.r, color.g, color.b)
end

function create_leg(legs, body_pos, suffix, leg_color)
    local leg_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d%s", legs.hinges[1], suffix))
    local prev_entity = leg_entity
    for i = 2, #legs.hinges do
        local prev_length = nv_fauna.hinges[legs.hinges[i - 1]][4]
        local next_length = nv_fauna.hinges[legs.hinges[i]][1]
        local attach_x = 0
        local attach_len = next_length * math.cos(legs.angles[i] * math.pi / 180)
        local attach_height = next_length * math.sin(legs.angles[i] * math.pi / 180)
        local hinge_color = mod_color(leg_color)
        
        local hinge_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d%s", legs.hinges[i], suffix))
        core.after(0, function(he, pe)
            he:set_attach(pe, "LeafSwinging", {x=attach_x + attach_len, y=-attach_height, z=0}, {x=0, y=0, z=-legs.angles[i]}, false)
        end, hinge_entity, prev_entity)
        hinge_entity:set_texture_mod(color_to_mod(hinge_color))
        prev_entity = hinge_entity
    end
    leg_entity:set_texture_mod(color_to_mod(leg_color))
    return leg_entity
end

function add_legs(body_entity, body_hinge, legs, leg_count, body_pos, body_color)
    local body_width = nv_fauna.hinges[body_hinge][3]
    local body_length = nv_fauna.hinges[body_hinge][1]
    local leg_width = nv_fauna.hinges[legs.hinges[1]][3]
    local leg_length = nv_fauna.hinges[legs.hinges[1]][1]
    local leg_entities = {}
    
    local leg_color = mod_color(body_color)
    for leg_i = 0, leg_count - 1 do
        local attach_x = (body_length - leg_width) * 0.8 * leg_i / leg_count + leg_width / 2
        local attach_z = body_width / 2
        local attach_len = leg_length * math.cos(legs.angles[1] * math.pi / 180)
        local attach_height = leg_length * math.sin(legs.angles[1] * math.pi / 180)
        
        local leg_entity = create_leg(legs, body_pos, "", leg_color)
        core.after(0, function()
            leg_entity:set_attach(body_entity, "", {x=-attach_x, y=-attach_height, z=-attach_z - attach_len}, {x=-90, y=90 - legs.angles[1], z=-90}, false)
        end)
        table.insert(leg_entities, #leg_entities + 1, leg_entity)
        
        local leg_entity2 = create_leg(legs, body_pos, "_r", leg_color)
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
        local total_length = leg_length + leg_length2 / 2
        local total_height = total_length * math.sin(angle * math.pi / 180)
        height = height + total_height
    end
    return height + nv_fauna.hinges[legs.hinges[#legs.hinges]][4] / 2
end

function add_neck(body_entity, body_hinge, body_pos, body_color)
    local G = PcgRandom(body_color.r * 6546 + body_color.g * 4563 + body_color.b * 2134)
    local neck_hinge = 1
    if body_hinge > 1 then
        neck_hinge = G:next(G:next(1, body_hinge - 1), body_hinge - 1)
    end
    local neck_len = nv_fauna.hinges[neck_hinge][1]
    local neck_angle = G:next(0, 90)
    local attach_len = neck_len * math.cos(neck_angle * math.pi / 180)
    local attach_height = neck_len * math.sin(neck_angle * math.pi / 180)
    local neck_color = body_color
    
    local neck_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d", neck_hinge))
    core.after(0, function()
        neck_entity:set_attach(body_entity, "LeafSwinging", {x=attach_len, y=attach_height, z=0}, {x=0, y=0, z=neck_angle}, false)
    end)
    neck_entity:set_texture_mod(color_to_mod(neck_color))
    return neck_entity, neck_angle, neck_hinge
end

function add_tail(body_entity, body_hinge, body_pos, body_color)
    local G = PcgRandom(body_color.r * 566 + body_color.g * 4567 + body_color.b * 5321)
    local tail_hinge = 1
    if body_hinge > 1 then
        tail_hinge = G:next(G:next(1, body_hinge - 1), body_hinge - 1)
    end
    local tail_len = nv_fauna.hinges[tail_hinge][1]
    local tail_angle = G:next(0, 30)
    local attach_len = tail_len * math.cos(tail_angle * math.pi / 180)
    local attach_height = tail_len * math.sin(tail_angle * math.pi / 180)
    local tail_color = mod_color(mod_color(body_color))
    
    local tail_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d", tail_hinge))
    core.after(0, function()
        tail_entity:set_attach(body_entity, "LeafFixed", {x=-attach_len, y=-attach_height, z=0}, {x=0, y=0, z=tail_angle + 180}, false)
    end)
    tail_entity:set_texture_mod(color_to_mod(tail_color))
end

function decorate_body(body_entity, body_hinge, body_pos, body_color)
    local G = PcgRandom(body_color.r * 6531 + body_color.g * 656 + body_color.b * 11)
    -- Spikes
    if body_hinge >= 7 then
        local spike_count = G:next(0, 4)
        local spike_hinge = G:next(3, G:next(3, body_hinge - 1))
        local spike_length = nv_fauna.hinges[spike_hinge][1]
        local spike_width = nv_fauna.hinges[spike_hinge][3]
        local body_length = nv_fauna.hinges[body_hinge][1]
        local body_height = nv_fauna.hinges[body_hinge][2]
        local body_width = nv_fauna.hinges[body_hinge][3]
        for spike_i = 1, spike_count, 1 do
            local attach_x = (body_length - spike_width) * 0.8 * spike_i / spike_count + spike_width / 2
            local attach_y = body_height / 2 + spike_length / 2
            local attach_z = body_width / 4
            local spike_color = mod_color(mod_color(body_color))
            
            local spike_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d", spike_hinge))
            core.after(0, function()
                spike_entity:set_attach(body_entity, "", {x=-attach_x, y=attach_y, z=attach_z}, {x=-90, y=0, z=90}, false)
            end)
            spike_entity:set_texture_mod(color_to_mod(spike_color))
            
            local spike_entity2 = core.add_entity(body_pos, string.format("nv_fauna:hinge%d", spike_hinge))
            core.after(0, function()
                spike_entity2:set_attach(body_entity, "", {x=-attach_x, y=attach_y, z=-attach_z}, {x=90, y=0, z=90}, false)
            end)
            spike_entity2:set_texture_mod(color_to_mod(spike_color))
        end
    end
end

function decorate_head(head_entity, head_angle, head_hinge, body_pos, body_color)
    local G = PcgRandom(body_color.r * 6531 + body_color.g * 656 + body_color.b * 11)
    -- Eyes
    if head_hinge >= 2 then
        local head_length = nv_fauna.hinges[head_hinge][4]
        local head_height = nv_fauna.hinges[head_hinge][5]
        local head_width = nv_fauna.hinges[head_hinge][6]
        local attach_x = head_length / 2
        local attach_y = head_height / 2
        local attach_z = head_width / 4
        local eye_color = gen_color(head_angle)
        
        local eye_entity = core.add_entity(body_pos, "nv_fauna:hinge1")
        core.after(0, function()
            eye_entity:set_attach(head_entity, "LeafSwinging", {x=attach_x, y=attach_y, z=attach_z}, {x=0, y=0, z=90 - head_angle}, false)
        end)
        eye_entity:set_texture_mod(color_to_mod(eye_color))
        
        local eye_entity2 = core.add_entity(body_pos, "nv_fauna:hinge1")
        core.after(0, function()
            eye_entity2:set_attach(head_entity, "LeafSwinging", {x=attach_x, y=attach_y, z=-attach_z}, {x=0, y=0, z=90 - head_angle}, false)
        end)
        eye_entity2:set_texture_mod(color_to_mod(eye_color))
    end
    
    -- Antennae
    if head_hinge >= 3 and head_angle % 2 >= 1 then
        local head_length = nv_fauna.hinges[head_hinge][4]
        local head_height = nv_fauna.hinges[head_hinge][5]
        local head_width = nv_fauna.hinges[head_hinge][6]
        local attach_x = head_length / 4
        local attach_y = head_height / 2
        local attach_z = head_width / 4
        local antenna_color = mod_color(mod_color(mod_color(body_color)))
        
        local antenna_entity = core.add_entity(body_pos, "nv_fauna:hinge2")
        core.after(0, function()
            antenna_entity:set_attach(head_entity, "LeafSwinging", {x=attach_x, y=attach_y, z=attach_z}, {x=0, y=0, z=90 - head_angle}, false)
        end)
        antenna_entity:set_texture_mod(color_to_mod(antenna_color))
        
        local antenna_entity2 = core.add_entity(body_pos, "nv_fauna:hinge2")
        core.after(0, function()
            antenna_entity2:set_attach(head_entity, "LeafSwinging", {x=attach_x, y=attach_y, z=-attach_z}, {x=0, y=0, z=90 - head_angle}, false)
        end)
        antenna_entity2:set_texture_mod(color_to_mod(antenna_color))
    end
    
    -- Mouthpieces
    if head_hinge >= 3 and head_angle % 3 >= 1 then
        local mouth_hinge = G:next(1, head_hinge - 1)
        local head_length = nv_fauna.hinges[head_hinge][4]
        local head_height = nv_fauna.hinges[head_hinge][5]
        local head_width = nv_fauna.hinges[head_hinge][6]
        local mouth_length = nv_fauna.hinges[mouth_hinge][1]
        local mouth_angle = G:next(0, 45)
        local attach_x = head_length / 2
        local attach_len = mouth_length * math.sin(mouth_angle * math.pi / 180) * math.cos(head_angle * math.pi / 180)
        local attach_y = 0
        local attach_z = head_width / 4
        local mouth_color = mod_color(mod_color(mod_color(body_color)))
        
        local mouth_entity = core.add_entity(body_pos, "nv_fauna:hinge2")
        core.after(0, function()
            mouth_entity:set_attach(head_entity, "LeafSwinging", {x=attach_x + attach_len, y=attach_y, z=attach_z}, {x=90, y=mouth_angle, z=-head_angle}, false)
        end)
        mouth_entity:set_texture_mod(color_to_mod(mouth_color))
        
        local mouth_entity2 = core.add_entity(body_pos, "nv_fauna:hinge2")
        core.after(0, function()
            mouth_entity2:set_attach(head_entity, "LeafSwinging", {x=attach_x + attach_len, y=attach_y, z=-attach_z}, {x=-90, y=-mouth_angle, z=-head_angle}, false)
        end)
        mouth_entity2:set_texture_mod(color_to_mod(mouth_color))
    end
end

function nv_fauna.spawn_creature(pos, creature)
    local body_hinge = math.floor(creature.size * #nv_fauna.hinges + 1)
    local body_color = gen_color(creature.seed)
    local legs = gen_legs(creature, body_hinge)
    local leg_count = gen_leg_count(body_hinge, legs)
    if math.floor(leg_count / creature.less_legs) > 1 then
        leg_count = math.floor(leg_count / creature.less_legs)
    end

    local height = compute_leg_height(legs) / 10
    local body_pos = {x = pos.x, y = pos.y + height, z = pos.z}
    
    local body_entity = core.add_entity(body_pos, string.format("nv_fauna:hinge%d", body_hinge))
    local head_entity = body_entity
    local head_hinge = body_hinge
    local head_angle = 0
    body_entity:set_texture_mod(color_to_mod(body_color))
    decorate_body(body_entity, body_hinge, body_pos, body_color)
    local leg_entities = add_legs(body_entity, body_hinge, legs, leg_count, body_pos, body_color)
    if creature.has_neck then
        head_entity, head_angle, head_hinge = add_neck(body_entity, body_hinge, body_pos, body_color)
    end
    decorate_head(head_entity, head_angle, head_hinge, body_pos, body_color)
    if creature.has_tail then
        add_tail(body_entity, body_hinge, body_pos, body_color)
    end
    local creature = {
        body_entity = body_entity,
        leg_entities = leg_entities,
        height = height,
    }
    return creature
end
