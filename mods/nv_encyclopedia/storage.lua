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
    nv_encyclopedia:planets     list of seeds of every planet the player has visited
    nv_encyclopedia:f<n>        'flora' field in planet with seed 'n', as a bitmap
                                (B for found, A for not found) (see 'init.lua')
]]

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

local function check_parse_s18(lmh, ch)
    if lmh.low == nil then
        lmh.low = base64_decode(ch)
    elseif lmh.mid == nil then
        lmh.mid = base64_decode(ch)
    elseif lmh.high == nil then
        lmh.high = base64_decode(ch)
        local r = 4096*lmh.high + 64*lmh.mid + lmh.low
        if r >= 131072 then r = 131072 - r end
        return r
    end
    return nil
end

local function parse_s18(str)
    local lmh = {}
    check_parse_s18(lmh, string.sub(str, 1, 1))
    check_parse_s18(lmh, string.sub(str, 2, 2))
    return check_parse_s18(lmh, string.sub(str, 3, 3))
end

--[[
 # LOADING
]]--

function nv_encyclopedia.load_player_state(player)
    local name = player:get_player_name()
    if nv_encyclopedia.players[name] ~= nil then
        return
    end
    local meta = player:get_meta()
    local read_table = meta:to_table()
    if read_table == nil then
        return
    end
    read_table = read_table.fields
    nv_encyclopedia.players[name] = {}
    local planets = {}
    for n=1,#read_table["nv_encyclopedia:planets"],3 do
        table.insert(planets, parse_s18(string.sub(read_table["nv_encyclopedia:planets"], n, n + 2)))
    end
    for n, seed in ipairs(planets) do
        local player_planet = {seed=seed, flora = {}}
        table.insert(nv_encyclopedia.players[name], player_planet)
        local key = string.format("nv_encyclopedia:f%d", seed)
        local value = read_table[key]
        if value then
            for m=1,#value,1 do
                if string.sub(value, m, m) == "B" then
                    player_planet.flora[m] = true
                end
            end
        end
    end
end

--[[
 # STORING
]]--

function nv_encyclopedia.store_player_state(player)
    local name = player:get_player_name()
    local meta = player:get_meta()
    local written_table = {}
    local array = {}
    for n, player_planet in ipairs(nv_encyclopedia.players[name]) do
        local key = string.format("nv_encyclopedia:f%d", player_planet.seed)
        local value = ""
        local max_index = 0
        for index, t in pairs(player_planet.flora) do
            max_index = math.max(max_index, index)
        end
        for index=1,max_index,1 do
            value = value .. (player_planet.flora[index] and "B" or "A")
        end
        written_table[key] = value
        encode_s18(array, player_planet.seed)
    end
    written_table["nv_encyclopedia:planets"] = table.concat(array) or ""
    
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
