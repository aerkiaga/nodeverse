--[[
This file handles storage for the nv_ships mod, comprising owned ship data.
The data is stored in `PlayerMetaRef` objects; although it isn't stated in any
document, the source code leads me to believe that those objects don't get sent
to the clients, so they should be an efficient solution.

# INDEX
   ENCODING
   DECODING
   SERIALIZATION
   DESERIALIZATION
   LOADING
   STORING

Database format:
    key                         description
    nv_ships:state              'state' field in player table (see 'ships.lua')
    nv_ships:cur_ship_index     index of 'cur_ship' in 'ships' (see 'ships.lua')
    nv_ships:ship_count         number of ships owned by player
    nv_ships:ship1
    nv_ships:ship2
    ...                         n-th index ship, serialized (see below)

Ships are serialized into long strings, using a relatively straightforward
format that encodes numbers using Base64, in units of 6 bits. You can see it at
https://en.wikipedia.org/wiki/Base64#Base64_table.

A few serialized types are defined for this data. These are the types used in
the tables below:
    type    description
    u6      one 6-bit unsigned number, as Base64 character
    u12     12-bit, little-endian (low bits first, followed by high bits)
    u18     18-bit, signed and little-endian (low, mid, high)
    s18     18-bit, signed and little-endian (low, mid, high), sign-magnitude
                the topmost bit indicates sign (1 for negative), while the lower
                17 bits are the absolute magnitude of the number
    vu12    a vector of three u12-s, 6 bytes (x first, followed by y and z)
    vs18    a vector of three s18-s, 9 bytes
    ?       optional value; can be replaced with all bytes '_', same width
    char    plain, non-encoded character
    string  a non-terminated string (non-Base64), its length is stored elsewhere

Serialized ship format:
    offset  type    description
    0       u6      version, always 0
    1       u12     length of owner name string
    3       string  owner name (see 'ships.lua')
    a       u12     ship index (see 'ships.lua')
    a+2     char    state, 'e' for "entity", 'n' for "node" (see 'ships.lua')
    a+3     vu12    ship size in all axes (see 'ships.lua')
    a+9     vs18?   absolute position of ship origin (see 'ships.lua')
    a+18    vu12?   relative position of cockpit (see 'ships.lua')
    a+24    u6?     cockpit (and ship) facing direction (see 'ships.lua')
    a+25    u12     number of distinct node types, entries in node type table
    a+27    u6      reserved, should be 0
    Following this is the node type table, with entries following this format:
    ent+0   u12     node type name length
    ent+2   u18     node type name offset in node type name list
    ent+7   u6      reserved, should be 0
    After these entries, node type names of variable length:
    off+0   string  node name corresponding to one ship node type
    Then, node type data, as an array of inividual bytes:
    byte+0  u6      interpretation depends on range
        0 - 31      Node type name index
        32 - 47     Use this minus 32 as the 4 high bits, append next byte as u6
        48 - 63     This number minus 47 of empty ("") nodes
    And, finally, and array of 'param2' values for non-empty nodes, in order
    val+0   u12     param2 value for the corresponding node
    Remember, only non-empty nodes get a value in this array, others are omitted
]]

--[[
 # ENCODING
]]--

local function encode_u12(array, value)
    table.insert(array, base64_encode(value % 64))
    table.insert(array, base64_encode(math.floor(value / 64)))
end

local function encode_u18(array, value)
    table.insert(array, base64_encode(value % 64))
    table.insert(array, base64_encode(math.floor(value / 64) % 64))
    table.insert(array, base64_encode(math.floor(value / 4096)))
end

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

local function check_parse_u12(lh, ch)
    if lh.low == nil then
        lh.low = base64_decode(ch)
    elseif lh.high == nil then
        lh.high = base64_decode(ch)
        return 64*lh.high + lh.low
    end
    return nil
end

local function check_parse_u18(lmh, ch)
    if lmh.low == nil then
        lmh.low = base64_decode(ch)
    elseif lmh.mid == nil then
        lmh.mid = base64_decode(ch)
    elseif lmh.high == nil then
        lmh.high = base64_decode(ch)
        return 4096*lmh.high + 64*lmh.mid + lmh.low
    end
    return nil
end

local function check_parse_vu12(lh, ch)
    if lh.low == nil then
        lh.low = {}
        lh.low.x = base64_decode(ch)
    elseif lh.high == nil then
        lh.high = {}
        lh.high.x = base64_decode(ch)
    elseif lh.low.y == nil then
        lh.low.y = base64_decode(ch)
    elseif lh.high.y == nil then
        lh.high.y = base64_decode(ch)
    elseif lh.low.z == nil then
        lh.low.z = base64_decode(ch)
    elseif lh.high.z == nil then
        lh.high.z = base64_decode(ch)
        return {
            x = 64*lh.high.x + lh.low.x,
            y = 64*lh.high.y + lh.low.y,
            z = 64*lh.high.z + lh.low.z
        }
    end
    return nil
end

local function check_parse_vs18(lmh, ch)
    if lmh.low == nil then
        lmh.low = {}
        lmh.low.x = base64_decode(ch)
    elseif lmh.mid == nil then
        lmh.mid = {}
        lmh.mid.x = base64_decode(ch)
    elseif lmh.high == nil then
        lmh.high = {}
        lmh.high.x = base64_decode(ch)
    elseif lmh.low.y == nil then
        lmh.low.y = base64_decode(ch)
    elseif lmh.mid.y == nil then
        lmh.mid.y = base64_decode(ch)
    elseif lmh.high.y == nil then
        lmh.high.y = base64_decode(ch)
    elseif lmh.low.z == nil then
        lmh.low.z = base64_decode(ch)
    elseif lmh.mid.z == nil then
        lmh.mid.z = base64_decode(ch)
    elseif lmh.high.z == nil then
        lmh.high.z = base64_decode(ch)
        local r = {
            x = 4096*lmh.high.x + 64*lmh.mid.x + lmh.low.x,
            y = 4096*lmh.high.y + 64*lmh.mid.y + lmh.low.y,
            z = 4096*lmh.high.z + 64*lmh.mid.z + lmh.low.z
        }
        if r.x >= 131072 then r.x = 131072 - r.x end
        if r.y >= 131072 then r.y = 131072 - r.y end
        if r.z >= 131072 then r.z = 131072 - r.z end
        return r
    end
    return nil
end

--[[
 # SERIALIZATION
]]--

local function serialize_ship_nodes(array, ship)
    local node_type_list = {}
    local name_to_index_map = {}
    local name_strings_array = {}
    local name_data_array = {}
    local param2_array = {}

    local max_index = -1
    local next_name_offset = 0
    local empty_in_a_row = 0
    local ship_volume = ship.size.x * ship.size.y * ship.size.z
    for k = 1, ship_volume do
        local name = ship.An[k]
        if name == "" then
            empty_in_a_row = empty_in_a_row + 1
        end
        if empty_in_a_row == 16 or
            (empty_in_a_row > 0 and (name ~= "" or k == ship_volume)) then
            table.insert(name_data_array, base64_encode(empty_in_a_row + 47))
            empty_in_a_row = 0
        end
        if name ~= "" then
            local index = name_to_index_map[name]
            if index == nil then
                max_index = max_index + 1
                index = max_index
                name_to_index_map[name] = index
                node_type_list[index] = name
                -- Node type name table
                encode_u12(array, #name)
                encode_u18(array, next_name_offset)
                next_name_offset = next_name_offset + #name
                table.insert(array, base64_encode(0))
                -- Node type strings
                table.insert(name_strings_array, name)
            end
            if index < 32 then
                table.insert(name_data_array, base64_encode(index))
            else
                local high_bits = math.floor(index / 64)
                local low_bits = index % 64
                table.insert(name_data_array, base64_encode(high_bits + 32))
                table.insert(name_data_array, base64_encode(low_bits))
            end
            local param2 = ship.A2[k]
            encode_u12(param2_array, param2)
        end
    end

    table.insert(array, table.concat(name_strings_array))
    table.insert(array, table.concat(name_data_array))
    table.insert(array, table.concat(param2_array))
end

function nv_ships.serialize_ship(ship)
    local array = {}
    table.insert(array, "0") -- length
    encode_u12(array, #ship.owner)
    table.insert(array, ship.owner)
    encode_u12(array, ship.index)
    table.insert(array, string.sub(ship.state, 1, 1))
    encode_u12(array, ship.size.x)
    encode_u12(array, ship.size.y)
    encode_u12(array, ship.size.z)
    if ship.pos == nil then
        table.insert(array, "_________")
    else
        encode_s18(array, ship.pos.x)
        encode_s18(array, ship.pos.y)
        encode_s18(array, ship.pos.z)
    end
    if ship.cockpit_pos == nil then
        table.insert(array, "______")
    else
        encode_u12(array, ship.cockpit_pos.x)
        encode_u12(array, ship.cockpit_pos.y)
        encode_u12(array, ship.cockpit_pos.z)
    end
    if ship.facing == nil then
        table.insert(array, "_")
    else
        table.insert(array, base64_encode(ship.facing))
    end
    local node_types_set = {}
    for k = 1, ship.size.x * ship.size.y * ship.size.z do
        node_types_set[ship.An[k]] = true
    end
    local node_types = 0
    for key, _ in pairs(node_types_set) do
        if key ~= "" then
            node_types = node_types + 1
        end
    end
    encode_u12(array, node_types)
    table.insert(array, base64_encode(0))
    serialize_ship_nodes(array, ship)
    return table.concat(array) or ""
end

--[[
 # DESERIALIZATION
]]--

local function deserialize_ship_nodes(ship, data, node_types)
    local name_strings_start = node_types * 6
    local name_data_start = 1

    -- Node types
    local parsed_node_types = 0
    local index_to_name_map = {}
    local current_index = 0
    local current_name_length_lh, current_name_length = {}, nil
    local current_name_offset_lmh, current_name_offset = {}, nil
    for ch in data:gmatch(".") do
        if current_name_length == nil then
            current_name_length = check_parse_u12(current_name_length_lh, ch)
        elseif current_name_offset == nil then
            current_name_offset = check_parse_u18(current_name_offset_lmh, ch)
            if current_name_offset ~= nil then
                local absolute_offset = name_strings_start + current_name_offset
                local end_offset = absolute_offset + current_name_length - 1
                name_data_start = math.max(name_data_start, end_offset + 2)
                local name = data:sub(absolute_offset + 1, end_offset + 1)
                index_to_name_map[current_index] = name
                current_index = current_index + 1
            end
        else -- one extra byte
            if current_index >= node_types then
                break
            else
                current_name_length_lh, current_name_length = {}, nil
                current_name_offset_lmh, current_name_offset = {}, nil
            end
        end
    end

    -- Node names (An)
    local ship_volume = ship.size.x * ship.size.y * ship.size.z
    local param2_data_start = name_data_start
    local k = 1
    local is_continuation = false
    local high_bits
    for ch in data:sub(name_data_start, -1):gmatch(".") do
        local value = base64_decode(ch)
        param2_data_start = param2_data_start + 1
        if is_continuation then
            local index = 64*high_bits + value
            ship.An[k] = index_to_name_map[index]
            is_continuation = false
            k = k + 1
        elseif value < 32 then
            ship.An[k] = index_to_name_map[value]
            k = k + 1
        elseif value < 48 then
            high_bits = value - 32
            is_continuation = true
        else
            local count = value - 47
            for n = 1, count do
                ship.An[k] = ""
                k = k + 1
            end
        end
        if k > ship_volume then
            break
        end
    end

    -- Node param2 (A2)
    k = 1
    local param2_lh, param2 = {}, nil
    for ch in data:sub(param2_data_start, -1):gmatch(".") do
        param2 = check_parse_u12(param2_lh, ch)
        if param2 ~= nil then
            while ship.An[k] == "" do
                ship.A2[k] = 0
                k = k + 1
                if k > ship_volume then
                    break
                end
            end
            if k > ship_volume then
                break
            end
            ship.A2[k] = param2
            k = k + 1
            if k > ship_volume then
                break
            end
            param2_lh, param2 = {}, nil
        end
    end
end

function nv_ships.deserialize_ship(data)
    local version = nil
    local owner_length_lh, owner_length = {}, nil
    local owner_array = {}
    local owner = nil
    local index_lh, index = {}, nil
    local state = nil
    local size_lh, size = {}, nil
    local pos_lmh, pos = {}, nil
    local cockpit_pos_lh, cockpit_pos = {}, nil
    local facing = nil
    local node_types_lh, node_types = {}, nil
    local header_length = 0
    local ignore = 0
    for ch in data:gmatch(".") do
        header_length = header_length + 1
        if ignore > 0 then
            ignore = ignore - 1
        elseif version == nil then
            version = base64_decode(ch)
        elseif owner_length == nil then
            owner_length = check_parse_u12(owner_length_lh, ch)
        elseif owner == nil then
            table.insert(owner_array, ch)
            if #owner_array >= owner_length then
                owner = table.concat(owner_array)
            end
        elseif index == nil then
            index = check_parse_u12(index_lh, ch)
        elseif state == nil then
            if ch == "n" then
                state = "node"
            else
                state = "entity"
            end
        elseif size == nil then
            size = check_parse_vu12(size_lh, ch)
        elseif pos == nil then
            if ch == "_" then
                pos = {}
                ignore = 8
            else
                pos = check_parse_vs18(pos_lmh, ch)
            end
        elseif cockpit_pos == nil then
            if ch == "_" then
                cockpit_pos = {}
                ignore = 5
            else
                cockpit_pos = check_parse_vu12(cockpit_pos_lh, ch)
            end
        elseif facing == nil then
            if ch == "_" then
                facing = -1
            else
                facing = base64_decode(ch)
            end
        elseif node_types == nil then
            node_types = check_parse_u12(node_types_lh, ch)
        else
            -- one extra byte
            break
        end
    end
    if pos.x == nil then pos = nil end
    if cockpit_pos.x == nil then cockpit_pos = nil end
    if facing == -1 then facing = nil end

    local ship = {
        owner = owner,
        index = index,
        state = state,
        size = size,
        pos = pos,
        An = {},
        A2 = {},
        cockpit_pos = cockpit_pos,
        facing = facing
    }

    deserialize_ship_nodes(ship, data:sub(header_length + 1, -1), node_types)

    return ship
end

--[[
 # LOADING
]]--

function nv_ships.load_player_state(player)
    local name = player:get_player_name()
    local player_data = nv_ships.players_list[name]
    if player_data.state ~= nil then
        return
    end
    local meta = player:get_meta()
    local read_table = meta:to_table()
    if read_table == nil then
        return
    end
    read_table = read_table.fields

    player_data.state = read_table["nv_ships:state"]
    if read_table["nv_ships:state"] ~= "" then
        player_data.state = read_table["nv_ships:state"]
    end

    local ship_count = read_table["nv_ships:ship_count"] or 0

    player_data.ships = {}
    for ship_index = 1, ship_count do
        local ship = read_table["nv_ships:ship" .. ship_index]
        player_data.ships[ship_index] = nv_ships.deserialize_ship(ship)
    end

    local player_cur_ship_index = read_table["nv_ships:cur_ship_index"] or 0
    player_cur_ship_index = tonumber(player_cur_ship_index)
    if player_cur_ship_index > 0 then
        player_data.cur_ship = player_data.ships[player_cur_ship_index]
    end
end

--[[
 # STORING
]]--

function nv_ships.store_player_state(player)
    local name = player:get_player_name()
    local meta = player:get_meta()
    local player_data = nv_ships.players_list[name]
    local written_table = {}

    local player_state = player_data.state or ""
    written_table["nv_ships:state"] = player_state

    local player_cur_ship = player_data.cur_ship
    local player_cur_ship_index = 0
    if player_cur_ship then
        player_cur_ship_index = player_cur_ship.index
    end
    written_table["nv_ships:cur_ship_index"] = player_cur_ship_index

    for index, ship in ipairs(player_data.ships) do
        written_table["nv_ships:ship" .. index] = nv_ships.serialize_ship(ship)
    end

    written_table["nv_ships:ship_count"] = #(player_data.ships)

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
