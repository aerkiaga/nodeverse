--[[
NV Flora implements large flora for Nodeverse.

Included files:
    nodetypes.lua       Node definitions and registration

 # INDEX
]]--

nv_flora = {}

dofile(minetest.get_modpath("nv_flora") .. "/nodetypes.lua")

local function cane_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer
)
    local x = minp.x
    local z = minp.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local k = (z - base.z) * extent.x + x - base.x + 1
    if k > #ground_buffer then
        return
    end
    local ground = math.floor(ground_buffer[k])
    if ground < -1 or ground > 1 then
        return
    end
    local grass_height = 3 + math.floor((x % 4) / 2 - 0.5)
    local yrot = (x * 23 + z * 749) % 24
    for y=maxp.y,minp.y,-1 do
        if y + mapping.offset.y < ground + 1 + grass_height then
            local i = area:index(x, y, z)
            local replaceable
            if A[i] == nil or A[i] == minetest.CONTENT_AIR then
                replaceable = true
            else
                local buildable = minetest.registered_nodes[minetest.get_name_from_content_id(A[i])].buildable_to
                if buildable == nil then
                    buildable = false
                end
                replaceable = buildable
            end
            if replaceable then
                A[i] = nv_flora.node_types.tall_grasses[mapping.seed % 6 + 1]
                A2[i] = yrot
            end
        elseif y + mapping.offset.y < ground then
            break
        end
    end
end

local function cane_handler(seed)
    local G = PcgRandom(seed, seed)
    return {{
        density = 1/(G:next(2, 20)^2),
        side = 1,
        callback = cane_callback
    }}
end

nv_planetgen.register_structure_handler(cane_handler)
