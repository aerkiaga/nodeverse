--[[
NV Flora implements large flora for Nodeverse.

Included files:
    nodetypes.lua       Node definitions and registration

 # INDEX
]]--

nv_flora = {}

dofile(minetest.get_modpath("nv_flora") .. "/nodetypes.lua")

local function test_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet
)
    local x = minp.x
    local z = minp.z
    for y=minp.y,maxp.y do
        local i = area:index(x, y, z)
        A[i] = planet.node_types.stone
    end
end

local function test_handler(seed)
    return {{
        density = 1/100,
        side = 1,
        callback = test_callback
    }}
end

nv_planetgen.register_structure_handler(test_handler)
