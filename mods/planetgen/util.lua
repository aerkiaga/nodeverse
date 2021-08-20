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

function gen_linear_sum(generator, min, max, sum)
    r = 0
    for n=1, sum do
        r = r + gen_linear(generator, min, max)
    end
    return r
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
