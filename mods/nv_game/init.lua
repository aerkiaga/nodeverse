--[[
NV Game adds playable content to Nodeverse. It's the top-level mod that depends
on other NV mods. 

 # INDEX
    MAPGEN SETUP
    SHIPS SETUP
]]--

dofile(minetest.get_modpath("nv_game") .. "/nodetypes.lua")

--[[
 # MAPGEN SETUP
]]

local block_size = 300
local planets_per_block = 4
local planet_size = 60

local function new_area_callback(minp, maxp, area, A, A1, A2)
    local max = math.max
    local min = math.min
    local ceil = math.ceil
    local floor = math.floor
    local minpx, minpy, minpz = minp.x, minp.y, minp.z
    local maxpx, maxpy, maxpz = maxp.x, maxp.y, maxp.z
    -- Iterate over all overlapping block_size * block_size * block_size blocks
    for block_x=minpx - minpx%block_size, maxpx - maxpx%block_size, block_size do
        for block_y=minpy - minpy%block_size, maxpy - maxpy%block_size, block_size do
            for block_z=minpz - minpz%block_size, maxpz - maxpz%block_size, block_size do
                -- Get overlapping area
                local common_minp = {
                    x=max(minpx, block_x),
                    y=max(minpy, block_y),
                    z=max(minpz, block_z)
                }
                local common_maxp = {
                    x=min(maxpx, block_x + block_size - 1),
                    y=min(maxpy, block_y + block_size - 1),
                    z=min(maxpz, block_z + block_size - 1)
                }
                -- Check overlap with randomly placed planets
                local seed = block_x + 0x10*block_y + 0x1000*block_z + 464646
                local G = PcgRandom(seed, seed)
                for n=1, planets_per_block do
                    local planet_pos = {
                        x=block_x + G:next(ceil(planet_size/2), block_size - ceil(planet_size/2)),
                        y=block_y + G:next(ceil(planet_size/2), block_size - ceil(planet_size/2)),
                        z=block_z + G:next(ceil(planet_size/2), block_size - ceil(planet_size/2))
                    }
                    local planet_mapping = {
                        minp = {
                            x=planet_pos.x - floor(planet_size/2),
                            y=planet_pos.y - 4*floor(planet_size/2),
                            z=planet_pos.z - floor(planet_size/2),
                        },
                        maxp = {
                            x=planet_pos.x + floor(planet_size/2),
                            y=planet_pos.y + 4*floor(planet_size/2),
                            z=planet_pos.z + floor(planet_size/2),
                        }
                    }
                    local common_minp2 = {
                        x=max(common_minp.x, planet_mapping.minp.x),
                        y=max(common_minp.y, planet_mapping.minp.y),
                        z=max(common_minp.z, planet_mapping.minp.z)
                    }
                    local common_maxp2 = {
                        x=min(common_maxp.x, planet_mapping.maxp.x),
                        y=min(common_maxp.y, planet_mapping.maxp.y),
                        z=min(common_maxp.z, planet_mapping.maxp.z)
                    }
                    if common_maxp2.x > common_minp2.x
                    and common_maxp2.y > common_minp2.y
                    and common_maxp2.z > common_minp2.z then
                        -- Generate planet
                        planet_mapping.offset = {x=0, y=-planet_pos.y, z=0}
                        planet_mapping.seed = seed + n
                        planet_mapping.walled = true
                        nv_planetgen.generate_planet_chunk(
                            common_minp2, common_maxp2, area, A, A1, A2, planet_mapping
                        )
                        for index in area:iterp(common_minp2, common_maxp2) do
                            if index % 100 == 0 then
                                if A[index] == minetest.get_content_id('nv_planetgen:snow') then
                                    A[index] = minetest.get_content_id('nv_game:pinata')
                                    A2[index] = A2[index] % 4
                                    nv_planetgen.set_dirty_flag()
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

nv_planetgen.register_on_not_generated(new_area_callback)

--[[
 # SHIPS SETUP
]]

local default_ship = "0MAsingleplayerBAnFAEAEABAgAAABAgCABACAALAAUAAAAAXAUAAAbArAAAXAGBAAcAdBAAUA5BAATANCAATAgCAATAzCAAcAGDAAVAiDAAnv_ships:floor_hull4nv_ships:scaffold_hull5nv_ships:turbo_engine_hull6nv_ships:scaffold_hull6nv_ships:scaffold_edge_hull6nv_ships:landing_legnv_ships:seat_hull5nv_ships:glass_facenv_ships:glass_edgenv_ships:control_panel_hull6nv_ships:glass_vertex6AwAyA4BxCDBDCwEDEyFyDGDxHwHxIHI2EJExIHIxKIKwAAAAAAAACADAAADACAEAAAHAAAAAAAAADADAEAIAKABAAACABAAACAWANAVA"

nv_ships.set_default_ship(default_ship)


