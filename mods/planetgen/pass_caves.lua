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

function pass_caves_generate_side_openings(side_seeds, noise)
    -- Returns side opening shape noise generators
    local Perlin_2d_generic = function (index)
        --return PerlinNoise({offset=0, scale=0.5, spread={x=10, y=10}, seed=side_seeds[index], octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
        local noise_seed = side_seeds[index]
        return {
            get_2d = function (self, pos)
                pos = {
                    x=(pos.x + noise_seed) % 0x100000,
                    y=(pos.y - math.floor(noise_seed/3)) % 0x100000,
                }
                return noise.side:get_2d(pos)
            end
        }
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

function pass_caves_generate_volume_noise(side_seeds, noise)
    -- Returns tunnel noise generators
    local Perlin_3d_generic = function (index)
        --return PerlinNoise({offset=0, scale=0.5, spread={x=10, y=10, z=10}, seed=int_hash(side_seeds[index]), octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"})
        local noise_seed = int_hash(side_seeds[index])
        return {
            get_3d = function (self, pos)
                pos = {
                    x=(pos.x - noise_seed) % 0x100000,
                    y=(pos.y + math.floor(noise_seed/2)) % 0x100000,
                    z=(pos.z + noise_seed*3) % 0x100000
                }
                return noise.volume:get_3d(pos)
            end
        }
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

function pass_caves_calculate_side_contribution(
    side, relp, Perlin_2d_side, side_position, center_pos, Perlin_3d_side
)
    -- Decide if a block is part of a tunnel connecting to a face (return > 0)
    -- First, compute position relative to opening
    local opening_pos = {x=relp.x-side_position[side].x,y=relp.y-side_position[side].y}
    if side % 2 == 0 then
        opening_pos.z = relp.z
    else
        opening_pos.z = relp.z - 16
    end
    -- Then, compute radial noise contribution at opening
    local modulo = vec2_modulo({x=opening_pos.x, y=opening_pos.y})
    if modulo == 0 then modulo = 0.00001 end
    local unit_pos = {x=opening_pos.x/modulo, y=opening_pos.y/modulo}
    local radialcontrib = (Perlin_2d_side[side]:get_2d(unit_pos) + 1) / 2
    local max_radius = math.min(7.5 - math.abs(side_position[side].x - 7.5), 7.5 - math.abs(side_position[side].y - 7.5))
    local radius = max_radius * radialcontrib
    local opening_contrib = -(modulo - radius) / (math.abs(modulo - radius) + 1)

    -- Transform coordinates so volume_vector becomes (0, 0, 1)
    local volume_vector = {x=side_position[side].x-center_pos.x, y=side_position[side].y-center_pos.y}
    if side % 2 == 0 then
        volume_vector.z = -center_pos.z
    else
        volume_vector.z = 16 - center_pos.z
    end
    -- b_rot = b a·k/|a| + axkxb/|a| + axk(axk·b)(1 - a·k/|a|)/|axk|^2
    local a = volume_vector
    local b = {x=relp.x-center_pos.x, y=relp.y-center_pos.y, z=relp.z-center_pos.z}
    local k = {x=0, y=0, z=1}
    local modulo_a = vec3_modulo(a)
    local axk = vec3_cross_product(a, k)
    local cosine = vec3_dot_product(a, k) / modulo_a
    local comp_1 = vec3_scale(b, cosine)
    local comp_2 = vec3_scale(vec3_cross_product(axk, b), 1/modulo_a)
    local comp_3 = vec3_scale(axk, vec3_dot_product(axk, b) * (1 - cosine) / vec3_modulo(axk)^2)
    local b_rot = {x=comp_1.x+comp_2.x+comp_3.x, y=comp_1.y+comp_2.y+comp_3.y, z=comp_1.z+comp_2.z+comp_3.z}

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
    local volume_contrib = -(modulo - radius) / (math.abs(modulo - radius) + 1)
    if volume_contrib < -0.01 then volume_contrib = -0.01 end

    -- Weigh contributions
    local opening_weight = (1 - math.abs(opening_pos.z)/16)^15
    local volume_weight = 1 - opening_weight
    return opening_weight * opening_contrib + volume_weight * volume_contrib
end

function pass_caves_generate_block(
    block_minp_abs, minp_abs, maxp_abs, area, offset, A, A2, noise, planet
)
    local block_minp = vec3_add(block_minp_abs, offset)
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
    local caveness = planet.caveness
    if block_minp.y < -16*4 then caveness = caveness / 4
    elseif block_minp.y < -16*2 then caveness = caveness ^ (1/4)
    end
    for key, value in pairs(side_seeds) do
        if gen_true_with_probability(PcgRandom(planet.seed, value), 1 - caveness) then
            side_seeds[key] = nil
        end
    end

    if not pass_caves_check_block(side_seeds, block_minp, noise, planet) then return end

    -- Generate side opening shape noise generators
    local Perlin_2d_side = pass_caves_generate_side_openings(side_seeds, noise)

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
    local Perlin_3d_side = pass_caves_generate_volume_noise(side_seeds, noise)

    -- APPLY
    for z_abs=minp_abs.z, maxp_abs.z do
        local z = z_abs + offset.z
        for x_abs=minp_abs.x, maxp_abs.x do
            local x = x_abs + offset.x
            for y_abs=minp_abs.y, maxp_abs.y do
                local y = y_abs + offset.y
                repeat
                    local truth = false
                    local rel_x = x-block_minp.x
                    local rel_y = y-block_minp.y
                    local rel_z = z-block_minp.z

                    -- Don't touch some nodes
                    local i = area:index(x_abs, y_abs, z_abs)
                    if A[i] == minetest.CONTENT_AIR or A[i] == planet.node_types.sediment or A[i] == planet.node_types.liquid then
                        do break end
                    end
                    if A[i] == planet.node_types.grass or A[i] == planet.node_types.dry_grass or A[i] == planet.node_types.tall_grass or A[i] == planet.node_types.snow then
                        rel_y = rel_y - 1
                    end

                    local threshold = 0

                    -- Logical OR tunnels from center to all faces
                    -- Side +Y
                    if side_seeds[1] ~= nil and not truth then
                        local contrib = pass_caves_calculate_side_contribution(1, {x=rel_x, y=rel_z, z=rel_y}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > threshold)
                    end
                    -- Side -Y
                    if side_seeds[2] ~= nil and not truth then
                        local contrib = pass_caves_calculate_side_contribution(2, {x=rel_x, y=rel_z, z=rel_y}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > threshold)
                    end
                    -- Side +X
                    if side_seeds[3] ~= nil and not truth then
                        local contrib = pass_caves_calculate_side_contribution(3, {x=rel_y, y=rel_z, z=rel_x}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > threshold)
                    end
                    -- Side -X
                    if side_seeds[4] ~= nil and not truth then
                        local contrib = pass_caves_calculate_side_contribution(4, {x=rel_y, y=rel_z, z=rel_x}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > threshold)
                    end
                    -- Side +Z
                    if side_seeds[5] ~= nil and not truth then
                        local contrib = pass_caves_calculate_side_contribution(5, {x=rel_x, y=rel_y, z=rel_z}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > threshold)
                    end
                    -- Side -Z
                    if side_seeds[6] ~= nil and not truth then
                        local contrib = pass_caves_calculate_side_contribution(6, {x=rel_x, y=rel_y, z=rel_z}, Perlin_2d_side, side_position, center_pos, Perlin_3d_side)
                        truth = truth or (contrib > threshold)
                    end
                    if truth then A[i] = minetest.CONTENT_AIR end
                until true
            end
        end
    end
end

function pass_caves_init_noise(planet)
    return {
        side = PerlinNoise({
            offset=0, scale=0.5, spread={x=10, y=10}, seed=planet.seed,
            octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"
        }),
        volume = PerlinNoise({
            offset=0, scale=0.5, spread={x=10, y=10, z=10}, seed=planet.seed,
            octaves=3, persist=0.5, lacunarity=2.0, flags="defaults"
        })
    }
end

--[[
 # ENTRY POINT
]]--

function pass_caves(minp_abs, maxp_abs, area, offset, A, A2, planet)
    local noise = pass_caves_init_noise(planet)

    -- Start xyz of block to generate
    -- Can be lower than start xyz of generated area
    local block_minp = {x=minp_abs.x-minp_abs.x%16, y=minp_abs.y-minp_abs.y%16, z=minp_abs.z-minp_abs.z%16}
    while block_minp.z <= maxp_abs.z do
        while block_minp.y <= maxp_abs.y do
            while block_minp.x <= maxp_abs.x do
                -- Bounds of block or block fragment to generate
                local common_minp = {
                    x=math.max(minp_abs.x, block_minp.x),
                    y=math.max(minp_abs.y, block_minp.y),
                    z=math.max(minp_abs.z, block_minp.z)
                }
                local common_maxp = {
                    x=math.min(maxp_abs.x, block_minp.x+15),
                    y=math.min(maxp_abs.y, block_minp.y+15),
                    z=math.min(maxp_abs.z, block_minp.z+15)
                }
                pass_caves_generate_block(
                    block_minp, common_minp, common_maxp, area, offset, A, A2, noise, planet
                )
                block_minp.x = block_minp.x+16
            end
            block_minp.x = minp_abs.x-minp_abs.x%16
            block_minp.y = block_minp.y+16
        end
        block_minp.y = minp_abs.y-minp_abs.y%16
        block_minp.z = block_minp.z+16
    end
end
