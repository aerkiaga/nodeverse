--[[
This pass adds caves to the planet.
The basic algorithm is the following: each face between mapblocks is assigned
either an 'open' or 'closed' status. The mapblock has a 'threshold' at each
node, that is higher near its 'closed' faces. Then, 3D Perlin Noise is generated
and nodes where the noise value is higher than their threshold are convrted into
air if their type is suitable. Nodes that should not lie over open air are
assigned a higher threshold.

 # INDEX
    ENTRY POINT
]]--

function caves_check_block(sides)
    local num_openings = 0
    for index=1, 6 do
        if sides[index] then num_openings = num_openings + 1 end
    end
    return num_openings > 1
end

caves_def_threshold_buffer = {}

function caves_init_def_threshold_buffer()
    local k = 1
    local buffer = caves_def_threshold_buffer
    for z_rel=0, 15 do
        local z_wall = z_rel == 0 or z_rel == 15
        local z_near_wall = z_rel < 4 or z_rel > 11
        for y_rel=0, 15 do
            local y_wall = z_wall or y_rel == 0 or y_rel == 15
            local y_near_wall = z_near_wall or y_rel < 4 or y_rel > 11
            for x_rel=0, 15 do
                local x_wall = y_wall or x_rel == 0 or x_rel == 15
                local x_near_wall = y_near_wall or x_rel < 4 or x_rel > 11
                if x_wall then
                    buffer[k] = 0.7
                elseif x_near_wall then
                    buffer[k] = 0.2
                else
                    buffer[k] = 0
                end
                k = k + 1
            end
        end
    end
end

caves_threshold_buffer = {}

caves_const_boxes = {
    {minp = {x=15, y=0, z=0}, maxp = {x=15, y=15, z=15}}, -- X+
    {minp = {x=0, y=15, z=0}, maxp = {x=15, y=15, z=15}}, -- Y+
    {minp = {x=0, y=0, z=15}, maxp = {x=15, y=15, z=15}}, -- Z+
    {minp = {x=0, y=0, z=0}, maxp = {x=0, y=15, z=15}}, -- X-
    {minp = {x=0, y=0, z=0}, maxp = {x=15, y=0, z=15}}, -- Y-
    {minp = {x=0, y=0, z=0}, maxp = {x=15, y=15, z=0}}, -- Z-
}

function caves_set_threshold_buffer_box(box, value)
    local buffer = caves_threshold_buffer
    local minp_x, minp_y, minp_z = box.minp.x, box.minp.y, box.minp.z
    local maxp_x, maxp_y, maxp_z = box.maxp.x, box.maxp.y, box.maxp.z
    for z_rel=minp_z, maxp_z do
        for y_rel=minp_y, maxp_y do
            for x_rel=minp_x, maxp_x do
                local k = 256*z_rel + 16*y_rel + x_rel + 1
                buffer[k] = value
            end
        end
    end
end

function caves_gen_threshold_buffer(sides)
    if #caves_def_threshold_buffer == 0 then
        caves_init_def_threshold_buffer()
    end
    local src_buffer = caves_def_threshold_buffer
    local buffer = caves_threshold_buffer
    for k = 1, 4096 do
        buffer[k] = src_buffer[k]
    end
    for index, value in ipairs(sides) do
        if value then
            local box = caves_const_boxes[index]
            caves_set_threshold_buffer_box(box, 0.2)
        end
    end
end

caves_3d_buffer = {}

function caves_gen_block(
    block_minp_abs, minp_abs, maxp_abs, offset, area, A, A2, noise, planet
)
    local block_minp = vec3_add(block_minp_abs, offset)
    local sides = {}

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
    for n=1, 6 do
        local n2 = ((n - 1) % 3) + 1
        local block_minp2 = {x=block_minp.x, y=block_minp.y, z=block_minp.z}
        -- Make sure that matching faces have the same value
        if n == 4 then block_minp2.x = block_minp2.x - 16
        elseif n == 5 then block_minp2.y = block_minp2.y - 16
        elseif n == 6 then block_minp2.z = block_minp2.z - 16
        end
        local seed = block_minp2.x%0x10000 + block_minp2.y%0x100 + block_minp2.z
        sides[n] = gen_true_with_probability(PcgRandom(planet.seed + seed, n2 + seed), 1 - caveness)
    end

    if not caves_check_block(sides) then
        return
    end

    caves_gen_threshold_buffer(sides)

    noise:get_3d_map_flat(block_minp, caves_3d_buffer)

    local k = 1
    for z_abs=minp_abs.z, maxp_abs.z do
        for y_abs=minp_abs.y, maxp_abs.y do
            for x_abs=minp_abs.x, maxp_abs.x do
                local i = area:index(x_abs, y_abs, z_abs)
                local Ai = A[i]

                if Ai == minetest.CONTENT_AIR
                or Ai == planet.node_types.sediment
                or Ai == planet.node_types.liquid then else
                    local threshold = caves_threshold_buffer[k]
                    if Ai == planet.node_types.grass
                    or Ai == planet.node_types.dry_grass
                    or Ai == planet.node_types.tall_grass then
                        threshold = threshold - 0.2
                    end
                    if caves_3d_buffer[k] > threshold then
                        A[i] = minetest.CONTENT_AIR
                    end
                end

                k = k + 1
            end
        end
    end
end

function caves_init_noise(planet)
    return PerlinMapWrapper (
        {
            offset=0, scale=0.5, spread={x=8, y=8, z=8}, seed=planet.seed,
            octaves=2, persist=0.5, lacunarity=2.0, flags="defaults"
        },
        {x=16, y=16, z=16}
    )
end

--[[
 # ENTRY POINT
]]--

function pass_caves(minp_abs, maxp_abs, area, offset, A, A2, planet)
    --local noise = caves_init_noise(planet)
    local noise = caves_init_noise(planet)

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
                --caves_gen_block(
                    --block_minp, common_minp, common_maxp, area, offset, A, A2, noise, planet
                --)
                caves_gen_block(
                    block_minp, common_minp, common_maxp, offset, area, A, A2, noise, planet
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
