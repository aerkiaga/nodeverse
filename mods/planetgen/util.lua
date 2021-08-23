--[[
Here are defined all distribution generators and math utilities used by other
parts of the code, as well as other functions.

 # INDEX
    DISTRIBUTIONS
    VECTOR MATH
    NOISE
]]

function table_copy(tab)
    local r = {}
    for key, value in pairs(tab) do
        r[key] = value
    end
    return r
end

profile_times = {}

function profile_start(name) --
    profile_times[name] = minetest.get_us_time()
end

function profile_end(name) --
    if profile_times[name] == nil then
        print(string.format("Profiling not started: %s", name))
        return
    end
    local time = minetest.get_us_time() - profile_times[name]
    print(string.format("%s %d", name, time))
end

function int_hash(value)
    return tonumber(minetest.sha1(value):sub(0, 8), 16)
end

--[[
 # DISTRIBUTIONS
]]

function gen_true_with_probability(generator, P)
    return generator:next(0, 65535)/65536 < P
end

function gen_linear(generator, min, max)
    return generator:next(0, 65535)/65536 * (max-min) + min
end

function gen_linear_sum(generator, min, max, sum)
    local r = 0
    for n=1, sum do
        r = r + gen_linear(generator, min, max)
    end
    return r
end

function gen_weighted(generator, options)
    local total_weight = 0
    for i, v in pairs(options) do
        total_weight = total_weight + v
    end
    local value = gen_linear(generator, 0, total_weight)
    for i, v in pairs(options) do
        value = value - v
        if value <= 0 then
            return i
        end
    end
end

--[[
 # VECTOR MATH
]]

function vec2_modulo(v)
    return math.sqrt(v.x^2 + v.y^2)
end

function vec3_modulo(v)
    return math.sqrt(v.x^2 + v.y^2 + v.z^2)
end

function vec3_scale(v, a)
    return {
        x = a * v.x,
        y = a * v.y,
        z = a * v.z
    }
end

function vec3_add(v1, v2)
    return {
        x = v1.x + v2.x,
        y = v1.y + v2.y,
        z = v1.z + v2.z
    }
end

function vec3_dot_product(v1, v2)
    return v1.x * v2.x + v1.y + v2.y + v1.z + v2.z
end

function vec3_cross_product(v1, v2)
    return {
        x = v1.y * v2.z - v1.z * v2.y,
        y = v1.z * v2.x - v1.x * v2.z,
        z = v1.x * v2.y - v1.y * v2.x
    }
end

function vec3_apply_matrix(v, M)
    return {
        x = M[1][1]*v.x + M[1][2]*v.y + M[1][3]*v.z,
        y = M[2][1]*v.x + M[2][2]*v.y + M[2][3]*v.z,
        z = M[3][1]*v.x + M[3][2]*v.y + M[3][3]*v.z
    }
end

function vec3_rotate(v, theta, axis)
    -- Uses radians!
    axis = vec3_scale(axis, 1/vec3_modulo(axis))
    return vec3_apply_matrix(v, {
        {
            math.cos(theta) + axis.x^2*(1 - math.cos(theta)),
            axis.x*axis.y*(1 - math.cos(theta)) - axis.z*math.sin(theta),
            axis.x*axis.z*(1 - math.cos(theta)) + axis.y*math.sin(theta)
        },
        {
            axis.y*axis.x*(1 - math.cos(theta)) + axis.z*math.sin(theta),
            math.cos(theta) + axis.y^2*(1 - math.cos(theta)),
            axis.y*axis.z*(1 - math.cos(theta)) - axis.x*math.sin(theta)
        },
        {
            axis.z*axis.x*(1 - math.cos(theta)) - axis.y*math.sin(theta),
            axis.z*axis.y*(1 - math.cos(theta)) - axis.x*math.sin(theta),
            math.cos(theta) + axis.z^2*(1 - math.cos(theta)),
        }
    })
end

--[[
 # NOISE
]]

perlin_generators = {}

function PerlinWrapper(noiseparams)
    local generator = nil
    for key, value in pairs(perlin_generators) do
        if key.offset == noiseparams.offset
        and key.scale == noiseparams.scale
        and key.spread == noiseparams.spread
        and key.octaves == noiseparams.octaves
        and key.persistence == noiseparams.persistence
        and key.lacunarity == noiseparams.lacunarity then
            generator = value
        end
    end
    if generator == nil then
        local noiseparams2 = table_copy(noiseparams)
        noiseparams2.seed = 0
        generator = PerlinNoise(noiseparams2)
        perlin_generators[noiseparams2] = generator
    end
    local x_offset = noiseparams.seed % 0x10000 - 0x8000
    local y_offset = noiseparams.seed % 0x1000 - 0x800
    local z_offset = noiseparams.seed % 0x100 - 0x80
    return {
        get_2d = function (self, pos)
            pos = {x=pos.x-x_offset, y=pos.y-y_offset}
            return generator:get_2d(pos)
        end,
        get_3d = function (self, pos)
            pos = {x=pos.x-x_offset, y=pos.y-y_offset, z=pos.z-z_offset}
            return generator:get_3d(pos)
        end
    }
end

perlin_map_generators = {}

function PerlinMapWrapper(noiseparams, size)
    local generator = nil
    for key, value in pairs(perlin_map_generators) do
        if key[1].offset == noiseparams.offset
        and key[1].scale == noiseparams.scale
        and key[1].spread == noiseparams.spread
        and key[1].octaves == noiseparams.octaves
        and key[1].persistence == noiseparams.persistence
        and key[1].lacunarity == noiseparams.lacunarity
        and key[2].x == size.x
        and key[2].y == size.y
        and key[2].z == size.z then
            generator = value
        end
    end
    if generator == nil then
        local noiseparams2 = table_copy(noiseparams)
        noiseparams2.seed = 0
        generator = PerlinNoiseMap(noiseparams2, size)
        perlin_map_generators[{noiseparams2, size}] = generator
    end
    local x_offset = noiseparams.seed % 0x12000 - 0x7000
    local y_offset = noiseparams.seed % 0x1200 - 0x700
    local z_offset = noiseparams.seed % 0x120 - 0x70
    return {
        get_2d_map_flat = function (self, pos, buffer)
            pos = {x=pos.x-x_offset, y=pos.y-y_offset}
            return generator:get_2d_map_flat(pos, buffer)
        end,
        get_3d_map_flat = function (self, pos, buffer)
            pos = {x=pos.x-x_offset, y=pos.y-y_offset, z=pos.z-z_offset}
            return generator:get_3d_map_flat(pos, buffer)
        end
    }
end
