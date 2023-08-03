--[[
NV Flora implements large flora for Nodeverse.

Included files:

 # INDEX
]]--

nv_flora = {}

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

nv_planetgen.register_structure({
    density = 1/100,
    side = 1,
    callback = test_callback
})
