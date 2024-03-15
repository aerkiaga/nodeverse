--[[
This file handles storage for the nv_universe mod, comprising various data.
The player-specific data is stored in `PlayerMetaRef` objects.

# INDEX
   ENCODING
   DECODING
   LOADING
   STORING

Player database format:
    key                         description
    nv_universe:in_space        'in_space' field in player table (see 'init.lua')
    nv_universe:planet          'planet' field in player table (see 'init.lua'))

Player database format:
    key                         description
    nv_universe:l<n>_<key>      <key> field in layers table (see 'allocation.lua')
    nv_universe:p<n>_<key>      <key> field in planets table (see 'allocation.lua'))

A few serialized types are defined for this data. These are the types used in
the tables below:
    type    description
    s18     18-bit, signed and little-endian (low, mid, high), sign-magnitude
                the topmost bit indicates sign (1 for negative), while the lower
                17 bits are the absolute magnitude of the number
    vs18    a vector of three s18-s, 9 bytes

The format of 'nv_universe:l<n>_areas' is a sequence of pairs of vs18, where the
first is 'minp' and the second corresponds to 'maxp'.
]]

local global_meta = minetest.get_mod_storage()

--[[
 # ENCODING
]]--

local function encode_s18(array, value)
    local sign = 0
    if value < 0 then sign = 1 end
    value = math.abs(value)
    table.insert(array, base64_encode(value % 64))
    table.insert(array, base64_encode(math.floor(value / 64) % 64))
    table.insert(array, base64_encode(math.floor(value / 4096) + 32 * sign))
end

--[[
 # DECODING
]]--

local function decode_vs18(str)
    local lowx = base64_decode(str:sub(1,1))
    local midx = base64_decode(str:sub(2,2))
    local highx = base64_decode(str:sub(3,3))
    local lowy = base64_decode(str:sub(4,4))
    local midy = base64_decode(str:sub(5,5))
    local highy = base64_decode(str:sub(6,6))
    local lowz = base64_decode(str:sub(7,7))
    local midz = base64_decode(str:sub(8,8))
    local highz = base64_decode(str:sub(9,9))
    local r = {
        x = 4096*highx + 64*midx + lowx,
        y = 4096*highy + 64*midy + lowy,
        z = 4096*highz + 64*midz + lowz
    }
    if r.x >= 131072 then r.x = 131072 - r.x end
    if r.y >= 131072 then r.y = 131072 - r.y end
    if r.z >= 131072 then r.z = 131072 - r.z end
    return r
end

--[[
 # LOADING
]]--

function nv_universe.load_player_state(player)
    local name = player:get_player_name()
    if nv_universe.players[name] ~= nil then
        return
    end
    local meta = player:get_meta()
    local read_table = meta:to_table()
    if read_table == nil then
        return
    end
    read_table = read_table.fields
    nv_universe.players[name] = {}
    nv_universe.players[name].in_space = (read_table["nv_universe:in_space"] ~= "false")
    nv_universe.players[name].planet = tonumber(read_table["nv_universe:planet"])
end

function nv_universe.load_global_state()
    local meta = global_meta
    local read_table = meta:to_table()
    if read_table == nil then
        return
    end
    read_table = read_table.fields
    for id, value in pairs(read_table) do
        if id:sub(1, 12) == "nv_universe:" then
            local name = id:sub(13, -1)
            local separator = string.find(name, "_")
            local index = tonumber(name:sub(2, separator - 1))
            local key = name:sub(separator + 1, -1)
            if name:sub(1, 1) == "l" then
                nv_universe.layers[index] = nv_universe.layers[index] or {}
                if key == "in_space" then
                    nv_universe.layers[index][key] = (value == "true")
                elseif key == "planet" or key == "n_players" then
                    nv_universe.layers[index][key] = tonumber(value)
                elseif key == "mapping" then
                    nv_universe.layers[index][key] = tonumber(value)
                end
            elseif name:sub(1, 1) == "p" then
                nv_universe.planets[index] = nv_universe.planets[index] or {}
                if value == "nil" then
                    nv_universe.planets[index][key] = nil
                else
                    nv_universe.planets[index][key] = tonumber(value)
                end
            elseif name:sub(1, 1) == "d" then
                local count = #value / 9
                for n=1,count do
                    local pos = decode_vs18(value:sub(1+n*9-9,9+n*9-9))
                    nv_universe.mark_dug_node(false, index, pos.x, pos.y, pos.z)
                end
            end
        end
    end
end

nv_universe.load_global_state()

--[[
 # STORING
]]--

function nv_universe.store_player_state(player)
    local name = player:get_player_name()
    local meta = player:get_meta()
    local written_table = {}
    written_table["nv_universe:in_space"] = nv_universe.players[name].in_space and "true" or "false"
    written_table["nv_universe:planet"] = tostring(nv_universe.players[name].planet)
    
    local read_table = meta:to_table()
    if read_table ~= nil then
        read_table = read_table.fields
        for key, value in pairs(read_table) do
            written_table[key] = written_table[key] or value
        end
    end
    local status = meta:from_table({
        fields = written_table
    })
end

function nv_universe.store_global_state()
    local written_table = {}
    if nv_universe.layers == nil then
        return
    end
    local meta = global_meta
    for index, value in pairs(nv_universe.layers) do
        for key, val in pairs(value) do
            if key == "mapping" then
                local array = {}
                encode_s18(array, val)
                written_table[string.format("nv_universe:l%d_%s", index, key)] = table.concat(array)
            else
                written_table[string.format("nv_universe:l%d_%s", index, key)] = tostring(val)
            end
        end
    end
    for index, value in pairs(nv_universe.planets) do
        for key, val in pairs(value) do
            written_table[string.format("nv_universe:p%d_%s", index, key)] = tostring(val)
        end
    end
    
    if nv_universe.dug[false] then
        for planet, coords in pairs(nv_universe.dug[false]) do
            local array = {}
            for y, coords2 in pairs(coords) do
                for z, coords3 in pairs(coords2) do
                    for x, t in pairs(coords3) do
                        encode_s18(array, x)
                        encode_s18(array, y)
                        encode_s18(array, z)
                    end
                end
            end
            written_table[string.format("nv_universe:d%d_", planet)] = table.concat(array)
        end
    end
    
    local read_table = meta:to_table()
    if read_table ~= nil then
        read_table = read_table.fields
        for key, value in pairs(read_table) do
            written_table[key] = written_table[key] or value
        end
    end
    local status = meta:from_table({
        fields = written_table
    })
end

minetest.register_on_shutdown(nv_universe.store_global_state)
