nv_flora = {}

dofile(minetest.get_modpath("nv_flora") .. "/thumbnail.lua")
dofile(minetest.get_modpath("nv_flora") .. "/small_plants.lua")
dofile(minetest.get_modpath("nv_flora") .. "/tall_grasses.lua")
dofile(minetest.get_modpath("nv_flora") .. "/cave_plants.lua")
dofile(minetest.get_modpath("nv_flora") .. "/trees.lua")
dofile(minetest.get_modpath("nv_flora") .. "/branched_plants.lua")
dofile(minetest.get_modpath("nv_flora") .. "/vines.lua")
dofile(minetest.get_modpath("nv_flora") .. "/lilypads.lua")

local f = io.open(minetest.get_worldpath() .. "/nv_flora.node_types", "rt")
nv_flora.node_types = minetest.deserialize(f:read())
f:close()

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
    local plant_type_handler = nil
    if meta.life == "lush" then
        if index == 1 then
            plant_type_handler = "small_plant"
        else
            plant_type_handler = gen_weighted(G, {
                small_plant = 30,
                cave_plant = 30,
                tall_grass = 20,
                tree = 25,
                vine = 7,
                lilypad = meta.has_oceans and 7 or 0
            })
        end
    elseif meta.atmosphere == "hot" then
        plant_type_handler = gen_weighted(G, {
            small_plant = 30,
            cave_plant = 20,
            tall_grass = 20,
            tree = 20,
            branched_plant = 30
        })
    elseif meta.atmosphere == "cold" then
        plant_type_handler = gen_weighted(G, {
            small_plant = 30,
            cave_plant = 20,
            tall_grass = 5,
            tree = 40
        })
    else
        plant_type_handler = gen_weighted(G, {
            small_plant = 40,
            cave_plant = 20,
            tall_grass = 15,
            tree = 40
        })
    end
    local translation = {
        small_plant = nv_flora.get_small_plant_meta,
        cave_plant = nv_flora.get_cave_plant_meta,
        tall_grass = nv_flora.get_tall_grass_meta,
        tree = nv_flora.get_tree_meta,
        vine = nv_flora.get_vine_meta,
        lilypad = nv_flora.get_lilypad_meta,
        branched_plant = nv_flora.get_branched_plant_meta,
    }
    plant_type_handler = translation[plant_type_handler]
    return plant_type_handler(seed, index)
end

local function plant_handler(seed)
    local G = PcgRandom(seed, seed)
    local meta = generate_planet_metadata(seed)
    local plant_count = 0
    if meta.life == "normal" then
        plant_count = G:next(12, 20)
    elseif meta.life == "lush" then
        plant_count = G:next(25, 45)
    end
    local r = {}
    for index=1,plant_count,1 do
        local plant_meta = get_plant_meta(seed, index)
        table.insert(r, {
            density = plant_meta.density,
            seed = plant_meta.seed,
            side = plant_meta.side,
            order = plant_meta.order,
            callback = plant_meta.callback,
            thumbnail = plant_meta.thumbnail or nv_flora.get_default_thumbnail,
            custom = plant_meta
        })
    end
    return r
end

nv_flora.get_planet_flora = plant_handler

nv_planetgen.register_structure_handler(plant_handler)
