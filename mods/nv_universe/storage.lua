--[[
This file handles storage for the nv_universe mod, comprising various data.
The player-specific data is stored in `PlayerMetaRef` objects.

# INDEX
   LOADING
   STORING

Player database format:
    key                         description
    nv_universe:in_space        'in_space' field in player table (see 'init.lua')
    nv_universe:planet          'planet' field in player table (see 'init.lua'))
]]

--[[
 # LOADING
]]--

function nv_universe.load_player_state(player)
    local name = player:get_player_name()
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
            written_table[key] = value
        end
    end
    local status = meta:from_table({
        fields = written_table
    })
end
