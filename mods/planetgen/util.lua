--[[
Here are defined all distribution generators and math utilities used by other
parts of the code.

 # INDEX
    DISTRIBUTIONS
    VECTOR MATH
]]

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

function gen_weighted(generator, options)
    total_weight = 0
    for i, v in pairs(options) do
        total_weight = total_weight + v
    end
    value = gen_linear(generator, 0, total_weight)
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

function vec3_scale(v, a)
    return {
        x = a * v.x,
        y = a * v.y,
        z = a * v.z
    }
end
