--[[
This pass adds structures (e.g. trees, buildings) that can be configured
from other mods.

 # INDEX
    EXTERNAL API
    ENTRY POINT
]]

--[[
 # EXTERNAL API
]]--

--[[
Structure format:
    density     average density of this structure in the world (scaled by structure size)
    seed        unique seed for structure placing
    side        horizontal width of the structure as a square
    order       structures with a lower order floating point value will be created earlier
    callback    function (origin, minp, maxp, area, A, A1, A2, mapping)
    Will be passed the extents of the structure area, as well as objects useful
    for creating the structure. Note that the given area may overlap with any
    existing structures, including of the same type. This function might choose
    not to overwrite anything if it can't identify empty space.
        origin      minimum x and z coordinates of the actual structure (not its center)
        minp        starting x, y and z node coordinates of the chunk to generate
        maxp        ending x, y and z node coordinates of the chunk to generate
        Note that the structure is a vertically infinite square prism, and only
        a bounded portion of it is generated at a time, so the callback should
        be able to generate any part of the structure, no matter how small.
        area        value returned by Minetest's 'VoxelArea:new()'
        A           value returned by Minetest's 'VoxelManip:get_data()'
        A1          value returned by Minetest's 'VoxelManip:get_light_data()'
        A2          value returned by Minetest's 'VoxelManip:get_param2_data()'
        mapping     planet mapping
        planet      planet metadata
        custom      custom data from the structure definition
    custom      custom data to pass to the callback function
]]--

local registered_structures = {}
local function register_structure(seed, def)
    registered_structures[seed] = registered_structures[seed] or {}
    for n, structure in ipairs(registered_structures[seed]) do
        if structure.order > def.order then
            table.insert(registered_structures[seed], n, def)
            break
        end
    end
    table.insert(registered_structures[seed], def)
end

local structure_handlers = {}
-- The callback will get a seed and must return a list of structures
function nv_planetgen.register_structure_handler(callback)
    table.insert(structure_handlers, callback)
end

local function get_registered_structures(seed)
    registered_structures[seed] = {}
    for _, callback in ipairs(structure_handlers) do
        local structures = callback(seed)
        for _, structure in ipairs(structures) do
            register_structure(seed, structure)
        end
    end
end

--[[
 # ENTRY POINT
]]--

function nv_planetgen.pass_structures(
    minp_abs, maxp_abs, area, offset, A, A1, A2, mapping, planet, ground_buffer
)
    local seed = mapping.seed
    if registered_structures[seed] == nil then
        get_registered_structures(seed)
    end
    for _, structure in ipairs(registered_structures[seed]) do
        local test_minx = minp_abs.x - structure.side
        local test_minz = minp_abs.z - structure.side
        local test_maxx = maxp_abs.x
        local test_maxz = maxp_abs.z
        local test_step = math.max(math.floor(structure.side / 10), 1)
        local test_prob = structure.density * test_step^2 / structure.side^2
        for test_z=test_minz,test_maxz,test_step do
            local planet_z = test_z + mapping.offset.z
            for test_x=test_minx,test_maxx,test_step do
                local planet_x = test_x + mapping.offset.x
                local G = PcgRandom(planet.seed + structure.seed, planet_x + planet_z * 1749)
                if gen_linear(G, 0, 1) < test_prob then
                    local origin = {x=test_x, z=test_z}
                    local minp = {
                        x = math.max(test_x, minp_abs.x),
                        y = minp_abs.y,
                        z = math.max(test_z, minp_abs.z)
                    }
                    local maxp = {
                        x = math.min(test_x + structure.side, maxp_abs.x),
                        y = maxp_abs.y,
                        z = math.min(test_z + structure.side, maxp_abs.z)
                    }
                    structure.callback(
                        origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, structure.custom
                    )
                end
            end
        end
    end
end
