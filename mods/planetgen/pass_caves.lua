--[[
This pass adds caves to the planet.
The basic algorithm is the following: each mapblock and face between mapblocks
gets a randomly placed 'center' within it. Each face is assigned either an
'open' or 'closed' status, and for each open face center and block center a
tunnel is made joining them, by means of radial Perlin noise.

 # INDEX
    ENTRY POINT
]]--

function pass_caves_check_block(side_seeds, block_minp, planet)
    local num_openings = 0
    for index=1, 6 do
        if side_seeds[index] ~= nil then num_openings = num_openings + 1 end
    end
    if num_openings > 1 then return true end
    return false
end

function pass_caves_generate_side_openings(side_seeds)
    -- Returns side opening shape noise generators
    local Perlin_2d_generic = function (index)
        return PerlinNoise({offset=0, scale=0.5, spread={x=10, y=10}, seed=side_seeds[index], octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    end

    return {
        (function () if side_seeds[1] ~= nil then return Perlin_2d_generic(1) else return nil end end) (),
        (function () if side_seeds[2] ~= nil then return Perlin_2d_generic(2) else return nil end end) (),
        (function () if side_seeds[3] ~= nil then return Perlin_2d_generic(3) else return nil end end) (),
        (function () if side_seeds[4] ~= nil then return Perlin_2d_generic(4) else return nil end end) (),
        (function () if side_seeds[5] ~= nil then return Perlin_2d_generic(5) else return nil end end) (),
        (function () if side_seeds[6] ~= nil then return Perlin_2d_generic(6) else return nil end end) ()
    }
end

function pass_caves_generate_side_opening_positions(generator_1, side_seeds, block_minp, planet)
    -- Returns side opening relative positions
    local generators = {
        generator_1,
        PcgRandom(planet.seed, block_minp.x/16*65771 + (block_minp.y/16 - 1)*56341 + block_minp.z/16*63427),
        PcgRandom(planet.seed, block_minp.x/16*65263 + block_minp.y/16*65825 + block_minp.z/16*54819),
        PcgRandom(planet.seed, (block_minp.x/16 - 1)*65263 + block_minp.y/16*65825 + block_minp.z/16*54819),
        PcgRandom(planet.seed, block_minp.x/16*65917 + block_minp.y/16*76827 + block_minp.z/16*65823),
        PcgRandom(planet.seed, block_minp.x/16*65917 + block_minp.y/16*76827 + (block_minp.z/16 - 1)*65823),
    }

    return {
        (function () if side_seeds[1] ~= nil then return {x=gen_linear(generators[1], 2, 13), y=gen_linear(generators[1], 2, 13)} else return nil end end) (),
        (function () if side_seeds[2] ~= nil then return {x=gen_linear(generators[2], 2, 13), y=gen_linear(generators[2], 2, 13)} else return nil end end) (),
        (function () if side_seeds[3] ~= nil then return {x=gen_linear(generators[3], 2, 13), y=gen_linear(generators[3], 2, 13)} else return nil end end) (),
        (function () if side_seeds[4] ~= nil then return {x=gen_linear(generators[4], 2, 13), y=gen_linear(generators[4], 2, 13)} else return nil end end) (),
        (function () if side_seeds[5] ~= nil then return {x=gen_linear(generators[5], 2, 13), y=gen_linear(generators[5], 2, 13)} else return nil end end) (),
        (function () if side_seeds[6] ~= nil then return {x=gen_linear(generators[6], 2, 13), y=gen_linear(generators[6], 2, 13)} else return nil end end) ()
    }
end

function pass_caves_generate_volume_noise(side_seeds)
    -- Returns tunnel noise generators
    local Perlin_3d_generic = function (index)
        return PerlinNoise({offset=0, scale=0.5, spread={x=10, y=10, z=10}, seed=int_hash(side_seeds[index]), octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
    end

    return {
        (function () if side_seeds[1] ~= nil then return Perlin_3d_generic(1) else return nil end end) (),
        (function () if side_seeds[2] ~= nil then return Perlin_3d_generic(2) else return nil end end) (),
        (function () if side_seeds[3] ~= nil then return Perlin_3d_generic(3) else return nil end end) (),
        (function () if side_seeds[4] ~= nil then return Perlin_3d_generic(4) else return nil end end) (),
        (function () if side_seeds[5] ~= nil then return Perlin_3d_generic(5) else return nil end end) (),
        (function () if side_seeds[6] ~= nil then return Perlin_3d_generic(6) else return nil end end) ()
    }
end

function pass_caves_calculate_side_contribution(side, relp, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
    -- Decide if a block is part of a tunnel connecting to a face (return > 0)
    -- First, compute position relative to opening
    opening_pos = {x=relp.x-side_position[side].x,y=relp.y-side_position[side].y}
    if side % 2 == 0 then
        opening_pos.z = relp.z
    else
        opening_pos.z = relp.z - 16
    end
    -- Then, compute radial noise contribution at opening
    modulo = vec2_modulo({x=opening_pos.x, y=opening_pos.y})
    if modulo == 0 then modulo = 0.00001 end
    unit_pos = {x=opening_pos.x/modulo, y=opening_pos.y/modulo}
    radialcontrib = (Perlin_2d_side[side]:get_2d(unit_pos) + 1) / 2
    max_radius = math.min(7.5 - math.abs(side_position[side].x - 7.5), 7.5 - math.abs(side_position[side].y - 7.5))
    radius = max_radius * radialcontrib
    opening_contrib = -(modulo - radius) / (math.abs(modulo - radius) + 1)

    -- Transform coordinates so volume_vector becomes (0, 0, 1)
    volume_vector = {x=side_position[side].x-center_pos.x, y=side_position[side].y-center_pos.y}
    if side % 2 == 0 then
        volume_vector.z = -center_pos.z
    else
        volume_vector.z = 16 - center_pos.z
    end
    -- b_rot = b a·k/|a| + axkxb/|a| + axk(axk·b)(1 - a·k/|a|)/|axk|^2
    a = volume_vector
    b = {x=relp.x-center_pos.x, y=relp.y-center_pos.y, z=relp.z-center_pos.z}
    k = {x=0, y=0, z=1}
    modulo_a = vec3_modulo(a)
    axk = vec3_cross_product(a, k)
    cosine = vec3_dot_product(a, k) / modulo_a
    comp_1 = vec3_scale(b, cosine)
    comp_2 = vec3_scale(vec3_cross_product(axk, b), 1/modulo_a)
    comp_3 = vec3_scale(axk, vec3_dot_product(axk, b) * (1 - cosine) / vec3_modulo(axk)^2)
    b_rot = {x=comp_1.x+comp_2.x+comp_3.x, y=comp_1.y+comp_2.y+comp_3.y, z=comp_1.z+comp_2.z+comp_3.z}

    -- Calculate contribution by volume
    modulo = vec2_modulo({x=b_rot.x, y=b_rot.y})
    if modulo == 0 then modulo = 0.00001 end
    unit_pos = {x=b_rot.x/modulo, y=b_rot.y/modulo, z=b_rot.z}
    radialcontrib = (Perlin_3d_side[side]:get_3d(unit_pos) + 1) / 2
    radialcontrib = radialcontrib ^ (1)
    max_radius = math.min(7.5 - math.abs(relp.x - 7.5), 7.5 - math.abs(relp.y - 7.5), 7.5 - math.abs(relp.z - 7.5))
    radius = max_radius * radialcontrib
    radius = radius * (1 + (b_rot.z - math.abs(b_rot.z))/6)^(1/3)
    if radius ~= radius or radius < 0 then radius = -0.1 end --NaN or negative
    volume_contrib = -(modulo - radius) / (math.abs(modulo - radius) + 1)
    if volume_contrib < -0.01 then volume_contrib = -0.01 end

    -- Weigh contributions
    opening_weight = (1 - math.abs(opening_pos.z)/16)^15
    volume_weight = 1 - opening_weight
    return opening_weight * opening_contrib + volume_weight * volume_contrib
end

function pass_caves_generate_block(block_minp, minp, maxp, area, A, A2, planet)
    local side_seeds = {
        int_hash(block_minp.x/16*65771 + block_minp.y/16*56341 + block_minp.z/16*63427),
        int_hash(block_minp.x/16*65771 + (block_minp.y/16 - 1)*56341 + block_minp.z/16*63427),
        int_hash(block_minp.x/16*65263 + block_minp.y/16*65825 + block_minp.z/16*54819),
        int_hash((block_minp.x/16 - 1)*65263 + block_minp.y/16*65825 + block_minp.z/16*54819),
        int_hash(block_minp.x/16*65917 + block_minp.y/16*76827 + block_minp.z/16*65823),
        int_hash(block_minp.x/16*65917 + block_minp.y/16*76827 + (block_minp.z/16 - 1)*65823),
    }

    -- Delete a fixed proportion of side openings, depending on planet and depth
    -- The less openings, the less connected and large the caves will be
    -- At a certain threshold, cave size tends to infinity:
    --[[
    "In the simple cubic lattice, for bond-percolation our Monte Carlo
    simulation gives a value of p∞ = 0.2492 ± 0.0002, [...]"

    S. Wilke 1983 "Bond percolation threshold in the simple cubic lattice"
    ]]--
    caveness = planet.caveness
    if block_minp.y < -16*4 then caveness = caveness / 4
    elseif block_minp.y < -16*2 then caveness = caveness ^ (1/4)
    end
    for key, value in pairs(side_seeds) do
        if gen_true_with_probability(PcgRandom(planet.seed, value), 1 - caveness) then
            side_seeds[key] = nil
        end
    end

    if not pass_caves_check_block(side_seeds, block_minp, planet) then return end

    -- Generate side opening shape noise generators
    local Perlin_2d_side = pass_caves_generate_side_openings(side_seeds)

    -- Generate side opening positions
    local generator_1 = PcgRandom(planet.seed, block_minp.x/16*65771 + block_minp.y/16*56341 + block_minp.z/16*63427)
    local side_position = pass_caves_generate_side_opening_positions(generator_1, side_seeds, block_minp, planet)

    -- Generate center position
    local center_pos = {
        x=gen_linear(generator_1, 4, 11),
        y=gen_linear(generator_1, 4, 11),
        z=gen_linear(generator_1, 4, 11)
    }

    -- Generate volume noise generators
    local Perlin_3d_side = pass_caves_generate_volume_noise(side_seeds)

    -- APPLY
    for z=minp.z, maxp.z do
        for x=minp.x, maxp.x do
            for y=minp.y, maxp.y do
                repeat
                    local truth = false

                    -- Don't touch some nodes
                    local i = area:index(x, y, z)
                    if A[i] == minetest.CONTENT_AIR or A[i] == planet.node_types.sediment or A[i] == planet.node_types.liquid then
                        do break end
                    end
                    if A[i] == planet.node_types.grass or A[i] == planet.node_types.dry_grass or A[i] == planet.node_types.tall_grass then
                        A[i] = minetest.CONTENT_AIR
                        do break end
                    end

                    -- Logical OR tunnels from center to all faces
                    -- Side +Y
                    if side_seeds[1] ~= nil and not truth then
                        contrib = pass_caves_calculate_side_contribution(1, {x=x-block_minp.x, y=z-block_minp.z, z=y-block_minp.y}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > 0)
                    end
                    -- Side -Y
                    if side_seeds[2] ~= nil and not truth then
                        contrib = pass_caves_calculate_side_contribution(2, {x=x-block_minp.x, y=z-block_minp.z, z=y-block_minp.y}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > 0)
                    end
                    -- Side +X
                    if side_seeds[3] ~= nil and not truth then
                        contrib = pass_caves_calculate_side_contribution(3, {x=y-block_minp.y, y=z-block_minp.z, z=x-block_minp.x}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > 0)
                    end
                    -- Side -X
                    if side_seeds[4] ~= nil and not truth then
                        contrib = pass_caves_calculate_side_contribution(4, {x=y-block_minp.y, y=z-block_minp.z, z=x-block_minp.x}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > 0)
                    end
                    -- Side +Z
                    if side_seeds[5] ~= nil and not truth then
                        contrib = pass_caves_calculate_side_contribution(5, {x=x-block_minp.x, y=y-block_minp.y, z=z-block_minp.z}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > 0)
                    end
                    -- Side -Z
                    if side_seeds[6] ~= nil and not truth then
                        contrib = pass_caves_calculate_side_contribution(6, {x=x-block_minp.x, y=y-block_minp.y, z=z-block_minp.z}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > 0)
                    end
                    if truth then A[i] = minetest.CONTENT_AIR end
                until true
            end
        end
    end
end

--[[
 # ENTRY POINT
]]--

function pass_caves(minp, maxp, area, A, A2, planet)
    -- Start xyz of block to generate
    -- Can be lower than start xyz of generated area
    block_minp = {x=minp.x-minp.x%16, y=minp.y-minp.y%16, z=minp.z-minp.z%16}
    while block_minp.z <= maxp.z do
        while block_minp.y <= maxp.y do
            while block_minp.x <= maxp.x do
                -- Bounds of block or block fragment to generate
                common_minp = {
                    x=math.max(minp.x, block_minp.x),
                    y=math.max(minp.y, block_minp.y),
                    z=math.max(minp.z, block_minp.z)
                }
                common_maxp = {
                    x=math.min(maxp.x, block_minp.x+15),
                    y=math.min(maxp.y, block_minp.y+15),
                    z=math.min(maxp.z, block_minp.z+15)
                }
                pass_caves_generate_block(block_minp, common_minp, common_maxp, area, A, A2, planet)
                block_minp.x = block_minp.x+16
            end
            block_minp.x = minp.x-minp.x%16
            block_minp.y = block_minp.y+16
        end
        block_minp.y = minp.y-minp.y%16
        block_minp.z = block_minp.z+16
    end
end
