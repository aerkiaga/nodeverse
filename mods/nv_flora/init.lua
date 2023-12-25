--[[
NV Flora implements large flora for Nodeverse.

Included files:
    nodetypes.lua       Node definitions and registration

 # INDEX
]]--

nv_flora = {}

dofile(minetest.get_modpath("nv_flora") .. "/nodetypes.lua")
dofile(minetest.get_modpath("nv_flora") .. "/small_plants.lua")
dofile(minetest.get_modpath("nv_flora") .. "/tall_grasses.lua")
dofile(minetest.get_modpath("nv_flora") .. "/cave_plants.lua")
dofile(minetest.get_modpath("nv_flora") .. "/trees.lua")
dofile(minetest.get_modpath("nv_flora") .. "/branched_plants.lua")

function get_planet_plant_colors(seed)
    local G = PcgRandom(seed, seed)
    local meta = generate_planet_metadata(seed)
    nv_planetgen.choose_planet_nodes_and_colors(meta)
    local color_count = G:next(2, 4)
    local default_color_group = tonumber(minetest.get_name_from_content_id(meta.node_types.grass):sub(19,-1))
    local default_color_index = meta.color_dictionary[meta.node_types.grass]
    local default_color = (default_color_group - 1) * 8 + default_color_index + 1
    local r = {default_color}
    for n=2,color_count do
        local color = G:next(1, 64)
        if color > 48 then
            color = color - 16
        end
        table.insert(r, color)
    end
    return r
end

local function get_plant_meta(seed, index)
    local G = PcgRandom(seed, index)
    local meta = generate_planet_metadata(seed)
    local plant_type_handler
    if meta.life == "lush" then
        if index == 0 then
            plant_type_handler = nv_flora.get_tree_meta
        else
            plant_type_handler = gen_weighted(G, {
                [nv_flora.get_small_plant_meta] = 70,
                [nv_flora.get_cave_plant_meta] = 30,
                [nv_flora.get_tall_grass_meta] = 30,
                [nv_flora.get_tree_meta] = 20
            })
        end
    elseif meta.atmosphere == "hot" then
        plant_type_handler = gen_weighted(G, {
            [nv_flora.get_small_plant_meta] = 50,
            [nv_flora.get_cave_plant_meta] = 20,
            [nv_flora.get_tall_grass_meta] = 20,
            [nv_flora.get_tree_meta] = 20,
            [nv_flora.get_branched_plant_meta] = 30
        })
    elseif meta.atmosphere == "cold" then
        plant_type_handler = gen_weighted(G, {
            [nv_flora.get_small_plant_meta] = 50,
            [nv_flora.get_cave_plant_meta] = 20,
            [nv_flora.get_tall_grass_meta] = 5,
            [nv_flora.get_tree_meta] = 40
        })
    else
        plant_type_handler = gen_weighted(G, {
            [nv_flora.get_small_plant_meta] = 70,
            [nv_flora.get_cave_plant_meta] = 20,
            [nv_flora.get_tall_grass_meta] = 15,
            [nv_flora.get_tree_meta] = 40
        })
    end
    return plant_type_handler(seed, index)
end

local function plant_handler(seed)
    local G = PcgRandom(seed, seed)
    local meta = generate_planet_metadata(seed)
    local plant_count = 0
    if meta.life == "normal" then
        plant_count = G:next(15, 25)
    elseif meta.life == "lush" then
        plant_count = G:next(30, 50)
    end
    local r = {}
    for index=1,plant_count do
        local plant_meta = get_plant_meta(seed, index)
        table.insert(r, {
            density = plant_meta.density,
            seed = plant_meta.seed,
            side = plant_meta.side,
            order = plant_meta.order,
            callback = plant_meta.callback,
            custom = plant_meta
        })
    end
    return r
end

nv_planetgen.register_structure_handler(plant_handler)
